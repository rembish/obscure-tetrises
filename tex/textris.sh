#!/usr/bin/env bash
# textris.sh - launcher for textris, a falling-block puzzle game written in plain TeX.
#
#   ./textris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/tex/textris.sh | bash
#
#   ./textris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *textris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/tex/textris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=textris DIR=tex ENGINE=textris.tex NEEDS=tex

# TeX writes its log into a temporary directory. It always prints a banner line
# first, and switching back to \batchmode at the end prints one empty line; sed
# drops both (frame lines are never empty). -8bit lets ESC and UTF-8 through,
# and max_print_line stops TeX from breaking long lines.
run_engine() {
  local out
  out=$(mktemp -d "${TMPDIR:-/tmp}/$GAME-run.XXXXXX") || return 1
  max_print_line=100000 tex -8bit -interaction=batchmode -output-directory="$out" "$1" |
    sed '1d;/^$/d'
  rm -rf "$out"
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
