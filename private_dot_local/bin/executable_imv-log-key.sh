#!/usr/bin/env bash
event="$1"
key="$2"

IMV_LOG_EVENT="$event" \
  IMV_LOG_KEY="$key" \
  python3 ~/.local/bin/imv-log-window.py
