#!/usr/bin/env bash
# temps_record.sh: log every °C reading from `sensors` at a fixed interval,
# then print a per-sensor MIN / AVG / MAX table. Full log is kept as CSV.
#
# Usage:
#   temps_record.sh                         # record until Ctrl+C
#   temps_record.sh llama-cli -m model.gguf # record only while the command runs
#   temps_record.sh -i 1 -o run1.csv ...    # 1s interval, custom output file

interval=2
out="$HOME/temps_$(date +%Y%m%d_%H%M%S).csv"
while getopts "i:o:" opt; do
  case $opt in
    i) interval=$OPTARG ;;
    o) out=$OPTARG ;;
    *) echo "usage: temps_record.sh [-i sec] [-o file.csv] [command ...]"; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

echo "time,sensor,celsius" > "$out" || exit 1

# Sensor name = chip/label (e.g. acpitz-acpi-0/temp1) so repeated labels stay distinct.
sample() {
  local ts
  ts=$(date +%H:%M:%S)
  sensors | awk -v ts="$ts" -F: '
    NR == 1 || prev == "" { chip = $0 }
    { prev = $0 }
    /°C/ && NF >= 2 {
      if (match($2, /[+-]?[0-9]+\.[0-9]+/))
        printf "%s,%s/%s,%.1f\n", ts, chip, $1, substr($2, RSTART, RLENGTH) + 0
    }' >> "$out"
}

summary() {
  echo
  awk -F, 'NR > 1 {
      l = $2; v = $3
      if (!(l in n)) { order[++k] = l; mn[l] = v; mx[l] = v }
      n[l]++; s[l] += v
      if (v < mn[l]) mn[l] = v
      if (v > mx[l]) mx[l] = v
      if (NR == 2) first = $1
      last = $1
    }
    END {
      printf "Recorded %s -> %s\n\n", first, last
      printf "%-36s %7s %7s %7s %7s\n", "SENSOR", "MIN", "AVG", "MAX", "SAMPLES"
      for (i = 1; i <= k; i++) {
        l = order[i]
        printf "%-36s %7.1f %7.1f %7.1f %7d\n", l, mn[l], s[l] / n[l], mx[l], n[l]
      }
    }' "$out"
  echo
  echo "Full log: $out"
}

# Sampler runs in the background; Ctrl+C stops the foreground, not the script.
( while true; do sample; sleep "$interval"; done ) &
sampler=$!
trap ':' INT

if [ $# -gt 0 ]; then
  "$@"
else
  echo "Recording to $out every ${interval}s. Ctrl+C to stop."
  wait $sampler
fi

pkill -P "$sampler" 2>/dev/null   # stray sleep
kill $sampler 2>/dev/null
wait $sampler 2>/dev/null
sample
summary
