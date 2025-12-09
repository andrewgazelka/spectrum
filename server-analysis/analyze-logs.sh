#!/bin/bash

LOG_FILE="${1:-/var/log/nginx/access.log}"
OUTPUT_DIR="../results"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

if [ ! -f "$LOG_FILE" ]; then
    echo "log file not found: $LOG_FILE"
    echo "usage: ./analyze-logs.sh /path/to/access.log"
    exit 1
fi

echo "analyzing server logs for spectrum ssl failures"
echo "log file: $LOG_FILE"
echo ""

echo "extracting failed connections..."
grep -E "SSL|ssl|400|502|503" "$LOG_FILE" | \
    awk '{print $1}' | sort -u > "$OUTPUT_DIR/failed_ips_$TIMESTAMP.txt"

FAIL_COUNT=$(wc -l < "$OUTPUT_DIR/failed_ips_$TIMESTAMP.txt")
echo "found $FAIL_COUNT unique ips with errors"
echo ""

echo "looking up asn for each ip..."
echo "ip,asn,org" > "$OUTPUT_DIR/asn_lookup_$TIMESTAMP.csv"

while read ip; do
    asn_data=$(whois -h whois.cymru.com " -v $ip" 2>/dev/null | tail -1)
    asn=$(echo "$asn_data" | awk '{print $1}')
    org=$(echo "$asn_data" | awk '{$1=$2=$3=""; print $0}' | xargs)

    echo "$ip,AS$asn,$org" >> "$OUTPUT_DIR/asn_lookup_$TIMESTAMP.csv"

    if [[ "$asn" =~ ^(3456|7843|10796|10994|11060|11351|11426|11427|12271|20001|20115|33363|33490|33491|63365)$ ]]; then
        echo "SPECTRUM: $ip -> AS$asn"
    fi
done < "$OUTPUT_DIR/failed_ips_$TIMESTAMP.txt"

echo ""
echo "counting failures by asn..."
tail -n +2 "$OUTPUT_DIR/asn_lookup_$TIMESTAMP.csv" | \
    cut -d',' -f2 | sort | uniq -c | sort -rn > "$OUTPUT_DIR/asn_counts_$TIMESTAMP.txt"

echo ""
echo "top failing asns:"
head -20 "$OUTPUT_DIR/asn_counts_$TIMESTAMP.txt"

echo ""
SPECTRUM_FAILS=$(grep -E "AS(3456|7843|10796|10994|11060|11351|11426|11427|12271|20001|20115|33363|33490|33491|63365)" "$OUTPUT_DIR/asn_lookup_$TIMESTAMP.csv" | wc -l)
echo "total spectrum failures: $SPECTRUM_FAILS"

echo ""
echo "analysis complete"
echo "results in: $OUTPUT_DIR/"
