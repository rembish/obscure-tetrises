#!/usr/bin/env bash
# trofftris.sh - launcher for trofftris, a falling-block puzzle game written in troff.
#
#   ./trofftris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/troff/trofftris.sh | bash
#
#   ./trofftris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *trofftris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/troff/trofftris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=trofftris DIR=troff ENGINE=trofftris.tr NEEDS=troff

# troff reads input with .rd, which stops at a blank line, so each event N
# goes in as the request ".GO N" followed by an empty line. troff can only print
# printable ASCII, so it writes its frames to stderr with C-style escapes
# (\033[1m, \u2588), and printf '%b' turns those into bytes, one line at a time.
run_engine() {
  local line
  while IFS= read -r line; do printf '.GO %s\n\n' "$line"; done |
    troff -z -Ww "$1" 2>&1 >/dev/null | {
      export LC_ALL=C.UTF-8
      while IFS= read -r line; do printf '%b\n' "$line"; done
    }
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
