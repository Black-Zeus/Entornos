#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
declare -A classification=()
required_total=0
required_done=0
optional_total=0
optional_done=0

while read -r kind package; do
  [[ "$kind" == required || "$kind" == optional ]] || continue
  if [[ "$kind" == required || -z "${classification[$package]:-}" ]]; then
    classification[$package]="$kind"
  fi
done < <(cat "$ROOT_DIR"/packages/security-lab.txt "$ROOT_DIR"/packages/security-lab/*.txt)

for package in "${!classification[@]}"; do
  if [[ "${classification[$package]}" == required ]]; then
    required_total=$((required_total + 1))
    dpkg-query -W -f='${db:Status-Status}\n' "$package" 2>/dev/null |
      grep -qx 'installed' && required_done=$((required_done + 1))
  else
    optional_total=$((optional_total + 1))
    dpkg-query -W -f='${db:Status-Status}\n' "$package" 2>/dev/null |
      grep -qx 'installed' && optional_done=$((optional_done + 1))
  fi
done

total=$((required_total + optional_total))
done_count=$((required_done + optional_done))
percent=$((total > 0 ? done_count * 100 / total : 0))
printf 'required=%d/%d optional=%d/%d total=%d/%d percent=%d%%\n' \
  "$required_done" "$required_total" "$optional_done" "$optional_total" \
  "$done_count" "$total" "$percent"
