#!/usr/bin/env bash
# check.sh - play every engine against _tests/reference.py and compare the output byte for byte.
#
#   _tests/check.sh            all engines
#   _tests/check.sh jq dc      just these
#   _tests/check.sh --min ...  the same, with each engine's golfed .min file
#   _tests/check.sh -j 1 ...   one run at a time (default: one per CPU)
#   _tests/check.sh --strict   fail, instead of skipping, when a tool is missing (CI)
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

# The games are play.sh's GAMES table (dir|game|engine file|tool|description).
# Each engine runs through its launcher, <dir>/<game>.sh --pipe, with the
# engine file in ENGINE_FILE. Engines whose tool isn't installed are skipped.
eval "$(sed -n '/^GAMES=(/,/^)/p' "$root/play.sh")"

STREAMS=("bot 12345 300" "bot 777 150" "fuzz 7 4000" "fuzz 2024 4000" "fuzz 1 1500")

min=0 strict=0 jobs=$(nproc 2>/dev/null || echo 4)
while [[ ${1:-} == -* ]]; do
  case $1 in
    --min) min=1 ;;
    --strict) strict=1 ;;
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
  # shellcheck disable=SC2086 # each stream is "mode seed count", split on purpose
  python3 "$here/gen_events.py" ${STREAMS[$i]} > "$work/ev$i"
done

# run_one KEY LABEL TITLE FILE LAUNCHER STREAM: one engine on one stream;
# the result line(s) go to $work/res.KEY, which appears only when the run is done.
run_one() {
  local key=$1 label=$2 title=$3 file=$4 launcher=$5 i=$6 d=$work/$1 start ms frames
  mkdir "$d"
  python3 "$here/reference.py" "$title" < "$work/ev$i" > "$d/ref"
  start=$(date +%s%N)
  ENGINE_FILE=$file "$launcher" --pipe < "$work/ev$i" > "$d/out" 2> "$d/err"
  ms=$(( ($(date +%s%N) - start) / 1000000 ))
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
  [[ " ${GAMES[*]%%|*} " == *" $w "* ]] || { echo "check.sh: no engine '$w'" >&2; exit 2; }
done

# Build the job list in table order; skips are results right away.
keys=() args=() n=0
for spec in "${GAMES[@]}"; do
  IFS='|' read -r name game file tool _ <<<"$spec"
  title=$(sed 's/./& /g; s/ $//' <<<"${game^^}")    # jqtris -> J Q T R I S
  launcher=$name/$game.sh file=$name/$file
  if (( ${#want[@]} )) && [[ " ${want[*]} " != *" $name "* ]]; then continue; fi
  file=$root/$file
  (( min )) && file=${file%.*}.min.${file##*.}
  label=$name; (( min )) && label=$name.min
  if [[ ! -f $file ]]; then
    printf 'skip  %-12s (no %s)\n' "$label" "${file#"$root"/}" > "$work/res.$n"; keys+=("$n"); (( n++ )); continue
  fi
  if ! have "$tool"; then
    if (( strict )); then printf 'FAIL  %-12s (%s is not installed)\n' "$label" "$tool"
    else printf 'skip  %-12s (%s is not installed)\n' "$label" "$tool"; fi > "$work/res.$n"
    keys+=("$n"); (( n++ )); continue
  fi
  for i in "${!STREAMS[@]}"; do
    keys+=("$n"); args+=("$n|$label|$title|$file|$i|$root/$launcher"); (( n++ ))
  done
done

# The scheduler keeps up to $jobs runs going; the main loop prints results in order.
(
  trap 'kill $(jobs -p) 2>/dev/null; exit 1' TERM
  for a in "${args[@]}"; do
    IFS="|" read -r key label title file i launcher <<<"$a"
    while (( $(jobs -rp | wc -l) >= jobs )); do wait -n; done
    run_one "$key" "$label" "$title" "$file" "$launcher" "$i" &
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
