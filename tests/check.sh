#!/usr/bin/env bash
# check.sh - play every engine against tests/reference.py and compare the output byte for byte.
#
#   tests/check.sh            all engines
#   tests/check.sh jq dc      just these
#   tests/check.sh --min ...  the same, with each engine's golfed .min file
#   tests/check.sh -j 1 ...   one run at a time (default: one per CPU)
#
# Each engine gets the same event streams: a few line-clearing bot games and a
# few random fuzz runs. The engine must print exactly what the reference prints.
# Every (engine, stream) pair is a separate job, and the jobs run in parallel;
# results are still printed in table order. The ms column is wall time per run,
# so it is noisy while other jobs share the CPU; use -j 1 to time engines.
# The scheduler uses `wait -n`, which needs bash 4.3 or newer.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
work=$(mktemp -d "${TMPDIR:-/tmp}/tris-check.XXXXXX")
sched=""
trap '[[ -n $sched ]] && kill "$sched" 2>/dev/null; rm -rf "$work"' EXIT
trap 'exit 130' INT TERM

# name|title|options|engine file|tool|command
# The command reads events on stdin and writes frames to stdout, running the
# engine file given in $ENGINE. It comes last, so it may contain pipes. Option "nl": the engine can't avoid one extra newline
# at the very end (make's $(info), TeX's newline on exit, gnuplot's print).
# Engines whose tool isn't installed are skipped.
ENGINES=(
  "awk|A W K T R I S||awk/awktris.awk|awk|ENGINE_FILE=\"\$ENGINE\" $root/awk/awktris.sh --pipe"
  "bc|B C T R I S||bc/bctris.bc|bc|BC_LINE_LENGTH=0 bc -q \"\$ENGINE\""
  "cmake|C M A K E T R I S||cmake/cmaketris.cmake|cmake|ENGINE_FILE=\"\$ENGINE\" $root/cmake/cmaketris.sh --pipe"
  "cpp|C P P T R I S||cpp/cpptris.cpp|g++|ENGINE_FILE=\"\$ENGINE\" $root/cpp/cpptris.sh --pipe"
  "dc|D C T R I S||dc/dctris.dc|dc|DC_LINE_LENGTH=0 dc \"\$ENGINE\""
  "emacs|E M A C S T R I S||emacs/emacstris.el|emacs|ENGINE_FILE=\"\$ENGINE\" $root/emacs/emacstris.sh --pipe"
  "gnuplot|G N U P L O T T R I S|nl|gnuplot/gnuplottris.gp|gnuplot|ENGINE_FILE=\"\$ENGINE\" $root/gnuplot/gnuplottris.sh --pipe"
  "jq|J Q T R I S||jq/jqtris.jq|jq|jq -nrj -f \"\$ENGINE\""
  "m4|M 4 T R I S||m4/m4tris.m4|m4|sed 's/.*/E(&)/' | m4 \"\$ENGINE\" -"
  "make|M A K E T R I S|nl|make/maketris.mk|make|ENGINE_FILE=\"\$ENGINE\" $root/make/maketris.sh --pipe"
  "postscript|P O S T S C R I P T T R I S||postscript/postscripttris.ps|gs|ENGINE_FILE=\"\$ENGINE\" $root/postscript/postscripttris.sh --pipe"
  "sed|S E D T R I S|nl|sed/sedtris.sed|sed|ENGINE_FILE=\"\$ENGINE\" $root/sed/sedtris.sh --pipe"
  "sendmail|S E N D M A I L T R I S||sendmail/sendmailtris.cf|sendmail|ENGINE_FILE=\"\$ENGINE\" $root/sendmail/sendmailtris.sh --pipe"
  "sqlite|S Q L I T E T R I S||sqlite/sqlitetris.sql|sqlite3|ENGINE_FILE=\"\$ENGINE\" $root/sqlite/sqlitetris.sh --pipe"
  "tex|T E X T R I S|nl|tex/textris.tex|tex|ENGINE_FILE=\"\$ENGINE\" $root/tex/textris.sh --pipe"
  "troff|T R O F F T R I S||troff/trofftris.tr|troff|ENGINE_FILE=\"\$ENGINE\" $root/troff/trofftris.sh --pipe"
  "vim|V I M T R I S||vim/vimtris.vim|vim|ENGINE_FILE=\"\$ENGINE\" $root/vim/vimtris.sh --pipe"
  "xslt|X S L T T R I S||xslt/xslttris.xsl|xsltproc|ENGINE_FILE=\"\$ENGINE\" $root/xslt/xslttris.sh --pipe"
)

