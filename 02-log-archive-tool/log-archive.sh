#!/bin/bash

LOG_DIR=$1
ARCHIVE_DIR="archives"
LOG_FILE="archive.log"

if [ -z "$LOG_DIR" ]; then
    echo "Usage: $0 <log-directory>"
    exit 1
fi

if [ ! -d "$LOG_DIR" ]; then
    echo "Error: Directory '$LOG_DIR' does not exist."
    exit 1
fi

mkdir -p "$ARCHIVE_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${ARCHIVE_DIR}/${ARCHIVE_NAME}"

if tar -czf "$ARCHIVE_PATH" "$LOG_DIR"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Archived $LOG_DIR to $ARCHIVE_PATH" >> "$LOG_FILE"
    echo "Archive created successfully."
    echo "Archive saved to: $ARCHIVE_PATH"
else
    echo "Archive creation failed."
    exit 1
fi
