#!/bin/bash

OUTPUT_DIR="../results/research"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "researching dpi vendors and known issues..." | tee "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
echo ""

echo "=== known dpi vendors ===" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
echo ""

VENDORS=(
  "sandvine:packetlogic"
  "procera:packetlogic"
  "allot:netenforcer"
  "cisco:waas"
  "bluecoat:proxysg"
  "palo-alto:networks"
)

for vendor in "${VENDORS[@]}"; do
  name=$(echo $vendor | cut -d: -f1)
  product=$(echo $vendor | cut -d: -f2)

  echo "$name - $product" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"

  echo "  cve search: https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=$product" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"

  echo "  google: site:exploit-db.com $product" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"

  echo "" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
done

echo "=== research questions ===" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
echo ""

QUESTIONS=(
  "which dpi vendor does charter/spectrum use?"
  "does the 0xff pattern match any known vendor error state?"
  "are there cves for ssl inspection bugs in these products?"
  "what equipment did time warner cable use before merger?"
  "public procurement records for spectrum dpi purchases?"
)

for q in "${QUESTIONS[@]}"; do
  echo "- $q" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
done

echo ""
echo "=== academic research ===" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
echo ""

ACADEMIC_TERMS=(
  "isp ssl interception"
  "transparent tls proxy"
  "middlebox tls failures"
  "deep packet inspection bugs"
)

for term in "${ACADEMIC_TERMS[@]}"; do
  echo "google scholar: $term" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
  echo "  https://scholar.google.com/scholar?q=$(echo $term | sed 's/ /+/g')" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
  echo "" | tee -a "$OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
done

echo ""
echo "research notes saved to: $OUTPUT_DIR/dpi-vendors-$TIMESTAMP.txt"
