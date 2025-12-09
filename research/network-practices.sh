#!/bin/bash

OUTPUT_DIR="../results/research"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "researching spectrum network management disclosures..."
echo ""

echo "key urls to check:"
echo ""

URLS=(
  "https://www.spectrum.com/policies/network-management-practices"
  "https://www.spectrum.net/support/internet/network-management"
  "https://www.charter.com/about-us/policies"
  "https://www.spectrum.com/policies/privacy-policy"
)

for url in "${URLS[@]}"; do
  echo "checking: $url"
  echo "$url" >> "$OUTPUT_DIR/network-practices-$TIMESTAMP.txt"

  if command -v curl > /dev/null; then
    curl -s -L "$url" > "$OUTPUT_DIR/page-$(echo $url | md5sum | cut -d' ' -f1).html" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "  saved"
    else
      echo "  failed to fetch"
    fi
  fi

  echo ""
done

echo ""
echo "search these pages for:"
echo "  - ssl"
echo "  - tls"
echo "  - inspection"
echo "  - decrypt"
echo "  - deep packet"
echo "  - dpi"
echo "  - middlebox"
echo "  - traffic management"
echo ""

if command -v grep > /dev/null; then
  echo "searching downloaded pages..."
  for html in "$OUTPUT_DIR"/page-*.html; do
    if [ -f "$html" ]; then
      echo "=== $html ===" >> "$OUTPUT_DIR/network-practices-keywords-$TIMESTAMP.txt"
      grep -iE "ssl|tls|inspect|decrypt|deep.packet|dpi|middlebox|traffic.management" "$html" >> "$OUTPUT_DIR/network-practices-keywords-$TIMESTAMP.txt" 2>/dev/null
      echo "" >> "$OUTPUT_DIR/network-practices-keywords-$TIMESTAMP.txt"
    fi
  done

  if [ -f "$OUTPUT_DIR/network-practices-keywords-$TIMESTAMP.txt" ]; then
    echo "keyword matches saved to: $OUTPUT_DIR/network-practices-keywords-$TIMESTAMP.txt"
  else
    echo "no keyword matches found"
  fi
fi

echo ""
echo "results in: $OUTPUT_DIR/"
