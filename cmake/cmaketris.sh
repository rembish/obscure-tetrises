#!/usr/bin/env bash
# cmaketris.sh - launcher for cmaketris, a falling-block puzzle game written in CMake script.
#
#   ./cmaketris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cmake/cmaketris.sh | bash
#
#   ./cmaketris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *cmaketris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/cmake/cmaketris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=cmaketris DIR=cmake ENGINE=cmaketris.cmake NEEDS=cmake
# CMake reads each event with file(DOWNLOAD "file://..."), to end of file. So
# every event gets its own named pipe: read N reads events.N, and the next pipe
# is created before the current one is written, so CMake always finds it.
# Once CMake exits, a drain loop answers any write still waiting on a pipe.
run_engine() {
  local k=0 line pid drain
  mkfifo "$work/events.0" || return 1
  echo 0 > "$work/current"
  cmake -DFIFO="$work/events" -DSCRATCH="$work/event.txt" -P "$1" & pid=$!
  ( while kill -0 "$pid" 2>/dev/null; do sleep 0.05; done
    while :; do { read -r -t 0.2 _; } <> "$work/events.$(<"$work/current")"; done 2>/dev/null ) & drain=$!
  feed() {
    mkfifo "$work/events.$((k + 1))"
    printf '%s' "$1" > "$work/events.$k"
    rm -f "$work/events.$k"
    k=$((k + 1)); echo "$k" > "$work/current"
  }
  while IFS= read -r line; do
    kill -0 "$pid" 2>/dev/null || break
    feed "$line"$'\n'
  done
  kill -0 "$pid" 2>/dev/null && feed ""          # empty write = end of input
  wait "$pid"
  kill "$drain" 2>/dev/null
}

# Load the shared part from the clone, or download it; then play. (In braces, so
# that bash has read all of it before it runs, even under curl | bash.)
{
  HERE=""
  [[ -f ${BASH_SOURCE[0]:-} ]] && HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  if [[ -n $HERE && -f $HERE/../_lib/launcher.sh ]]; then
    # shellcheck source=SCRIPTDIR/../_lib/launcher.sh
    . "$HERE/../_lib/launcher.sh"
  else
    lib=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/_lib/launcher.sh
    if ! lib=$(curl -fsSL "$lib" 2>/dev/null || wget -qO- "$lib") || [[ -z $lib ]]; then
      echo "$GAME: can't download _lib/launcher.sh" >&2; exit 1
    fi
    eval "$lib"
  fi
  tris_main "$@"
  exit $?
}
