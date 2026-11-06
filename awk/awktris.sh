#!/usr/bin/env bash
# awktris.sh - launcher for awktris, a falling-block puzzle game written in awk.
#
#   ./awktris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/awk/awktris.sh | bash
#
#   ./awktris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *awktris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/awk/awktris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=awktris DIR=awk ENGINE=awktris.awk NEEDS=awk

# The engine reads one event number per line on stdin and prints a frame
# after each one, calling fflush() so frames are not held back by a pipe.
# mawk also reads a pipe in big blocks, so it would sit on the first keys
# until 4 KB of them arrived; `-W interactive` makes it read line by line.
run_engine() {
  local opt=()
  case $(awk -W version 2>&1 </dev/null) in mawk*) opt=(-W interactive) ;; esac
  awk "${opt[@]}" -f "$1"
}

# Load the shared part from the clone, or download it; then play. (In braces, so
# that bash has read all of it before it runs, even under curl | bash.)
{
  HERE=""
  [[ -f ${BASH_SOURCE[0]:-} ]] && HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  if [[ -n $HERE && -f $HERE/../_lib/launcher.sh ]]; then
    . "$HERE/../_lib/launcher.sh"
  else
    lib=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/_lib/launcher.sh
    lib=$(curl -fsSL "$lib" 2>/dev/null || wget -qO- "$lib") && [[ -n $lib ]] ||
      { echo "$GAME: can't download _lib/launcher.sh" >&2; exit 1; }
    eval "$lib"
  fi
  tris_main "$@"
  exit $?
}
