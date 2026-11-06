#!/usr/bin/env bash
# postscripttris.sh - launcher for postscripttris, a falling-block puzzle game written in PostScript.
#
#   ./postscripttris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/postscript/postscripttris.sh | bash
#
#   ./postscripttris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *postscripttris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/postscript/postscripttris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=postscripttris DIR=postscript ENGINE=postscripttris.ps NEEDS=gs

# Ghostscript runs the game with no output device (-dNODISPLAY). The game reads
# its events from %stdin itself and prints the frames to stdout, so events and
# frames just pass through. The default -dSAFER is kept: reading %stdin and
# writing %stdout are allowed under it.
run_engine() {
  gs -q -dNODISPLAY -dBATCH -dNOPAUSE "$1"
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
    lib=$(curl -fsSL "$lib" 2>/dev/null || wget -qO- "$lib") && [[ -n $lib ]] ||
      { echo "$GAME: can't download _lib/launcher.sh" >&2; exit 1; }
    eval "$lib"
  fi
  tris_main "$@"
  exit $?
}
