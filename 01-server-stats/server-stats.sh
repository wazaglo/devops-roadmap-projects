#!/bin/bash

echo "====================================="
echo "      SERVER PERFORMANCE STATS"
echo "====================================="
echo

# CPU Usage
echo "CPU Usage:"
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
printf "Total CPU Usage: %.2f%%\n" "$cpu_usage"
echo

# Memory Usage
echo "Memory Usage:"
free -m | awk '
/Mem:/ {
    used=$3
    free=$4
    total=$2
    percent=(used/total)*100

    printf "Total Memory: %d MB\n", total
    printf "Used Memory : %d MB\n", used
    printf "Free Memory : %d MB\n", free
    printf "Usage       : %.2f%%\n", percent
}'
echo

# Disk Usage
echo "Disk Usage:"
df -h / | awk 'NR==2 {
    print "Total Disk  :", $2
    print "Used Disk   :", $3
    print "Free Disk   :", $4
    print "Usage       :", $5
}'
echo

# Top 5 Processes by CPU
echo "Top 5 Processes by CPU Usage:"
ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6
echo

# Top 5 Processes by Memory
echo "Top 5 Processes by Memory Usage:"
ps -eo pid,comm,%mem --sort=-%mem | head -n 6
echo

echo "====================================="
echo "          REPORT COMPLETE"
echo "====================================="
