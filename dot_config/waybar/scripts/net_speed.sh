#!/bin/bash

IFACE="enp6s0"
INTERVAL=1

read_bytes() {
  grep "$IFACE" /proc/net/dev | awk '{print $2, $10}'
}

read -r RX_BEFORE TX_BEFORE < <(read_bytes)
sleep "$INTERVAL"
read -r RX_AFTER TX_AFTER < <(read_bytes)

RX_DIFF=$((RX_AFTER - RX_BEFORE))
TX_DIFF=$((TX_AFTER - TX_BEFORE))

# Convert to bits per second
RX_BPS=$((RX_DIFF * 8))
TX_BPS=$((TX_DIFF * 8))

format_speed_iec() {
  local BPS=$1
  if ((BPS < 1024)); then
    printf "%10s" "${BPS} bps"
  elif ((BPS < 1048576)); then
    printf "%10s" "$((BPS / 1024)) Kbps"
  elif ((BPS < 1073741824)); then
    printf "%10s" "$((BPS / 1048576)) Mbps"
  else
    printf "%10s" "$((BPS / 1073741824)) Gbps"
  fi
}

RX_HUMAN=$(format_speed_iec "$RX_BPS")
TX_HUMAN=$(format_speed_iec "$TX_BPS")

printf "↓ %s   ↑ %s\n" "$RX_HUMAN" "$TX_HUMAN"
