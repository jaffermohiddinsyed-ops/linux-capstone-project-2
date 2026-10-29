#!/bin/bash

# ============================================
# Server Health Check Script
# Linux Capstone Project 2
# ============================================

LOGFILE="/var/log/health_check.log"
PASS=0
FAIL=0

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" |
        tee -a "$LOGFILE"
}

check_service() {
    local SERVICE="$1"

    if systemctl is-active --quiet "$SERVICE"; then
        log "PASS: $SERVICE is running"
        PASS=$((PASS + 1))
    else
        log "FAIL: $SERVICE is not running"
        FAIL=$((FAIL + 1))
    fi
}

check_port() {
    local PORT="$1"
    local NAME="$2"

    if ss -ltnH | awk -v p=":$PORT" '$4 ~ (p "$") {found=1} END {exit !found}'; then
        log "PASS: Port $PORT ($NAME) is listening"
        PASS=$((PASS + 1))
    else
        log "FAIL: Port $PORT ($NAME) is not listening"
        FAIL=$((FAIL + 1))
    fi
}

check_disk() {
    local THRESHOLD=80
    local USAGE

    USAGE=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

    if [[ "$USAGE" =~ ^[0-9]+$ ]] && (( USAGE < THRESHOLD )); then
        log "PASS: Disk usage is ${USAGE}% (threshold ${THRESHOLD}%)"
        PASS=$((PASS + 1))
    else
        log "WARN: Disk usage is ${USAGE}% (threshold ${THRESHOLD}%)"
        FAIL=$((FAIL + 1))
    fi
}

check_memory() {
    local FREE_MEM

    FREE_MEM=$(free | awk '/^Mem:/ {if ($2>0) printf "%.0f", $7/$2*100; else print 0}')

    if [[ "$FREE_MEM" =~ ^[0-9]+$ ]] && (( FREE_MEM > 10 )); then
        log "PASS: Available memory is ${FREE_MEM}%"
        PASS=$((PASS + 1))
    else
        log "WARN: Low available memory (${FREE_MEM}%)"
        FAIL=$((FAIL + 1))
    fi
}

check_http() {
    local HTTP_CODE

    HTTP_CODE=$(curl --connect-timeout 3 --max-time 5 \
        -s -o /dev/null -w '%{http_code}' http://localhost/)

    if [[ "$HTTP_CODE" == "200" ]]; then
        log "PASS: HTTP response code is $HTTP_CODE"
        PASS=$((PASS + 1))
    else
        log "FAIL: HTTP response code is ${HTTP_CODE:-unknown} (expected 200)"
        FAIL=$((FAIL + 1))
    fi
}

log "========================================"
log "Server Health Check Started"
log "========================================"

check_service nginx
check_port 80 HTTP
check_disk
check_memory
check_http

log "========================================"
log "Health Check Complete: PASS=$PASS | FAIL=$FAIL"
log "========================================"
