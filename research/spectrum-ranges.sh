#!/bin/bash

OUTPUT_DIR="../results/research"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "fetching spectrum ip ranges..."
echo ""

SPECTRUM_ASNS=(3456 7843 10796 10994 11060 11351 11426 11427 12271 20001 20115 33363 33490 33491 63365)

for asn in "${SPECTRUM_ASNS[@]}"; do
  echo "=== AS${asn} ===" | tee -a "$OUTPUT_DIR/spectrum-ranges-$TIMESTAMP.txt"

  whois -h whois.radb.net -- "-i origin AS${asn}" | grep "route:" | awk '{print $2}' | tee -a "$OUTPUT_DIR/spectrum-ranges-$TIMESTAMP.txt"

  echo "" | tee -a "$OUTPUT_DIR/spectrum-ranges-$TIMESTAMP.txt"
done

echo "ip ranges saved to: $OUTPUT_DIR/spectrum-ranges-$TIMESTAMP.txt"
echo ""

TOTAL=$(grep -E "^[0-9]" "$OUTPUT_DIR/spectrum-ranges-$TIMESTAMP.txt" | wc -l)
echo "total ranges found: $TOTAL"
