#!/usr/bin/env bash
# jsonnettris.sh - launcher for jsonnettris, a falling-block puzzle game written in Jsonnet.
#
#   ./jsonnettris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/jsonnet/jsonnettris.sh | bash
#
#   ./jsonnettris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *jsonnettris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/jsonnet/jsonnettris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=jsonnettris DIR=jsonnet ENGINE=jsonnettris.jsonnet NEEDS=jsonnet

# Jsonnet has no input or output and keeps nothing between runs, so it runs
# once per input line: the line goes in as the ext-str "input", the state of
# the run before as the ext-code "state" (null at first). -S -m writes the
# result's two strings to their own files: "frame", printed as it is, and
# "state.json", the next state, empty at game over. 9 (quit) stops here.
run_engine() {
  local engine=$1 line frame state=null
  while IFS= read -r line; do
    line=${line//[!0-9]/}
    [[ -z $line ]] && continue
    [[ $state != null && $line == 9 ]] && break
    jsonnet -S -m "$work" --ext-str input="$line" --ext-code state="$state" "$engine" >/dev/null || return 1
    # -m ends each file with a newline of its own; $(<) drops it again.
    frame=$(<"$work/frame")
    [[ -n $frame ]] && printf '%s\n' "$frame"
    state=$(<"$work/state.json")
    [[ -z $state ]] && break
  done
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
