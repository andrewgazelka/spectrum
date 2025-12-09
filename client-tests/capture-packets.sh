#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "needs root to capture packets"
    echo "run: sudo ./capture-packets.sh"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="../results"
mkdir -p "$OUTPUT_DIR"
PCAP_FILE="$OUTPUT_DIR/capture-$TIMESTAMP.pcap"

echo "starting packet capture..."
echo "this will run for 30 seconds while testing connections"
echo "pcap file: $PCAP_FILE"
echo ""

tcpdump -i any -s 65535 -w "$PCAP_FILE" 'host staging.drafted.ai or host drafted.ai or host api-v2.drafted.ai' &
TCPDUMP_PID=$!

sleep 2

echo "testing connections..."
for i in {1..5}; do
    echo "attempt $i/5"
    timeout 3 openssl s_client -connect staging.drafted.ai:443 -tls1_2 2>&1 | head -10
    sleep 1
done

echo ""
echo "waiting for capture to finish..."
sleep 5

kill $TCPDUMP_PID 2>/dev/null
wait $TCPDUMP_PID 2>/dev/null

echo "capture complete: $PCAP_FILE"
echo ""
echo "to analyze, run:"
echo "  tshark -r $PCAP_FILE -V -Y 'ssl.handshake'"
echo "  wireshark $PCAP_FILE"
