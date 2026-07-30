#!/usr/bin/env bash
set -Eeuo pipefail

awk '
  /^MemTotal:/     { mem_total = $2 }
  /^MemAvailable:/ { mem_available = $2 }
  /^SwapTotal:/    { swap_total = $2 }
  /^SwapFree:/     { swap_free = $2 }
  END {
    ram = mem_total > 0 ? int(((mem_total - mem_available) * 100) / mem_total) : 0
    if (swap_total > 0) {
      swap = int(((swap_total - swap_free) * 100) / swap_total)
      printf "󰍛 RAM %d%% SWP %d%%\n", ram, swap
    } else {
      printf "󰍛 RAM %d%% SWP --\n", ram
    }
  }
' /proc/meminfo
