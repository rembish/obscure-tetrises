#!/usr/bin/env bash
# ghcitris.sh - launcher for ghcitris, a falling-block puzzle game written in Haskell type families.
#
#   ./ghcitris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/ghci/ghcitris.sh | bash
#
#   ./ghcitris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *ghcitris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/ghci/ghcitris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=ghcitris DIR=ghci ENGINE=ghcitris.hs NEEDS=ghci

# The engine is type families: the game state is a type, and GHC's type
# checker computes the next one. One ghci reads commands from this launcher.
# Per event: ":kind! Step S <n>" prints the next state in normal form, which
# the launcher names again with "type S = ...", and then ghci prints the
# Symbol "Frame S" (empty for a tick that moved nothing), followed by a line
# with \001 so that the launcher knows the frame is complete. A state that
# ends in Ended is the game-over frame.
run_engine() {
  local engine=$1 seed line next
  # -v0: no banner or prompts. -freduction-depth=0: no limit on how deep type
  # families may recurse. -dppr-cols: print each state on one line.
  coproc GHCI { exec ghci -v0 -ignore-dot-ghci -freduction-depth=0 -dppr-cols=1000000 \
                  -XDataKinds -XTypeApplications "$engine" 2>&1; }
  printf '%s\n' ':m + GHC.TypeLits Data.Proxy System.IO' 'hSetEncoding stdout utf8' >&"${GHCI[1]}"

  # step TYPE: reduce TYPE to the next state, print its frame. 1 at game over.
  step() {
    printf ':kind! %s\n' "$1" >&"${GHCI[1]}"
    IFS= read -r line <&"${GHCI[0]}" || return 1       # "Step S 3 :: Game"
    IFS= read -r next <&"${GHCI[0]}" || return 1       # "= 'Game ..."
    if [[ $line != *':: Game' || $next != '= '* ]]; then
      printf '%s: ghci said: %s\n%s\n' "$GAME" "$line" "$next" >&2; return 1
    fi
    printf 'type S = %s\nputStr (symbolVal (Proxy @(Frame S))) >> putStrLn "\\SOH"\n' "${next#= }" >&"${GHCI[1]}"
    while IFS= read -r line <&"${GHCI[0]}"; do
      [[ $line == $'\001' ]] && break
      printf '%s\n' "$line"
    done
    [[ $next != *Ended ]]                             # 9.4 prints 'Ended, 9.10 Ended
  }

  if IFS= read -r seed; then
    seed=${seed//[!0-9]/}
    if step "Start ${seed:-1}"; then
      while IFS= read -r line; do
        line=${line//[!0-9]/}
        [[ -z $line ]] && continue
        [[ $line == 9 ]] && break
        step "Step S $line" || break
      done
    fi
  fi
  printf ':quit\n' >&"${GHCI[1]}"
  wait "$GHCI_PID" 2>/dev/null
  return 0
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
