# spectrum

detect spectrum/charter ssl interception bugs.

## install

**macOS (Apple Silicon)**
```bash
curl -L https://github.com/andrewgazelka/spectrum/releases/latest/download/spectrum-aarch64-apple-darwin.tar.gz | tar xz
./spectrum
```

**macOS (Intel)**
```bash
curl -L https://github.com/andrewgazelka/spectrum/releases/latest/download/spectrum-x86_64-apple-darwin.tar.gz | tar xz
./spectrum
```

**Linux**
```bash
curl -L https://github.com/andrewgazelka/spectrum/releases/latest/download/spectrum-x86_64-unknown-linux-gnu.tar.gz | tar xz
./spectrum
```

**Windows (PowerShell)**
```powershell
Invoke-WebRequest -Uri https://github.com/andrewgazelka/spectrum/releases/latest/download/spectrum-x86_64-pc-windows-msvc.zip -OutFile spectrum.zip
Expand-Archive spectrum.zip
.\spectrum\spectrum.exe
```

**From source**
```bash
cargo install --git https://github.com/andrewgazelka/spectrum
```

## what it does

- detects your ISP and checks if you're on spectrum
- tests TLS 1.2 and 1.3 handshakes
- captures raw TLS responses to detect the 0xff garbage pattern
- checks IPv6 connectivity (often bypasses inspection)
- saves results to JSON for reporting

## the bug

spectrum/charter's transparent SSL inspection gear sometimes returns 256 bytes of `0xff` instead of valid TLS responses. browsers show `ERR_SSL_PROTOCOL_ERROR`, openssl shows `packet length too long`.

the pattern is always the same: `ff ff ff ff ff...` - openssl interprets this as a ~4GB packet length and fails.

## options

```
spectrum [OPTIONS]

Options:
  -o, --output <DIR>   Output directory [default: results]
  -v, --verbose        Show debug info (raw bytes, etc)
      --host <HOST>    Custom host to test [default: staging.drafted.ai]
  -h, --help           Print help
```

## workarounds

what helps:
- VPN (bypasses inspection)
- IPv6 (often not inspected)
- HTTP/3 over UDP
- mobile data

what doesn't help:
- different TLS versions
- different cipher suites
- different ports (they inspect all 443 traffic)

## reporting

if you detect the bug, please open an issue with your results JSON at:
https://github.com/andrewgazelka/spectrum/issues

include your location (city/state) and when it happens (time of day).

## why this matters

spectrum is running transparent SSL interception without disclosure. when it works, it's invasive. when it breaks (like this), it's unusable. we're collecting evidence for an FCC complaint.
