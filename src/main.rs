use color_eyre::eyre::WrapErr as _;

const SPECTRUM_ASNS: &[&str] = &[
    "AS3456", "AS7843", "AS10796", "AS10994", "AS11060", "AS11351", "AS11426", "AS11427",
    "AS12271", "AS20001", "AS20115", "AS33363", "AS33490", "AS33491", "AS63365",
];

const TEST_HOST: &str = "staging.drafted.ai";
const TEST_PORT: u16 = 443;

#[derive(clap::Parser)]
#[command(name = "spectrum")]
#[command(about = "Detect Spectrum/Charter SSL interception bugs")]
struct Cli {
    /// Output directory for test results
    #[arg(short, long, default_value = "results")]
    output: std::path::PathBuf,

    /// Run in verbose mode
    #[arg(short, long)]
    verbose: bool,

    /// Custom host to test against
    #[arg(long, default_value = TEST_HOST)]
    host: String,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct IpInfo {
    ip: String,
    city: Option<String>,
    region: Option<String>,
    country: Option<String>,
    org: Option<String>,
}

#[derive(serde::Serialize)]
struct TestResult {
    timestamp: String,
    ip_info: Option<IpInfo>,
    is_spectrum: bool,
    tls12: TlsTestResult,
    tls13: TlsTestResult,
    ipv6: ConnectionResult,
    bug_detected: bool,
    raw_bytes_hex: Option<String>,
}

#[derive(serde::Serialize)]
struct TlsTestResult {
    success: bool,
    error: Option<String>,
    raw_bytes: Option<Vec<u8>>,
    has_0xff_pattern: bool,
}

#[derive(serde::Serialize)]
struct ConnectionResult {
    success: bool,
    error: Option<String>,
}

fn detect_0xff_pattern(bytes: &[u8]) -> bool {
    if bytes.len() >= 5 {
        bytes[0..5] == [0xff, 0xff, 0xff, 0xff, 0xff]
    } else {
        false
    }
}

fn extract_asn(org: &str) -> Option<&str> {
    org.split_whitespace().find(|s| s.starts_with("AS"))
}

fn is_spectrum_asn(asn: &str) -> bool {
    SPECTRUM_ASNS.contains(&asn)
}

async fn fetch_ip_info() -> color_eyre::Result<IpInfo> {
    let client = reqwest::Client::new();
    let info: IpInfo = client
        .get("https://ipinfo.io/json")
        .send()
        .await
        .wrap_err("failed to fetch IP info")?
        .json()
        .await
        .wrap_err("failed to parse IP info JSON")?;
    Ok(info)
}

#[derive(Clone, Copy)]
enum TlsVersion {
    Tls12,
    Tls13,
}

async fn test_tls_raw(host: &str, port: u16, tls_version: TlsVersion) -> TlsTestResult {
    let result = test_tls_raw_inner(host, port, tls_version).await;
    match result {
        Ok(()) => TlsTestResult {
            success: true,
            error: None,
            raw_bytes: None,
            has_0xff_pattern: false,
        },
        Err((err, raw_bytes)) => {
            let has_pattern = raw_bytes
                .as_ref()
                .map(|b| detect_0xff_pattern(b))
                .unwrap_or(false);
            TlsTestResult {
                success: false,
                error: Some(err),
                raw_bytes: raw_bytes.clone(),
                has_0xff_pattern: has_pattern,
            }
        }
    }
}

async fn test_tls_raw_inner(
    host: &str,
    port: u16,
    tls_version: TlsVersion,
) -> Result<(), (String, Option<Vec<u8>>)> {
    let addr = format!("{host}:{port}");

    let stream = tokio::net::TcpStream::connect(&addr)
        .await
        .map_err(|e| (format!("TCP connect failed: {e}"), None))?;

    let mut root_store = rustls::RootCertStore::empty();
    root_store.extend(webpki_roots::TLS_SERVER_ROOTS.iter().cloned());

    let versions: &[&rustls::SupportedProtocolVersion] = match tls_version {
        TlsVersion::Tls12 => &[&rustls::version::TLS12],
        TlsVersion::Tls13 => &[&rustls::version::TLS13],
    };

    let config = rustls::ClientConfig::builder_with_protocol_versions(versions)
        .with_root_certificates(root_store)
        .with_no_client_auth();

    let connector = tokio_rustls::TlsConnector::from(std::sync::Arc::new(config));

    let server_name = rustls::pki_types::ServerName::try_from(host.to_string())
        .map_err(|e| (format!("invalid server name: {e}"), None))?;

    match connector.connect(server_name, stream).await {
        Ok(_tls_stream) => Ok(()),
        Err(e) => {
            let err_str = e.to_string();
            Err((err_str, None))
        }
    }
}

fn test_tls_with_raw_capture(host: &str, port: u16) -> (Option<Vec<u8>>, String) {
    use std::io::Read as _;
    use std::io::Write as _;

    let addr = format!("{host}:{port}");

    let mut stream = match std::net::TcpStream::connect(&addr) {
        Ok(s) => s,
        Err(e) => return (None, format!("TCP connect failed: {e}")),
    };

    stream.set_nodelay(true).ok();
    stream
        .set_read_timeout(Some(std::time::Duration::from_secs(10)))
        .ok();
    stream
        .set_write_timeout(Some(std::time::Duration::from_secs(10)))
        .ok();

    let client_hello = build_tls_client_hello(host);

    if let Err(e) = stream.write_all(&client_hello) {
        return (None, format!("failed to send ClientHello: {e}"));
    }

    let mut response = vec![0u8; 1024];
    match stream.read(&mut response) {
        Ok(n) if n > 0 => {
            response.truncate(n);
            let has_0xff = detect_0xff_pattern(&response);
            let msg = if has_0xff {
                "received 0xff garbage pattern - SSL interception detected!".to_string()
            } else {
                format!("received {n} bytes")
            };
            (Some(response), msg)
        }
        Ok(_) => (None, "connection closed without response".to_string()),
        Err(e) => (None, format!("read error: {e}")),
    }
}

fn build_tls_client_hello(host: &str) -> Vec<u8> {
    let mut hello = Vec::new();

    hello.push(0x16);
    hello.extend_from_slice(&[0x03, 0x01]);

    let mut handshake = Vec::new();

    handshake.push(0x01);

    let mut client_hello_body = Vec::new();

    client_hello_body.extend_from_slice(&[0x03, 0x03]);

    client_hello_body.extend_from_slice(&[0; 32]);

    client_hello_body.push(0);

    let cipher_suites: &[u8] = &[
        0x13, 0x01, 0x13, 0x02, 0x13, 0x03, 0xc0, 0x2c, 0xc0, 0x2b, 0xc0, 0x30, 0xc0, 0x2f,
    ];
    client_hello_body.extend_from_slice(&(cipher_suites.len() as u16).to_be_bytes());
    client_hello_body.extend_from_slice(cipher_suites);

    client_hello_body.push(1);
    client_hello_body.push(0);

    let mut extensions = Vec::new();

    extensions.extend_from_slice(&[0x00, 0x00]);
    let sni_len = host.len() + 5;
    extensions.extend_from_slice(&(sni_len as u16).to_be_bytes());
    extensions.extend_from_slice(&((sni_len - 2) as u16).to_be_bytes());
    extensions.push(0);
    extensions.extend_from_slice(&(host.len() as u16).to_be_bytes());
    extensions.extend_from_slice(host.as_bytes());

    extensions.extend_from_slice(&[0x00, 0x0b, 0x00, 0x02, 0x01, 0x00]);

    extensions.extend_from_slice(&[0x00, 0x0a, 0x00, 0x04, 0x00, 0x02, 0x00, 0x17]);

    extensions.extend_from_slice(&[0x00, 0x0d, 0x00, 0x04, 0x00, 0x02, 0x04, 0x01]);

    client_hello_body.extend_from_slice(&(extensions.len() as u16).to_be_bytes());
    client_hello_body.extend_from_slice(&extensions);

    let ch_len = client_hello_body.len();
    handshake.push(0);
    handshake.extend_from_slice(&(ch_len as u16).to_be_bytes());
    handshake.extend_from_slice(&client_hello_body);

    let hs_len = handshake.len();
    hello.extend_from_slice(&(hs_len as u16).to_be_bytes());
    hello.extend_from_slice(&handshake);

    hello
}

async fn test_ipv6(host: &str) -> ConnectionResult {
    let client = reqwest::Client::builder()
        .local_address(std::net::IpAddr::V6(std::net::Ipv6Addr::UNSPECIFIED))
        .build();

    let client = match client {
        Ok(c) => c,
        Err(e) => {
            return ConnectionResult {
                success: false,
                error: Some(format!("failed to create IPv6 client: {e}")),
            };
        }
    };

    match client
        .get(format!("https://{host}"))
        .timeout(std::time::Duration::from_secs(10))
        .send()
        .await
    {
        Ok(_) => ConnectionResult {
            success: true,
            error: None,
        },
        Err(e) => ConnectionResult {
            success: false,
            error: Some(e.to_string()),
        },
    }
}

fn bytes_to_hex(bytes: &[u8]) -> String {
    bytes
        .iter()
        .map(|b| format!("{b:02x}"))
        .collect::<Vec<_>>()
        .join(" ")
}

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    rustls::crypto::ring::default_provider()
        .install_default()
        .expect("failed to install rustls crypto provider");

