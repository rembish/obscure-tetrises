#!/usr/bin/env bash
# maketris.sh - launcher for maketris, a falling-block puzzle game written in GNU make.
#
#   ./maketris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/make/maketris.sh | bash
#
#   ./maketris.sh --pipe    events on stdin, frames on stdout (used by tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *maketris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/make/maketris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=maketris DIR=make ENGINE=maketris.mk NEEDS=make
# make can only read input with $(file <name), which reads to end of file. So
# every event gets its own named pipe: pass N of make reads events.N, and the
# next pipe is created before the current one is written, so make always finds it.
# Once make exits, a drain loop answers any write still waiting on a pipe.
run_engine() {
  local k=0 line pid drain
  mkfifo "$work/events.0" || return 1
  echo 0 > "$work/current"
  make -s --no-print-directory -f "$1" FIFO="$work/events" STATE="$work/state.mk" & pid=$!
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
  if [[ -n $HERE && -f $HERE/../lib/launcher.sh ]]; then
    . "$HERE/../lib/launcher.sh"
  else
    lib=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/lib/launcher.sh
    lib=$(curl -fsSL "$lib" 2>/dev/null || wget -qO- "$lib") && [[ -n $lib ]] ||
      { echo "$GAME: can't download lib/launcher.sh" >&2; exit 1; }
    eval "$lib"
  fi
  tris_main "$@"
  exit $?
}
