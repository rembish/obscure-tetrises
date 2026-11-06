#!/usr/bin/env bash
# vimtris.sh - launcher for vimtris, a falling-block puzzle game written in Vim script.
#
#   ./vimtris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/vim/vimtris.sh | bash
#
#   ./vimtris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *vimtris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/vim/vimtris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=vimtris DIR=vim ENGINE=vimtris.vim NEEDS=vim

# Vim is only the interpreter: -es is silent Ex mode (no screen, no terminal
# codes), -Nu NONE -i NONE skips every vimrc, plugin and the viminfo file.
# The script reads the events from stdin itself with input('') and writes the
# frames to /dev/stdout, so the event lines go in unchanged.
# Ctrl-C is a trap: a SIGINT sends Vim's Ex mode into a busy loop that then
# ignores even SIGTERM. So Vim runs in the background (stdin passed on
# explicitly) and a SIGINT here kills it outright.
run_engine() {
  local pid
  vim -Nu NONE -i NONE -es -S "$1" <&0 & pid=$!
  trap 'kill -9 "$pid" 2>/dev/null' INT
  wait "$pid"
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