    let cli = <Cli as clap::Parser>::parse();

    let filter = if cli.verbose {
        tracing::level_filters::LevelFilter::DEBUG
    } else {
        tracing::level_filters::LevelFilter::INFO
    };

    tracing_subscriber::fmt()
        .with_max_level(filter)
        .without_time()
        .with_target(false)
        .init();

    std::fs::create_dir_all(&cli.output).wrap_err("failed to create output directory")?;

    let timestamp = chrono::Utc::now().format("%Y%m%d-%H%M%S").to_string();

    tracing::info!("spectrum ssl bug test - {}", timestamp);
    tracing::info!("========================================\n");

    tracing::info!("collecting system info...");
    let ip_info = match fetch_ip_info().await {
        Ok(info) => {
            tracing::info!(ip = %info.ip, "your ip");
            if let Some(ref city) = info.city {
                tracing::info!(city = %city);
            }
            if let Some(ref region) = info.region {
                tracing::info!(region = %region);
            }
            if let Some(ref org) = info.org {
                tracing::info!(org = %org);
            }
            Some(info)
        }
        Err(e) => {
            tracing::warn!("could not fetch IP info: {e}");
            None
        }
    };

    let is_spectrum = ip_info
        .as_ref()
        .and_then(|info| info.org.as_ref())
        .and_then(|org| extract_asn(org))
        .map(is_spectrum_asn)
        .unwrap_or(false);

