#!/usr/bin/env bash
# gnuplottris.sh - launcher for gnuplottris, a falling-block puzzle game written in gnuplot.
#
#   ./gnuplottris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/gnuplot/gnuplottris.sh | bash
#
#   ./gnuplottris.sh --pipe    events on stdin, frames on stdout (used by tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *gnuplottris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/gnuplot/gnuplottris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=gnuplottris DIR=gnuplot ENGINE=gnuplottris.gp NEEDS=gnuplot

# gnuplot reads commands from stdin after loading the game, so each event N is
# sent as the statement "if ($step(N)) { exit }". GNUTERM=dumb keeps gnuplot
# away from the display; the game only prints text.
run_engine() {
  local line
  while IFS= read -r line; do printf 'if ($step(%s)) { exit }\n' "$line"; done |
    GNUTERM=dumb gnuplot "$1" -
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
