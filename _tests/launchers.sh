#!/usr/bin/env bash
# launchers.sh - test how every launcher starts, which check.sh doesn't cover.
#
#   _tests/launchers.sh            all games
#   _tests/launchers.sh jq sed     just these
#   _tests/launchers.sh --strict   fail, instead of skipping, when a tool is missing (CI)
#
# check.sh runs each engine as `<dir>/<game>.sh --pipe` from the clone. This
# checks the other ways in, each on a short event stream compared with the reference:
#   sh        `sh <game>.sh --pipe`: the hand-over from plain sh to bash
#   download  the launcher run as a string with no files next to it, as under
#             `curl | bash`; TRIS_URL points at this clone with file://, so it
#             downloads _lib/launcher.sh and its engine from here
#   terminal  a real session under `script`: the game starts on a pseudo-terminal,
#             draws, and quits on `q` (exit status 0, at least one frame)
# After every run the temporary directory must be empty again.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
work=$(mktemp -d "${TMPDIR:-/tmp}/tris-launchers.XXXXXX")
trap 'rm -rf "$work"' EXIT

strict=0
[[ ${1:-} == --strict ]] && { strict=1; shift; }
want=("$@")
eval "$(sed -n '/^GAMES=(/,/^)/p' "$root/play.sh")"

have() {
  [[ $1 == sendmail ]] && { [[ -x /usr/sbin/sendmail || -x /usr/lib/sendmail ]] && return 0; }
  command -v "$1" >/dev/null 2>&1
}

printf '42\n5\n3\n1\n2\n4\n0\n5\n9\n' > "$work/ev"
fail=0
result() {   # result LABEL OK DETAIL
  if (( $2 )); then printf 'ok    %-20s %s\n' "$1" "$3"; else printf 'FAIL  %-20s %s\n' "$1" "$3"; fail=1; fi
}
clean() {    # the run left nothing behind in its TMPDIR
  local left; left=$(ls -A "$work/tmp")
  [[ -z $left ]] || { echo "      left behind in TMPDIR: $left"; rm -rf "${work:?}/tmp/"*; return 1; }
}

for spec in "${GAMES[@]}"; do
  IFS='|' read -r dir game _ tool _ <<<"$spec"
  if (( ${#want[@]} )) && [[ " ${want[*]} " != *" $dir "* ]]; then continue; fi
  if ! have "$tool"; then
    if (( strict )); then result "$dir" 0 "($tool is not installed)"; else printf 'skip  %-20s (%s is not installed)\n' "$dir" "$tool"; fi
    continue
  fi
  launcher=$root/$dir/$game.sh
  title=$(sed 's/./& /g; s/ $//' <<<"${game^^}")
  python3 "$here/reference.py" "$title" < "$work/ev" > "$work/ref"
  mkdir -p "$work/tmp" "$work/empty"
  export TMPDIR=$work/tmp

  sh "$launcher" --pipe < "$work/ev" > "$work/out" 2>/dev/null
  cmp -s "$work/ref" "$work/out" && clean; result "$dir sh" $(( ! $? )) "sh hand-over"

  (cd "$work/empty" && TRIS_URL=file://$root bash -c "$(cat "$launcher")" "$game.sh" --pipe) \
    < "$work/ev" > "$work/out" 2>/dev/null
  cmp -s "$work/ref" "$work/out" && clean; result "$dir download" $(( ! $? )) "_lib and engine from TRIS_URL"

  (sleep 3; printf q) | timeout 60 script -qec "SEED=42 $launcher" /dev/null > "$work/tty" 2>&1
  rc=$? frames=$(grep -c $'\e\[H' "$work/tty")
  (( rc == 0 && frames > 0 )) && clean; result "$dir terminal" $(( ! $? )) "exit $rc, $frames frame lines"
  unset TMPDIR
done
exit $fail
