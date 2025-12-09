#!/bin/bash

OUTPUT_DIR="../results/research"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "finding all spectrum/charter asns..."
echo ""

SEARCH_TERMS=(
  "charter communications"
  "charter comm"
  "spectrum"
  "time warner cable"
  "twc"
  "bright house"
  "brighthouse"
)

echo "searching asn databases..." | tee "$OUTPUT_DIR/spectrum-asns-$TIMESTAMP.txt"
echo "" | tee -a "$OUTPUT_DIR/spectrum-asns-$TIMESTAMP.txt"

for term in "${SEARCH_TERMS[@]}"; do
  echo "=== searching: $term ===" | tee -a "$OUTPUT_DIR/spectrum-asns-$TIMESTAMP.txt"

  if command -v curl > /dev/null; then
    curl -s "https://bgp.he.net/search?search%5Bsearch%5D=$(echo $term | sed 's/ /%20/g')&commit=Search" 2>/dev/null | \
      grep -oP 'AS[0-9]+' | sort -u | tee -a "$OUTPUT_DIR/spectrum-asns-$TIMESTAMP.txt"
  fi

  echo "" | tee -a "$OUTPUT_DIR/spectrum-asns-$TIMESTAMP.txt"
done

echo ""
echo "known spectrum asns from documentation:"
cat ../spectrum-asns.txt

echo ""
echo "all findings saved to: $OUTPUT_DIR/spectrum-asns-$TIMESTAMP.txt"
echo ""
echo "manual verification needed:"
echo "  https://bgp.he.net/ - search for charter, spectrum, time warner"
echo "  https://ipinfo.io/AS11426 - check each asn"
