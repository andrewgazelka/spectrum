#!/bin/bash

OUTPUT_DIR="../results/research"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "searching for existing spectrum ssl complaints..."
echo ""

echo "=== reddit r/spectrum ===" | tee "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
echo ""

REDDIT_TERMS=(
  "spectrum ssl error"
  "spectrum https error"
  "spectrum certificate error"
  "charter ssl"
  "spectrum err_ssl_protocol_error"
  "spectrum cloudflare"
)

for term in "${REDDIT_TERMS[@]}"; do
  echo "searching: $term"
  echo "https://www.reddit.com/r/Spectrum/search/?q=$(echo $term | sed 's/ /+/g')" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
done

echo "" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
echo "=== twitter/x ===" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
echo ""

TWITTER_TERMS=(
  "spectrum ssl error"
  "charter https broken"
  "spectrum tls error"
  "@GetSpectrum ssl"
)

for term in "${TWITTER_TERMS[@]}"; do
  echo "searching: $term"
  echo "https://twitter.com/search?q=$(echo $term | sed 's/ /%20/g')" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
done

echo "" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
echo "=== github issues ===" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
echo ""

GITHUB_TERMS=(
  "spectrum ssl"
  "charter tls"
  "isp ssl interception"
)

for term in "${GITHUB_TERMS[@]}"; do
  echo "searching: $term"
  echo "https://github.com/search?q=$(echo $term | sed 's/ /+/g')&type=issues" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
done

echo "" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
echo "=== stack overflow ===" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
echo ""

SO_TERMS=(
  "spectrum ssl"
  "charter ssl error"
  "isp breaking tls"
)

for term in "${SO_TERMS[@]}"; do
  echo "searching: $term"
  echo "https://stackoverflow.com/search?q=$(echo $term | sed 's/ /+/g')" | tee -a "$OUTPUT_DIR/complaints-$TIMESTAMP.txt"
done

echo ""
echo "search urls saved to: $OUTPUT_DIR/complaints-$TIMESTAMP.txt"
echo ""
echo "manually check these and document any reports you find"
