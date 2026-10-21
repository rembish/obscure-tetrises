#!/usr/bin/env bash
# sedtris.sh - launcher for Sedtris, a Tetris game written in sed.
#
# Run it locally:      ./sedtris.sh
# Or straight from the web:
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sed/sedtris.sh | bash
#
# The launcher reads the keyboard, sends a tick to sed once a second
# (that is gravity), and adds a little hidden random input so the pieces
# come out less predictable. All the game logic lives in sedtris.sed.
#
# Based on playsed.sh by Aurelio Marinho Jargas
# http://sed.sf.net/grabbag/scripts/playsed.sh.txt

SEDTRIS_URL="${SEDTRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sed}"

# --- POSIX part: when started by plain sh (e.g. `curl ... | sh`), hand over to bash.
if [ -z "${BASH_VERSION:-}" ]; then
  if ! command -v bash >/dev/null 2>&1; then
    echo "sedtris: bash is required" >&2
    exit 1
  fi
  case "$0" in
    *sedtris*) [ -f "$0" ] && exec bash "$0" "$@" ;;
  esac
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SEDTRIS_URL/sedtris.sh" | bash -s -- "$@"
  else
    wget -qO- "$SEDTRIS_URL/sedtris.sh" | bash -s -- "$@"
  fi
  exit $?
fi

# --- bash from here on. Everything is wrapped in main() so the whole script
# is parsed before anything runs, which keeps `curl | bash` safe.

fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$2" "$1"
  else
    echo "sedtris: need curl or wget to download sedtris.sed" >&2
    return 1
  fi
}

# Turn keypresses into lines for sed, plus one tick per second.
input_loop() {
  local IFS= key rest last=$SECONDS
  while :; do
    if read -rsn1 -t 1 key; then
      if [[ $key == $'\e' ]]; then          # arrow keys: ESC [ A..D
        read -rsn1 -t 1 rest; key+=$rest
        if [[ $rest == '[' ]]; then
          read -rsn1 -t 1 rest; key+=$rest
        fi
      fi
      printf '%s\n' "$key"
    fi
    if (( SECONDS != last )); then
      last=$SECONDS
      # A "1" now and then nudges the piece generator.
      if (( (RANDOM / 10) % 7 == 1 )); then echo 1; else echo; fi
    fi
  done
}

tmp=""   # download dir, if any; global so the EXIT trap can clean it up

main() {
  local dir="" script sed_bin=sed

  if [[ ! -r /dev/tty ]]; then
    echo "sedtris: needs an interactive terminal" >&2
    return 1
  fi

  # Use sedtris.sed next to this script, or download it (e.g. under curl | bash).
  if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
    dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  fi
  script="$dir/sedtris.sed"
  if [[ -z $dir || ! -f $script ]]; then
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/sedtris.XXXXXX") || return 1
    script="$tmp/sedtris.sed"
    fetch "$SEDTRIS_URL/sedtris.sed" "$script" || { rm -rf "$tmp"; return 1; }
  fi

  # GNU sed is what the game is tested with; prefer it on BSD/macOS.
  command -v gsed >/dev/null 2>&1 && sed_bin=gsed

  # Clear the screen and hide the cursor; put the terminal back on exit.
  trap 'printf "\033[?25h\033[m\n" >/dev/tty; stty echo </dev/tty 2>/dev/null; [[ -n $tmp ]] && rm -rf "$tmp"' EXIT
  trap 'exit 130' INT TERM HUP
  printf '\033[2J\033[H\033[?25l' >/dev/tty

  input_loop </dev/tty | LC_ALL=C "$sed_bin" -n -f "$script" >/dev/tty
}

main "$@"
exit $?
