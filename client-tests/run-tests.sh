#!/bin/bash

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="../results"
mkdir -p "$OUTPUT_DIR"

echo "spectrum ssl bug test - $(date)"
echo "========================================"
echo ""

echo "collecting system info..."
IP=$(curl -s https://ipinfo.io/ip)
ISP_INFO=$(curl -s https://ipinfo.io/json)
echo "$ISP_INFO" > "$OUTPUT_DIR/system-$TIMESTAMP.json"

echo "your ip: $IP"
echo "$ISP_INFO" | grep -E "org|city|region"
echo ""

ASN=$(echo "$ISP_INFO" | grep -o '"org".*' | cut -d'"' -f4 | grep -o 'AS[0-9]*')
if [[ ! "$ASN" =~ ^AS(3456|7843|10796|10994|11060|11351|11426|11427|12271|20001|20115|33363|33490|33491|63365)$ ]]; then
    echo "warning: you're not on spectrum (detected: $ASN)"
    echo "this test is designed for spectrum users but will run anyway"
    echo ""
fi

echo "running tls 1.2 test..."
timeout 10 openssl s_client -connect staging.drafted.ai:443 -tls1_2 -debug 2>&1 | tee "$OUTPUT_DIR/tls12-$TIMESTAMP.txt"
TLS12_EXIT=$?
echo ""

echo "running tls 1.3 test..."
timeout 10 openssl s_client -connect staging.drafted.ai:443 -tls1_3 -debug 2>&1 | tee "$OUTPUT_DIR/tls13-$TIMESTAMP.txt"
TLS13_EXIT=$?
echo ""

echo "testing direct ip connection..."
timeout 10 openssl s_client -connect 76.76.21.21:443 -servername staging.drafted.ai -tls1_2 2>&1 | head -30 | tee "$OUTPUT_DIR/direct-ip-$TIMESTAMP.txt"
echo ""

echo "checking for ipv6..."
if timeout 5 curl -6 -s https://staging.drafted.ai > /dev/null 2>&1; then
    echo "ipv6 works"
    echo "ipv6: success" >> "$OUTPUT_DIR/summary-$TIMESTAMP.txt"
else
    echo "ipv6 failed or not available"
    echo "ipv6: failed" >> "$OUTPUT_DIR/summary-$TIMESTAMP.txt"
fi
echo ""

echo "checking http/3 support..."
if command -v curl > /dev/null && curl --version | grep -q HTTP3; then
    if timeout 5 curl --http3 -s https://staging.drafted.ai > /dev/null 2>&1; then
        echo "http/3 works"
        echo "http3: success" >> "$OUTPUT_DIR/summary-$TIMESTAMP.txt"
    else
        echo "http/3 failed"
        echo "http3: failed" >> "$OUTPUT_DIR/summary-$TIMESTAMP.txt"
    fi
else
    echo "http/3 not supported by your curl"
    echo "http3: not available" >> "$OUTPUT_DIR/summary-$TIMESTAMP.txt"
fi
echo ""

echo "running traceroute..."
traceroute -T -p 443 staging.drafted.ai 2>&1 | tee "$OUTPUT_DIR/traceroute-$TIMESTAMP.txt"
echo ""

echo "checking for the 0xff bug pattern..."
if grep -q "ff ff ff ff ff" "$OUTPUT_DIR/tls12-$TIMESTAMP.txt" || grep -q "ff ff ff ff ff" "$OUTPUT_DIR/tls13-$TIMESTAMP.txt"; then
    echo "!!!!! FOUND 0xFF PATTERN !!!!!"
    echo "this is the bug. spectrum is returning garbage data."
    echo "bug: CONFIRMED - 0xff pattern detected" >> "$OUTPUT_DIR/summary-$TIMESTAMP.txt"
else
    echo "no 0xff pattern detected (connection might have worked)"
    echo "bug: not detected" >> "$OUTPUT_DIR/summary-$TIMESTAMP.txt"
fi
echo ""

echo "test complete!"
echo "results saved to: $OUTPUT_DIR/"
echo ""
echo "please upload the entire results folder to:"
echo "https://codeberg.org/azzie/spectrum/issues"
