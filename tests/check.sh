#!/usr/bin/env bash
# check.sh - play every engine against tests/reference.py and compare the output byte for byte.
#
#   tests/check.sh            all engines
#   tests/check.sh jq dc      just these
#
# Each engine gets the same event streams: a few line-clearing bot games and a
# few random fuzz runs. The engine must print exactly what the reference prints.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
work=$(mktemp -d "${TMPDIR:-/tmp}/tris-check.XXXXXX")
trap 'rm -rf "$work"' EXIT

# name|title|options|command
# The command reads events on stdin and writes frames to stdout. It comes last,
# so it may contain pipes. Option "nl": the engine can't avoid one extra newline
# at the very end (make's $(info)).
ENGINES=(
  "bc|B C T R I S||BC_LINE_LENGTH=0 bc -q $root/bc/bctris.bc"
  "dc|D C T R I S||DC_LINE_LENGTH=0 dc $root/dc/dctris.dc"
  "jq|J Q T R I S||jq -nrj -f $root/jq/jqtris.jq"
  "m4|M 4 T R I S||sed 's/.*/E(&)/' | m4 $root/m4/m4tris.m4 -"
  "make|M A K E T R I S|nl|$root/make/maketris.sh --pipe"
)

STREAMS=("bot 12345 300" "bot 777 150" "fuzz 7 4000" "fuzz 2024 4000" "fuzz 1 1500")

want=("$@")
fail=0
for i in "${!STREAMS[@]}"; do
  python3 "$here/gen_events.py" ${STREAMS[$i]} > "$work/ev$i"
done

for spec in "${ENGINES[@]}"; do
  IFS='|' read -r name title opts cmd <<<"$spec"
  if (( ${#want[@]} )) && [[ " ${want[*]} " != *" $name "* ]]; then continue; fi
  for i in "${!STREAMS[@]}"; do
    python3 "$here/reference.py" "$title" < "$work/ev$i" > "$work/ref$i"
    start=$(date +%s%N)
    bash -c "$cmd" < "$work/ev$i" > "$work/out$i" 2> "$work/err$i"
    ms=$(( ($(date +%s%N) - start) / 1000000 ))
    if [[ ${opts:-} == nl && $(tail -c1 "$work/out$i" | od -An -c | tr -d ' ') == '\n' ]]; then
      truncate -s -1 "$work/out$i"
    fi
    frames=$(grep -c $'\e\[H' "$work/ref$i")
    if cmp -s "$work/ref$i" "$work/out$i"; then
      printf 'ok    %-5s %-16s %5d frames %6d ms\n' "$name" "${STREAMS[$i]}" "$frames" "$ms"
    else
      fail=1
      printf 'FAIL  %-5s %-16s\n' "$name" "${STREAMS[$i]}"
      cmp "$work/ref$i" "$work/out$i" | head -1
      head -c 300 "$work/err$i"
    fi
  done
done
exit $fail
