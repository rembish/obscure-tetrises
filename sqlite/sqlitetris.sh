#!/usr/bin/env bash
# sqlitetris.sh - launcher for sqlitetris, a falling-block puzzle game written in SQL for sqlite3.
#
#   ./sqlitetris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sqlite/sqlitetris.sh | bash
#
#   ./sqlitetris.sh --pipe    events on stdin, frames on stdout (used by tests/check.sh)
#
# The launcher turns keys into event numbers and sends a tick every 100 ms.
# Gravity, randomness, scoring and drawing all happen in the engine (see ../SPEC.md).

# ---- per-game settings ------------------------------------------------------
GAME=sqlitetris
ENGINE=sqlitetris.sql
NEEDS=sqlite3
BASE_URL="${SQLITETRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sqlite}"
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

# One long-running sqlite3 shell with an in-memory database plays the game. It
# first reads the engine (dot-commands and SQL), then one fixed statement pair
# per input line: "INSERT INTO ev VALUES(N);SELECT*FROM frame;". The INSERT
# fires the trigger that plays event N, the SELECT prints the frame. Blank lines
# are skipped, since "VALUES()" would be a syntax error. -init /dev/null keeps a
# ~/.sqliterc out of it. When the game ends the engine stops the shell with a
# deliberate SQL error (it runs with .bail on); $2 is where that message goes.
run_engine() {
  local line
  {
    cat "$1"
    while IFS= read -r line; do
      [[ -n $line ]] && printf 'INSERT INTO ev VALUES(%s);SELECT*FROM frame;\n' "$line"
    done
  } | sqlite3 -batch -init /dev/null :memory: 2>"$2"
}

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

  if [[ ${1:-} == --pipe ]]; then
    trap '[[ -n $tmp ]] && rm -rf "$tmp"' EXIT
    run_engine "$engine" /dev/stderr
    return
  fi

  trap 'printf "\033[?25h\033[m\n" >/dev/tty; stty echo </dev/tty 2>/dev/null; [[ -n $tmp ]] && rm -rf "$tmp"' EXIT
  trap 'exit 130' INT TERM HUP
  printf '\033[2J\033[H\033[?25l' >/dev/tty

  input_loop </dev/tty | run_engine "$engine" /dev/null >/dev/tty
}

main "$@"
exit $?
