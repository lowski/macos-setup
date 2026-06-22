#!/usr/bin/env bash
# Emit a styled tmux status segment: CPU / MEM / GPU / DISK.
# Called from tmux.conf status-right via #(). macOS only; degrades to "--"
# for any metric the host can't report. Colors mirror the tmux.conf palette.
set -euo pipefail

label="#[fg=#6c7086]"   # muted
value="#[fg=#cdd6f4]"   # text
sep="  "

# CPU: 100 - idle%, from `top` field "<n>% idle".
# Percentages are right-aligned to two digits so the layout holds steady below 10%.
cpu=$(top -l1 -n0 2>/dev/null \
  | awk '/CPU usage/ {gsub(/%/,"",$7); printf "%2d", 100-$7}') || cpu=""
[ -n "$cpu" ] && cpu="${cpu}%" || cpu="--"

# MEM: 100 - system-wide free percentage.
mem=$(memory_pressure 2>/dev/null \
  | awk '/free percentage/ {gsub(/%/,"",$NF); printf "%2d", 100-$NF}') || mem=""
[ -n "$mem" ] && mem="${mem}%" || mem="--"

# GPU: IOAccelerator "Device Utilization %" (Apple Silicon / most GPUs).
gpu=$(ioreg -r -d 1 -c IOAccelerator 2>/dev/null \
  | grep -o '"Device Utilization %"=[0-9]*' | head -1 | grep -o '[0-9]*$') || gpu=""
[ -n "$gpu" ] && gpu="$(printf '%2d%%' "$gpu")" || gpu="--"

# DISK: available space on the root volume.
disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}') || disk=""
[ -n "$disk" ] || disk="--"

printf '%sCPU %s%s%s%sMEM %s%s%s%sGPU %s%s%s%sDISK %s%s' \
  "$label" "$value" "$cpu" "$sep" \
  "$label" "$value" "$mem" "$sep" \
  "$label" "$value" "$gpu" "$sep" \
  "$label" "$value" "$disk"
