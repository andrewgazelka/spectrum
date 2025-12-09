#!/bin/bash

OUTPUT_DIR="../results/research"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "researching spectrum legal/regulatory history..." | tee "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo ""

echo "=== fcc actions ===" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo ""

echo "search fcc.gov for:" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - charter communications enforcement" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - spectrum complaints" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - charter consent decree" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo ""

FCC_URLS=(
  "https://www.fcc.gov/enforcement/orders?search=charter"
  "https://www.fcc.gov/enforcement/orders?search=spectrum"
  "https://docs.fcc.gov/public/attachments/DOC-344159A1.pdf"
)

for url in "${FCC_URLS[@]}"; do
  echo "$url" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
done

echo "" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "=== lawsuits ===" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo ""

LAWSUIT_TERMS=(
  "charter communications class action"
  "spectrum lawsuit ssl"
  "charter securities fraud"
  "spectrum consumer protection"
)

for term in "${LAWSUIT_TERMS[@]}"; do
  echo "google: $term" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
  echo "  https://www.google.com/search?q=$(echo $term | sed 's/ /+/g')" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
  echo "" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
done

echo "=== state ag actions ===" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo ""

echo "search for state attorney general actions against charter/spectrum:" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - ny ag charter spectrum" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - california ag charter" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - state attorneys general charter settlement" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo ""

echo "=== net neutrality violations ===" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo ""

echo "previous charter/spectrum net neutrality issues:" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - throttling" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - blocking" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo "  - paid prioritization" | tee -a "$OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
echo ""

echo "legal research saved to: $OUTPUT_DIR/legal-history-$TIMESTAMP.txt"
