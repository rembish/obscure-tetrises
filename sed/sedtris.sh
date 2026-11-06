#!/usr/bin/env bash
# sedtris.sh - launcher for sedtris, a falling-block puzzle game written in GNU sed.
#
#   ./sedtris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sed/sedtris.sh | bash
#
#   ./sedtris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *sedtris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/sed/sedtris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=sedtris DIR=sed ENGINE=sedtris.sed NEEDS=sed

# The engine reads one event number per line on stdin and prints a frame
# after each one. It needs GNU sed (it uses GNU extensions such as \xHH and
# \n in replacements). -u makes sed read its input line by line and flush
# every frame at once; without it, frames would sit in a pipe buffer.
# LC_ALL=C makes "." match bytes, not UTF-8 characters, which is also faster.
run_engine() {
  LC_ALL=C sed -n -E -u -f "$1"
}

check_tool() {
  command -v sed >/dev/null 2>&1 || { echo "$GAME: 'sed' is not installed" >&2; return 1; }
  case $(sed --version 2>/dev/null) in
    *"(GNU sed)"*) ;;
    *) echo "$GAME: needs GNU sed (on macOS: brew install gnu-sed, then put gsed first as sed)" >&2; return 1 ;;
  esac
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
