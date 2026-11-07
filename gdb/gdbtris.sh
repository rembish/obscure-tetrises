#!/usr/bin/env bash
# gdbtris.sh - launcher for gdbtris, a falling-block puzzle game written in gdb's command language.
#
#   ./gdbtris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/gdb/gdbtris.sh | bash
#
#   ./gdbtris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *gdbtris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/gdb/gdbtris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=gdbtris DIR=gdb ENGINE=gdbtris.gdb NEEDS=gdb

# gdb runs with no program, only the engine's commands (-x), and reads more
# commands on stdin: each input line becomes one, "seed 42" for the first and
# "event 3" for the rest, the way m4tris gets E(3). 9 (quit) stops here; at
# game over the engine quits gdb itself.
run_engine() {
  local line first=1
  while IFS= read -r line; do
    line=${line//[!0-9]/}
    [[ -z $line ]] && continue
    if (( first )); then
      first=0; echo "seed $line"
    else
      [[ $line == 9 ]] && break
      echo "event $line"
    fi
  done | gdb -q -nx -x "$1"
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
