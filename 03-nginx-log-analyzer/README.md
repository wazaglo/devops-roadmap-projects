# NGINX Log Analyzer

A lightweight bash script that analyzes NGINX access logs and generates a summary report of key metrics.

## Features

- **Top 5 IP addresses** with the most requests
- **Top 5 most requested paths** (endpoints)
- **Top 5 response status codes** (200, 404, 500, etc.)
- **Top 5 user agents** (browsers, bots, monitoring tools)

## Requirements

- Bash (standard on Linux/macOS)
- `awk`, `sort`, `uniq` (coreutils - pre-installed on most systems)

## Installation

```bash
git clone https://github.com/wazaglo/devops-roadmap-projects
cd 03-nginx-log-analyzer
chmod +x nginx-log-analyzer.sh
```

## Usage

```bash
./nginx-log-analyzer.sh <nginx-access-log-file>
```

**Example:**
```bash
./nginx-log-analyzer.sh /var/log/nginx/access.log
./nginx-log-analyzer.sh ./nginx-logs
```

## How It Works

The script uses standard Unix text processing tools:

1. **awk** - Extracts specific fields from each log line (IP, path, status code, user agent)
2. **sort** - Orders entries for counting
3. **uniq -c** - Counts unique occurrences
4. **sort -nr** - Sorts by count descending
5. **head -5** - Limits to top 5 results

Each metric uses a tailored awk field extraction based on the NGINX combined log format:
```
$1 = IP address
$9 = Response status code
$2 (within quoted request) = Requested path
$6 (within quoted fields) = User agent
```

## Log Format

Expects **NGINX combined log format** (default):
```
log_format combined '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent"';
```

Example line:
```
178.128.94.113 - - [04/Oct/2024:00:00:18 +0000] "GET /v1-health HTTP/1.1" 200 51 "-" "DigitalOcean Uptime Probe 0.22.0"
```
##Project URL

https://roadmap.sh/projects/nginx-log-analyser

## Author 

Wisdom Azaglo