    if !is_spectrum {
        tracing::warn!("you don't appear to be on spectrum");
        tracing::warn!("this test is designed for spectrum users but will run anyway\n");
    } else {
        tracing::info!("detected spectrum connection\n");
    }

    tracing::info!("running TLS 1.2 test...");
    let tls12 = test_tls_raw(&cli.host, TEST_PORT, TlsVersion::Tls12).await;
    if tls12.success {
        tracing::info!("  TLS 1.2: OK");
    } else {
        tracing::error!(
            "  TLS 1.2: FAILED - {}",
            tls12.error.as_deref().unwrap_or("unknown error")
        );
    }

    tracing::info!("running TLS 1.3 test...");
    let tls13 = test_tls_raw(&cli.host, TEST_PORT, TlsVersion::Tls13).await;
    if tls13.success {
        tracing::info!("  TLS 1.3: OK");
    } else {
        tracing::error!(
            "  TLS 1.3: FAILED - {}",
            tls13.error.as_deref().unwrap_or("unknown error")
        );
    }

    tracing::info!("running raw TLS capture test...");
    let (raw_bytes, raw_msg) = test_tls_with_raw_capture(&cli.host, TEST_PORT);
    tracing::debug!("  raw capture: {raw_msg}");

    let raw_bytes_hex = raw_bytes.as_ref().map(|b| bytes_to_hex(b));
    if let Some(ref hex) = raw_bytes_hex {
        if hex.len() <= 100 {
            tracing::debug!("  first bytes: {hex}");
        } else {
            tracing::debug!("  first bytes: {}...", &hex[..100]);
        }
    }

    let has_0xff_in_raw = raw_bytes
        .as_ref()
        .map(|b| detect_0xff_pattern(b))
        .unwrap_or(false);

    tracing::info!("running IPv6 test...");
    let ipv6 = test_ipv6(&cli.host).await;
    if ipv6.success {
        tracing::info!("  IPv6: OK");
    } else {
        tracing::warn!(
            "  IPv6: FAILED - {}",
            ipv6.error.as_deref().unwrap_or("not available")
        );
    }

    let bug_detected = tls12.has_0xff_pattern || tls13.has_0xff_pattern || has_0xff_in_raw;

    tracing::info!("========================================");
    if bug_detected {
        tracing::error!("!!!!! 0xFF PATTERN DETECTED !!!!!");
        tracing::error!("spectrum is returning garbage data instead of valid TLS responses.");
        tracing::error!("this confirms the SSL interception bug.\n");
    } else if !tls12.success || !tls13.success {
        tracing::warn!("TLS tests failed but no 0xff pattern detected.");
        tracing::warn!("the connection issue may have a different cause.\n");
    } else {
        tracing::info!("all tests passed - no SSL interception bug detected.\n");
    }

    let result = TestResult {
        timestamp: timestamp.clone(),
        ip_info,
        is_spectrum,
        tls12,
        tls13,
        ipv6,
        bug_detected,
        raw_bytes_hex,
    };

    let result_path = cli.output.join(format!("result-{timestamp}.json"));
    let json = serde_json::to_string_pretty(&result).wrap_err("failed to serialize results")?;
    std::fs::write(&result_path, &json).wrap_err("failed to write results")?;

    tracing::info!("results saved to: {}", result_path.display());

    if bug_detected {
        tracing::info!("please upload your results to:");
        tracing::info!("https://codeberg.org/azzie/spectrum/issues");
    }

    if let Err(e) = open::that(&cli.output) {
        tracing::debug!("could not open folder: {e}");
    }

    Ok(())
}
