#!/bin/bash

ZONE_ID="${CF_ZONE_ID:-}"
API_KEY="${CF_API_KEY:-}"
EMAIL="${CF_EMAIL:-}"

if [ -z "$ZONE_ID" ] || [ -z "$API_KEY" ] || [ -z "$EMAIL" ]; then
    echo "missing cloudflare credentials"
    echo ""
    echo "set these environment variables:"
    echo "  export CF_ZONE_ID='your-zone-id'"
    echo "  export CF_API_KEY='your-api-key'"
    echo "  export CF_EMAIL='your@email.com'"
    echo ""
    echo "or pass them as arguments:"
    echo "  ./cloudflare-stats.sh zone_id api_key email"
    exit 1
fi

OUTPUT_DIR="../results"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "fetching cloudflare analytics..."
echo ""

ANALYTICS_FILE="$OUTPUT_DIR/cloudflare_analytics_$TIMESTAMP.json"

curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/analytics/colos" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" > "$ANALYTICS_FILE"

if grep -q '"success":true' "$ANALYTICS_FILE"; then
    echo "analytics fetched successfully"
    echo "saved to: $ANALYTICS_FILE"
else
    echo "failed to fetch analytics"
    cat "$ANALYTICS_FILE"
    exit 1
fi

echo ""
echo "to analyze spectrum-specific errors, you'll need to:"
echo "1. log into cloudflare dashboard"
echo "2. go to analytics > traffic"
echo "3. filter by asn: 11426, 11427, 12271, 20001, 33363, 33490, 33491"
echo "4. export the data"
