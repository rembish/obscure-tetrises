#!/usr/bin/env bash
# m4tris.sh - launcher for m4tris, a falling-block puzzle game written in m4.
#
#   ./m4tris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/m4/m4tris.sh | bash
#
#   ./m4tris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *m4tris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/m4/m4tris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=m4tris DIR=m4 ENGINE=m4tris.m4 NEEDS=m4
# m4 only reacts to macro calls, so each event line N is passed on as E(N).
run_engine() {
  local line
  while IFS= read -r line; do printf 'E(%s)\n' "$line"; done | m4 "$1" -
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
