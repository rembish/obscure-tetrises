#!/usr/bin/env bash
# preprocessortris.sh - launcher for preprocessortris, a falling-block puzzle game written in the C preprocessor.
#
#   ./preprocessortris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/preprocessor/preprocessortris.sh | bash
#
#   ./preprocessortris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *preprocessortris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/preprocessor/preprocessortris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=preprocessortris DIR=preprocessor ENGINE=preprocessortris.h NEEDS=cpp
# The preprocessor can't read a stream, loop or keep state, so it runs once
# per event with the state so far in state.h (see preprocessortris.h). Its
# output lines starting with @ are the next state, "@NAME value" several to a
# line, written back as "#define NAME() value"; the other non-empty lines are
# the frame. A lock takes three runs: while the new state's PHASE() isn't 0,
# the engine runs again without a new event. No state at all means game over.
# -traditional-cpp keeps the frame's spaces exactly; it is GCC's preprocessor.
# -w: the golfed engine redefines macros without #undef, which only warns.
pp_run() {    # pp_run [-DEV=n]: one run; 0 if it left a next state
  local line part name have=0
  cpp -P -traditional-cpp -w -include "$work/state.h" -DPARTS="\"$work/parts.h\"" "$@" "$engine" \
    > "$work/out" || return 1
  : > "$work/next.h"
  while IFS= read -r line; do
    if [[ $line == @* ]]; then
      IFS='@' read -ra part <<<"${line#@}"
      for part in "${part[@]}"; do
        name=${part%% *}
        printf '#define %s() %s\n' "$name" "${part#* }" >> "$work/next.h"
        [[ $name == PHASE ]] && phase=${part#* }
      done
      have=1
    elif [[ -n $line ]]; then
      printf '%s\n' "$line"
    fi
  done < "$work/out"
  (( have )) || return 1
  mv "$work/next.h" "$work/state.h"
}

check_tool() {
  command -v cpp >/dev/null 2>&1 || { echo "$GAME: 'cpp' is not installed" >&2; return 1; }
  case $(cpp --version 2>/dev/null) in
    *"Free Software Foundation"*) ;;
    *) echo "$GAME: needs GCC's cpp (macOS's cpp is clang: brew install gcc, then put cpp-NN first as cpp)" >&2; return 1 ;;
  esac
}

run_engine() {
  local engine=$1 seed line phase=0
  # The engine includes its "parts" block twenty times a frame; a copy of just
  # that block saves the preprocessor from wading through the rest each time.
  sed -n '/^\/\*{/,/^\/\*}/p' "$engine" > "$work/parts.h"
  IFS= read -r seed || return 0
  seed=${seed//[!0-9]/}
  printf '#define START() %s\n' "${seed:-1}" > "$work/state.h"
  pp_run || return 0
  while [[ $phase != 0 ]]; do pp_run || return 0; done
  while IFS= read -r line; do
    line=${line//[!0-9]/}
    [[ -z $line ]] && continue
    [[ $line == 9 ]] && return 0
    pp_run -DEV="$line" || return 0
    while [[ $phase != 0 ]]; do pp_run || return 0; done
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
