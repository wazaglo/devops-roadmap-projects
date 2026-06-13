#!/bin/bash
set -e

# Load .env file if exists
if [ -f "$(dirname "$0")/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$(dirname "$0")/.env"
    set +a
fi

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_TOKEN="${GRAFANA_TOKEN:-}"
DASHBOARD_DIR="$(dirname "$0")/dashboards"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[-]${NC} $1"; }

if [ -z "$GRAFANA_TOKEN" ]; then
    err "GRAFANA_TOKEN not set. Add it to .env or export it:"
    echo "  export GRAFANA_TOKEN='your-service-account-token'"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    err "jq is required. Install it: sudo apt install jq"
    exit 1
fi

api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    if [ -n "$data" ]; then
        curl -s -X "$method" "$GRAFANA_URL$endpoint" \
            -H "Authorization: Bearer $GRAFANA_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$GRAFANA_URL$endpoint" \
            -H "Authorization: Bearer $GRAFANA_TOKEN" \
            -H "Content-Type: application/json"
    fi
}

log "Waiting for Grafana to be ready..."
for i in $(seq 1 30); do
    if curl -s "$GRAFANA_URL/api/health" | grep -q '"database": "ok"'; then
        log "Grafana is ready."
        break
    fi
    if [ "$i" -eq 30 ]; then
        err "Grafana not ready after 30 attempts."
        exit 1
    fi
    sleep 2
done

log "Creating folder: Monitoring Stack"
FOLDER_RESP=$(api POST "/api/folders" '{"title":"Monitoring Stack"}')
FOLDER_UID=$(echo "$FOLDER_RESP" | jq -r '.uid // empty')
if [ -z "$FOLDER_UID" ]; then
    warn "Folder may already exist. Fetching existing..."
    FOLDERS=$(api GET "/api/folders")
    FOLDER_UID=$(echo "$FOLDERS" | jq -r '.[] | select(.title=="Monitoring Stack") | .uid')
fi
log "Folder UID: $FOLDER_UID"

create_dashboard() {
    local file="$1"
    local name
    name=$(jq -r '.dashboard.title' "$file")

    log "Creating dashboard: $name"
    local payload
    payload=$(jq --arg uid "$FOLDER_UID" '.folderUid = $uid' "$file")
    RESP=$(api POST "/api/dashboards/db" "$payload")
    local status
    status=$(echo "$RESP" | jq -r '.status // .message')
    if echo "$RESP" | grep -q '"status":"success"'; then
        log "  Dashboard created: $name"
    else
        warn "  Response: $status"
    fi
}

create_dashboard "$DASHBOARD_DIR/node-exporter.json"
create_dashboard "$DASHBOARD_DIR/nginx.json"
create_dashboard "$DASHBOARD_DIR/postgres.json"
create_dashboard "$DASHBOARD_DIR/loki.json"

log "Fetching Prometheus datasource UID..."
DATASOURCES=$(api GET "/api/datasources")
DS_UID=$(echo "$DATASOURCES" | jq -r '.[] | select(.type=="prometheus") | .uid' | head -1)
if [ -z "$DS_UID" ]; then
    err "Prometheus datasource not found."
    exit 1
fi
log "Prometheus datasource UID: $DS_UID"

log "Creating alert rules..."

