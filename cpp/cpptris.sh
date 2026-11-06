#!/usr/bin/env bash
# cpptris.sh - launcher for cpptris, a falling-block puzzle game played by the C++ compiler (g++ templates).
#
#   ./cpptris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cpp/cpptris.sh | bash
#
#   ./cpptris.sh --pipe    events on stdin, frames on stdout (used by tests/check.sh)
#
# The launcher turns keys into event numbers and sends a tick every 100 ms.
# Gravity, randomness, scoring and drawing all happen in the engine (see ../SPEC.md).

# ---- per-game settings ------------------------------------------------------
GAME=cpptris
ENGINE=cpptris.cpp
NEEDS=g++
BASE_URL="${CPPTRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cpp}"
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
# (This function is parsed by plain sh before the bash handoff below, so it
# sticks to POSIX syntax.)
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
# -----------------------------------------------------------------------------

# POSIX part: under plain sh (e.g. `curl ... | sh`), hand over to bash.
if [ -z "${BASH_VERSION:-}" ]; then
  command -v bash >/dev/null 2>&1 || { echo "$GAME: bash is required" >&2; exit 1; }
  case "$0" in *"$GAME"*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$BASE_URL/$GAME.sh" | bash -s -- "$@"
  else
    wget -qO- "$BASE_URL/$GAME.sh" | bash -s -- "$@"
  fi
  exit $?
fi

# bash from here on; everything runs from main() so `curl | bash` parses it all first.

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  else echo "$GAME: need curl or wget to download $ENGINE" >&2; return 1
  fi
}

# Keys -> event numbers (0 tick, 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop, 9 quit).
input_loop() {
  local IFS= key rest now t0="" code
  echo "${SEED:-$(( (RANDOM << 15 | RANDOM) % 2147483646 + 1 ))}"
  [[ -n ${EPOCHREALTIME:-} ]] && t0=${EPOCHREALTIME//[.,]/}
  while :; do
    code=""
    if read -rsn1 -t 0.1 key; then
      if [[ $key == $'\e' ]]; then
        read -rsn1 -t 0.01 rest; key+=$rest
        [[ $rest == '[' || $rest == O ]] && { read -rsn1 -t 0.01 rest; key+=$rest; }
      fi
      case $key in
        a|A|$'\e[D'|$'\eOD') code=1 ;;
        d|D|$'\e[C'|$'\eOC') code=2 ;;
        w|W|$'\e[A'|$'\eOA') code=3 ;;
        s|S|$'\e[B'|$'\eOB'|'') code=4 ;;
        z|Z|' ') code=5 ;;
        q|Q) echo 9; return 0 ;;
      esac
      [[ -n $code ]] && echo "$code"
    elif [[ -z $t0 ]]; then
      echo 0                                  # bash 4: tick on every timeout
    fi
    if [[ -n $t0 ]]; then                     # bash 5: steady 100 ms ticks
      now=${EPOCHREALTIME//[.,]/}
      (( now - t0 > 1000000 )) && t0=$now     # don't replay a long pause
      while (( now - t0 >= 100000 )); do echo 0; (( t0 += 100000 )); done
    fi
  done
}

tmp=""   # download dir, if any; global so the EXIT trap can clean it up
work=""  # state, events and the compiled batch

main() {
  local dir="" engine

  if (( BASH_VERSINFO[0] < 4 )); then
    echo "$GAME: needs bash 4 or newer (this is $BASH_VERSION)" >&2; return 1
  fi
  command -v "$NEEDS" >/dev/null 2>&1 || { echo "$GAME: '$NEEDS' is not installed" >&2; return 1; }
  [[ ${1:-} == --pipe || -r /dev/tty ]] || { echo "$GAME: needs an interactive terminal" >&2; return 1; }

  # Use the engine next to this script, or download it (e.g. under curl | bash).
  if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
    dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  fi
  engine="$dir/$ENGINE"
  [[ -n ${ENGINE_FILE:-} ]] && engine=$ENGINE_FILE   # e.g. the .min version
  if [[ -z $dir || ! -f $engine ]]; then
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/$GAME.XXXXXX") || return 1
    engine="$tmp/$ENGINE"
    fetch "$BASE_URL/$ENGINE" "$engine" || return 1
  fi

  work=$(mktemp -d "${TMPDIR:-/tmp}/$GAME-run.XXXXXX") || return 1
  if [[ ${1:-} == --pipe ]]; then
    trap '[[ -n $tmp ]] && rm -rf "$tmp"; rm -rf "$work"' EXIT
    run_engine "$engine"
    return
  fi

  trap 'printf "\033[?25h\033[m\n" >/dev/tty; stty echo </dev/tty 2>/dev/null; [[ -n $tmp ]] && rm -rf "$tmp"; rm -rf "$work"' EXIT
  trap 'exit 130' INT TERM HUP
  printf '\033[2J\033[H\033[?25l' >/dev/tty

  input_loop </dev/tty | run_engine "$engine" >/dev/tty
}

main "$@"
exit $?
