#!/usr/bin/env bash
# check.sh - play every engine against tests/reference.py and compare the output byte for byte.
#
#   tests/check.sh            all engines
#   tests/check.sh jq dc      just these
#   tests/check.sh --min ...  the same, with each engine's golfed .min file
#
# Each engine gets the same event streams: a few line-clearing bot games and a
# few random fuzz runs. The engine must print exactly what the reference prints.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
work=$(mktemp -d "${TMPDIR:-/tmp}/tris-check.XXXXXX")
trap 'rm -rf "$work"' EXIT

# name|title|options|engine file|command
# The command reads events on stdin and writes frames to stdout, running the
# engine file given in $ENGINE. It comes last, so it may contain pipes. Option "nl": the engine can't avoid one extra newline
# at the very end (make's $(info), TeX's newline on exit, gnuplot's print).
ENGINES=(
  "bc|B C T R I S||bc/bctris.bc|BC_LINE_LENGTH=0 bc -q \"\$ENGINE\""
  "cmake|C M A K E T R I S||cmake/cmaketris.cmake|ENGINE_FILE=\"\$ENGINE\" $root/cmake/cmaketris.sh --pipe"
  "dc|D C T R I S||dc/dctris.dc|DC_LINE_LENGTH=0 dc \"\$ENGINE\""
  "gnuplot|G N U P L O T T R I S|nl|gnuplot/gnuplottris.gp|ENGINE_FILE=\"\$ENGINE\" $root/gnuplot/gnuplottris.sh --pipe"
  "jq|J Q T R I S||jq/jqtris.jq|jq -nrj -f \"\$ENGINE\""
  "m4|M 4 T R I S||m4/m4tris.m4|sed 's/.*/E(&)/' | m4 \"\$ENGINE\" -"
  "make|M A K E T R I S|nl|make/maketris.mk|ENGINE_FILE=\"\$ENGINE\" $root/make/maketris.sh --pipe"
  "sendmail|S E N D M A I L T R I S||sendmail/sendmailtris.cf|ENGINE_FILE=\"\$ENGINE\" $root/sendmail/sendmailtris.sh --pipe"
  "tex|T E X T R I S|nl|tex/textris.tex|ENGINE_FILE=\"\$ENGINE\" $root/tex/textris.sh --pipe"
  "troff|T R O F F T R I S||troff/trofftris.tr|ENGINE_FILE=\"\$ENGINE\" $root/troff/trofftris.sh --pipe"
)

STREAMS=("bot 12345 300" "bot 777 150" "fuzz 7 4000" "fuzz 2024 4000" "fuzz 1 1500")

min=0
if [[ ${1:-} == --min ]]; then min=1; shift; fi
want=("$@")
fail=0
for i in "${!STREAMS[@]}"; do
  python3 "$here/gen_events.py" ${STREAMS[$i]} > "$work/ev$i"
done

for spec in "${ENGINES[@]}"; do
  IFS='|' read -r name title opts file cmd <<<"$spec"
  if (( ${#want[@]} )) && [[ " ${want[*]} " != *" $name "* ]]; then continue; fi
  file=$root/$file
  (( min )) && file=${file%.*}.min.${file##*.}
  if [[ ! -f $file ]]; then printf 'skip  %-8s (no %s)\n' "$name" "${file#$root/}"; continue; fi
  label=$name; (( min )) && label=$name.min
  for i in "${!STREAMS[@]}"; do
    python3 "$here/reference.py" "$title" < "$work/ev$i" > "$work/ref$i"
    start=$(date +%s%N)
    ENGINE=$file bash -c "$cmd" < "$work/ev$i" > "$work/out$i" 2> "$work/err$i"
    ms=$(( ($(date +%s%N) - start) / 1000000 ))
    if [[ ${opts:-} == nl && $(tail -c1 "$work/out$i" | od -An -c | tr -d ' ') == '\n' ]]; then
      truncate -s -1 "$work/out$i"
    fi
    frames=$(grep -c $'\e\[H' "$work/ref$i")
    if cmp -s "$work/ref$i" "$work/out$i"; then
      printf 'ok    %-12s %-16s %5d frames %6d ms\n' "$label" "${STREAMS[$i]}" "$frames" "$ms"
    else
      fail=1
      printf 'FAIL  %-12s %-16s\n' "$label" "${STREAMS[$i]}"
      cmp "$work/ref$i" "$work/out$i" | head -1
      head -c 300 "$work/err$i"
    fi
  done
done
exit $fail