create_alert() {
    local title="$1"
    local expr="$2"
    local for_duration="${3:-5m}"
    local severity="${4:-critical}"

    local payload
    payload=$(cat <<EOF
{
  "title": "$title",
  "condition": "C",
  "data": [
    {
      "refId": "A",
      "queryType": "",
      "datasourceUid": "$DS_UID",
      "model": {
        "expr": "$expr",
        "legendFormat": "__auto",
        "refId": "A"
      }
    },
    {
      "refId": "C",
      "queryType": "threshold",
      "relativeTimeRange": { "from": 0, "to": 0 },
      "model": {
        "conditions": [
          {
            "evaluator": { "params": [1], "type": "gt" },
            "operator": { "type": "and" },
            "query": { "params": ["A"] },
            "reducer": { "params": [], "type": "last" },
            "type": "query"
          }
        ]
      }
    }
  ],
  "noDataState": "NoData",
  "execErrState": "Error",
  "for": "$for_duration",
  "annotations": { "summary": "$title" },
  "labels": { "severity": "$severity" }
}
EOF
)
    RESP=$(api POST "/api/v1/provisioning/alert-rules" "$payload")
    if echo "$RESP" | grep -q '"uid"'; then
        log "  Alert created: $title"
    else
        warn "  Alert response: $(echo "$RESP" | jq -r '.message // .error // empty' 2>/dev/null || echo "$RESP")"
    fi
}

create_alert \
    "High CPU Usage" \
    "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80" \
    "5m" \
    "critical"

create_alert \
    "High Memory Usage" \
    "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85" \
    "5m" \
    "critical"

create_alert \
    "High Disk Usage" \
    "(1 - (node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"})) * 100 > 90" \
    "5m" \
    "warning"

create_alert \
    "Nginx Down" \
    "up{job=\"nginx-exporter\"} == 0" \
    "1m" \
    "critical"

create_alert \
    "PostgreSQL Down" \
    "up{job=\"postgres-exporter\"} == 0" \
    "1m" \
    "critical"

log "Creating Loki alert rules..."

LOKI_DS_UID=$(echo "$DATASOURCES" | jq -r '.[] | select(.type=="loki") | .uid' | head -1)
if [ -n "$LOKI_DS_UID" ]; then
    create_loki_alert() {
        local title="$1"
        local expr="$2"
        local for_duration="${3:-5m}"
        local severity="${4:-critical}"

        local payload
        payload=$(cat <<EOF
{
  "title": "$title",
  "condition": "C",
  "data": [
    {
      "refId": "A",
      "queryType": "",
      "datasourceUid": "$LOKI_DS_UID",
      "model": {
        "expr": "$expr",
        "refId": "A"
      }
    },
    {
      "refId": "C",
      "queryType": "threshold",
      "relativeTimeRange": { "from": 0, "to": 0 },
      "model": {
        "conditions": [
          {
            "evaluator": { "params": [1], "type": "gt" },
            "operator": { "type": "and" },
            "query": { "params": ["A"] },
            "reducer": { "params": [], "type": "last" },
            "type": "query"
          }
        ]
      }
    }
  ],
  "noDataState": "NoData",
  "execErrState": "Error",
  "for": "$for_duration",
  "annotations": { "summary": "$title" },
  "labels": { "severity": "$severity" }
}
EOF
)
        RESP=$(api POST "/api/v1/provisioning/alert-rules" "$payload")
        if echo "$RESP" | grep -q '"uid"'; then
            log "  Alert created: $title"
        else
            warn "  Alert response: $(echo "$RESP" | jq -r '.message // .error // empty' 2>/dev/null || echo "$RESP")"
        fi
    }

    create_loki_alert \
        "High Error Log Rate" \
        "sum(rate({job=~\".+\"} |~ \"(?i)(error|exception|fatal|panic)\" [5m])) > 5" \
        "5m" \
        "critical"

    create_loki_alert \
        "No Logs Detected" \
        "sum(count_over_time({job=~\".+\"}[5m])) == 0" \
        "10m" \
        "warning"

    create_loki_alert \
        "Alloy Collection Errors" \
        "sum(rate({service_name=\"alloy\"} |~ \"(?i)error\" [5m])) > 0" \
        "5m" \
        "critical"
else
    warn "Loki datasource not found. Skipping Loki alerts."
fi

echo ""
log "Setup complete!"
echo ""
echo "  Grafana:     $GRAFANA_URL  (admin/admin)"
echo "  Prometheus:  http://localhost:9090"
echo ""
echo "  Dashboards:  Monitoring Stack folder"
echo "  Alerts:      Alerting > Alert rules"
