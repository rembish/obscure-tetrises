#!/usr/bin/env bash
# cpptris.sh - launcher for cpptris, a falling-block puzzle game played by the C++ compiler (g++ templates).
#
#   ./cpptris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cpp/cpptris.sh | bash
#
#   ./cpptris.sh --pipe    events on stdin, frames on stdout (used by tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *cpptris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/cpp/cpptris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=cpptris DIR=cpp ENGINE=cpptris.cpp NEEDS=g++
# The compiler plays the game, and a compiler can't read a live stream. So the
# engine is compiled once per batch of events: state.hpp holds the state so far
# (as a type), events.hpp the new events (as a pack). The program g++ builds
# prints the batch's frames, writes the next state.hpp to fd 3, and exits with
# status 1 when the game is over. A reader appends stdin to a queue file while
# a compile runs, and the next compile takes everything that has arrived since
# (up to CHUNK events). Interactive play therefore moves in jumps, but every
# event is processed and the frames are the same.
CHUNK=${CPPTRIS_CHUNK:-500}
CXXFLAGS="-std=c++17 -O0 -w -fmax-errors=3 -ftemplate-depth=4096"
run_engine() {
  local seed line ev quit=0 done=0 total eof first=1 rc reader
  IFS= read -r seed || return 0
  seed=$(printf '%s' "$seed" | tr -cd 0-9)
  echo "using S0 = Init<${seed:-1}>;" > "$work/state.hpp"
  : > "$work/queue"
  { while IFS= read -r line || [ -n "$line" ]; do printf '%s\n' "$line"; done >> "$work/queue"
    : > "$work/eof"; } <&0 & reader=$!
  while [ "$quit" = 0 ]; do
    [ -e "$work/eof" ] && eof=1 || eof=0              # check before counting
    total=$(wc -l < "$work/queue")
    if [ "$total" -eq "$done" ] && [ "$first" = 0 ]; then
      [ "$eof" = 1 ] && break
      sleep 0.02; continue
    fi
    [ "$total" -gt $((done + CHUNK)) ] && total=$((done + CHUNK))
    : > "$work/batch"
    [ "$total" -gt "$done" ] && sed -n "$((done + 1)),${total}p" "$work/queue" | tr -d ' \t\r' > "$work/batch"
    done=$total
    ev=""
    while IFS= read -r line; do
      case $line in ''|*[!0-9]*) continue ;; esac     # blank or not a code: ignored
      [ ${#line} -gt 18 ] && continue
      line=$((10#$line))
      [ "$line" = 9 ] && { quit=1; break; }           # quit: stop here
      ev="$ev,$line"
    done < "$work/batch"
    [ -z "$ev" ] && [ "$first" = 0 ] && continue      # nothing to play
    # the first batch also draws the starting state
    echo "using Game = Batch<S0, $first$ev>;" > "$work/events.hpp"
    first=0
    g++ $CXXFLAGS -I"$work" -x c++ "$1" -o "$work/game" || break
    "$work/game" 3> "$work/next.hpp"; rc=$?
    mv "$work/next.hpp" "$work/state.hpp"
    [ "$rc" = 0 ] || break                            # game over
  done
  kill "$reader" 2>/dev/null
  return 0
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
