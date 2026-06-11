# Log Archive Tool

A simple Bash script that archives log directories by compressing them into a `.tar.gz` file and storing them in a dedicated archive directory.

## Project URL

https://roadmap.sh/projects/log-archive-tool

## Description

This tool accepts a log directory as an argument, compresses its contents into a timestamped archive, and stores the archive in an `archives` directory. Each archive operation is recorded in `archive.log`.

## Features

* Archive any log directory from the command line
* Compress logs into `.tar.gz` format
* Generate timestamped archive names
* Store archives in a dedicated directory
* Record archive operations in a log file
* Basic input validation and error handling

## Repository URL

https://github.com/wazaglo/devops-roadmap-projects/tree/main/02-log-archive-tool

## How to Run

### Clone the Repository

```bash
git clone https://github.com/wazaglo/devops-roadmap-projects.git
cd devops-roadmap-projects/02-log-archive-tool
```

### Make the Script Executable

```bash
chmod +x log-archive.sh
```

### Run the Script

```bash
./log-archive.sh <log-directory>
```

Example:

```bash
./log-archive.sh /var/log
```

For protected system log directories:

```bash
sudo ./log-archive.sh /var/log
```

## Example Output

```text
archives/
└── logs_archive_20260611_101530.tar.gz

archive.log
```

Example log entry:

```text
2026-06-11 10:15:30 - Archived /var/log to archives/logs_archive_20260611_101530.tar.gz
```

## Requirements

* Linux/Unix-based operating system
* Bash
* tar

## Author

Wisdom Azaglo
