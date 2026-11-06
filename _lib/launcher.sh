# shellcheck shell=bash
# launcher.sh - the part every game launcher shares. Each <dir>/<game>.sh sets a
# few variables, defines run_engine, loads this file (from the clone, or from
# $TRIS_URL under curl | bash) and calls tris_main.
#
# The launcher turns keys into event numbers and sends a tick every 100 ms.
# Gravity, randomness, scoring and drawing all happen in the engine (see ../SPEC.md).
#
# What a launcher provides:
#   GAME, DIR, ENGINE, NEEDS   game name, its directory, engine file, tool to look for
#   HERE                       the launcher's directory, or empty under curl | bash
#   run_engine ENGINE          events on stdin (seed first), frames on stdout
#   check_tool                 optional: replaces the `command -v $NEEDS` check and
#                              prints its own message on failure
# What it can use while run_engine runs:
#   work                       a scratch directory, removed afterwards
#   pipe                       1 under --pipe (events from stdin, as _tests/check.sh
#                              runs it), 0 when playing on the terminal

TRIS_URL=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}
tmp=""    # download dir, if any; global so the EXIT trap can clean it up
work=""
pipe=0

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  else echo "$GAME: need curl or wget to download $1" >&2; return 1
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

tris_main() {
  local engine

  if (( BASH_VERSINFO[0] < 4 )); then
    echo "$GAME: needs bash 4 or newer (this is $BASH_VERSION)" >&2; return 1
  fi
  if declare -F check_tool >/dev/null; then
    check_tool || return 1
  else
    command -v "$NEEDS" >/dev/null 2>&1 || { echo "$GAME: '$NEEDS' is not installed" >&2; return 1; }
  fi
  [[ ${1:-} == --pipe ]] && pipe=1
  (( pipe )) || [[ -r /dev/tty ]] || { echo "$GAME: needs an interactive terminal" >&2; return 1; }

  # Use the engine next to the launcher, or download it (e.g. under curl | bash).
  engine=${ENGINE_FILE:-$HERE/$ENGINE}               # ENGINE_FILE: e.g. the .min version
  if [[ -z $HERE || ! -f $engine ]]; then
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/$GAME.XXXXXX") || return 1
    engine="$tmp/$ENGINE"
    fetch "$TRIS_URL/$DIR/$ENGINE" "$engine" || return 1
  fi
  work=$(mktemp -d "${TMPDIR:-/tmp}/$GAME-run.XXXXXX") || return 1

  if (( pipe )); then
    trap '[[ -n $tmp ]] && rm -rf "$tmp"; rm -rf "$work"' EXIT
    run_engine "$engine"
    return
  fi

  trap 'printf "\033[?25h\033[m\n" >/dev/tty; stty echo </dev/tty 2>/dev/null; [[ -n $tmp ]] && rm -rf "$tmp"; rm -rf "$work"' EXIT
  trap 'exit 130' INT TERM HUP
  printf '\033[2J\033[H\033[?25l' >/dev/tty

  input_loop </dev/tty | run_engine "$engine" >/dev/tty
}
