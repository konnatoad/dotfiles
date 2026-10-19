#!/usr/bin/env python3
import os
import sys
from pathlib import Path
from datetime import datetime

manifest = os.environ.get("IMV_MANIFEST")
current = os.environ.get("imv_current_file")
event = os.environ.get("IMV_LOG_EVENT", "unknown")
key = os.environ.get("IMV_LOG_KEY", "?")
logfile = os.environ.get("IMV_LOG_FILE")


def write(msg: str):
    print(msg, flush=True)
    if logfile:
        with open(logfile, "a", encoding="utf-8") as lf:
            lf.write(msg + "\n")


ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

if not logfile:
    sys.exit(0)

if not manifest:
    write(f"[{ts}] EVENT={event} KEY={key} ERROR=no_manifest")
    sys.exit(0)

try:
    with open(manifest, "r", encoding="utf-8") as f:
        files = [line.rstrip("\n") for line in f if line.strip()]
except OSError:
    write(f"[{ts}] EVENT={event} KEY={key} ERROR=manifest_unreadable")
    sys.exit(0)

if not current:
    write(f"[{ts}] EVENT={event} KEY={key} INDEX=?/{len(files)} DELTA=start")
    if files:
        write(f"[{ts}] FIRST={files[0]}")
        for i, path in enumerate(files[:6], 1):
            label = "HERE" if i == 1 else f"next {i - 1}"
            write(f"   [{i:04d}] {label:>6}  {path}")
    sys.exit(0)

try:
    idx = files.index(current)
except ValueError:
    try:
        idx = files.index(str(Path(current).resolve()))
    except ValueError:
        write(f"[{ts}] EVENT={event} KEY={
              key} ERROR=current_not_found FILE={current}")
        sys.exit(0)

prev_idx = None
try:
    with open(logfile, "r", encoding="utf-8") as lf:
        lines = lf.readlines()
    for line in reversed(lines):
        if "INDEX " in line and "INDEX ?/" not in line:
            try:
                prev_idx = int(line.split("INDEX ", 1)[
                               1].split("/", 1)[0].strip()) - 1
                break
            except Exception:
                pass
except OSError:
    pass

if prev_idx is None:
    delta = "start"
else:
    d = idx - prev_idx
    delta = f"{d:+d}"

write("")
write("=" * 78)
write(f"[{ts}] EVENT={event} KEY={key} INDEX {
      idx + 1}/{len(files)} DELTA={delta}")
write(f"[{ts}] FILE={files[idx]}")
write("-" * 78)

start = max(0, idx - 5)
end = min(len(files), idx + 6)

for i in range(start, end):
    mark = ">>" if i == idx else "  "
    rel = i - idx
    if rel < 0:
        label = f"prev {abs(rel)}"
    elif rel > 0:
        label = f"next {rel}"
    else:
        label = "HERE  "
    write(f"{mark} [{i + 1:04d}] {label:>6}  {files[i]}")

write("=" * 78)