STREAMS=("bot 12345 300" "bot 777 150" "fuzz 7 4000" "fuzz 2024 4000" "fuzz 1 1500")

min=0 jobs=$(nproc 2>/dev/null || echo 4)
while [[ ${1:-} == -* ]]; do
  case $1 in
    --min) min=1 ;;
    -j) jobs=${2:?-j needs a number}; shift ;;
    -j*) jobs=${1#-j} ;;
    *) echo "check.sh: unknown option $1" >&2; exit 2 ;;
  esac
  shift
done
want=("$@")

have() {
  [[ $1 == sendmail ]] && { [[ -x /usr/sbin/sendmail || -x /usr/lib/sendmail ]] && return 0; }
  command -v "$1" >/dev/null 2>&1
}

for i in "${!STREAMS[@]}"; do
  python3 "$here/gen_events.py" ${STREAMS[$i]} > "$work/ev$i"
done

# run_one KEY LABEL TITLE OPTS FILE CMD STREAM: one engine on one stream; the
# result line(s) go to $work/res.KEY, which appears only when the run is done.
run_one() {
  local key=$1 label=$2 title=$3 opts=$4 file=$5 cmd=$6 i=$7 d=$work/$1 start ms frames
  mkdir "$d"
  python3 "$here/reference.py" "$title" < "$work/ev$i" > "$d/ref"
  start=$(date +%s%N)
  ENGINE=$file bash -c "$cmd" < "$work/ev$i" > "$d/out" 2> "$d/err"
  ms=$(( ($(date +%s%N) - start) / 1000000 ))
  if [[ $opts == nl && $(tail -c1 "$d/out" | od -An -c | tr -d ' ') == '\n' ]]; then
    truncate -s -1 "$d/out"
  fi
  frames=$(grep -c $'\e\[H' "$d/ref")
  {
    if cmp -s "$d/ref" "$d/out"; then
      printf 'ok    %-12s %-16s %5d frames %6d ms\n' "$label" "${STREAMS[$i]}" "$frames" "$ms"
    else
      printf 'FAIL  %-12s %-16s\n' "$label" "${STREAMS[$i]}"
      cmp "$d/ref" "$d/out" 2>&1 | head -1
      head -c 300 "$d/err" | tr -d '\033'; echo
    fi
  } > "$d/res"
  rm -f "$d/ref" "$d/out" "$d/err"
  mv "$d/res" "$work/res.$key"
}

for w in "${want[@]}"; do
  [[ " ${ENGINES[*]%%|*} " == *" $w "* ]] || { echo "check.sh: no engine '$w'" >&2; exit 2; }
done

# Build the job list in table order; skips are results right away.
keys=() args=() n=0
for spec in "${ENGINES[@]}"; do
  IFS='|' read -r name title opts file tool cmd <<<"$spec"
  if (( ${#want[@]} )) && [[ " ${want[*]} " != *" $name "* ]]; then continue; fi
  file=$root/$file
  (( min )) && file=${file%.*}.min.${file##*.}
  label=$name; (( min )) && label=$name.min
  if [[ ! -f $file ]]; then
    printf 'skip  %-12s (no %s)\n' "$label" "${file#$root/}" > "$work/res.$n"; keys+=("$n"); (( n++ )); continue
  fi
  if ! have "$tool"; then
    printf 'skip  %-12s (%s is not installed)\n' "$label" "$tool" > "$work/res.$n"; keys+=("$n"); (( n++ )); continue
  fi
  for i in "${!STREAMS[@]}"; do
    keys+=("$n"); args+=("$n|$label|$title|$opts|$file|$i|$cmd"); (( n++ ))
  done
done

# The scheduler keeps up to $jobs runs going; the main loop prints results in order.
(
  trap 'kill $(jobs -p) 2>/dev/null; exit 1' TERM
  for a in "${args[@]}"; do
    IFS='|' read -r key label title opts file i cmd <<<"$a"
    while (( $(jobs -rp | wc -l) >= jobs )); do wait -n; done
    run_one "$key" "$label" "$title" "$opts" "$file" "$cmd" "$i" &
  done
  wait
) & sched=$!

fail=0
for key in "${keys[@]}"; do
  while [[ ! -e $work/res.$key ]]; do
    kill -0 "$sched" 2>/dev/null || [[ -e $work/res.$key ]] || { echo "check.sh: a run died" >&2; exit 1; }
    sleep 0.05
  done
  cat "$work/res.$key"
  grep -q '^FAIL' "$work/res.$key" && fail=1
done
wait "$sched"
exit $fail
