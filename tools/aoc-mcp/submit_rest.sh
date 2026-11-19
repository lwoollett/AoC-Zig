#!/bin/bash
# Submit every manifest answer (2018-2025) that isn't already on the account.
# Resumable: already-solved levels answer WrongLevel (fast) and are skipped.
# Real verdicts (Incorrect/TooHigh/TooLow) abort so a bad answer can't burn
# attempts; anything else (network hiccup, truncated output) is retried.
cd "$(dirname "$0")/../.."
BIN=./zig-out/bin/aoc-mcp
LOG=/tmp/aoc_submit_rest.log

submit() { # year day part answer
  local out attempt
  for _attempt in 1 2 3; do
    out=$("$BIN" submit "$1" "$2" "$3" "$4" 2>&1 | tail -1)
    case "$out" in
      Correct|WrongLevel)
        echo "$(date '+%m-%d %H:%M:%S') $1/$2/$3 $4 -> $out" >> "$LOG"
        return 0
        ;;
      Incorrect|TooHigh|TooLow)
        echo "$(date '+%m-%d %H:%M:%S') $1/$2/$3 $4 -> $out" >> "$LOG"
        echo "$(date '+%m-%d %H:%M:%S') ABORT after $1/$2/$3: $out" >> "$LOG"
        return 1
        ;;
      *)
        echo "$(date '+%m-%d %H:%M:%S') $1/$2/$3 $4 -> retry ($out)" >> "$LOG"
        sleep 30
        ;;
    esac
  done
  echo "$(date '+%m-%d %H:%M:%S') ABORT after $1/$2/$3: no verdict after 3 tries" >> "$LOG"
  return 1
}

for Y in 2018 2019 2020 2021 2022 2023 2024 2025; do
  while read -r y d p a; do
    [ -z "$y" ] && continue
    submit "$y" "$d" "$p" "$a" || exit 1
  done < "tools/aoc-mcp/answers_$Y.txt"
done
echo "$(date '+%m-%d %H:%M:%S') ALL DONE" >> "$LOG"
