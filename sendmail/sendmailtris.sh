#!/usr/bin/env bash
# sendmailtris.sh - launcher for sendmailtris, a falling-block puzzle game written in sendmail.cf.
#
#   ./sendmailtris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sendmail/sendmailtris.sh | bash
#
#   ./sendmailtris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *sendmailtris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/sendmail/sendmailtris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=sendmailtris DIR=sendmail ENGINE=sendmailtris.cf NEEDS=sendmail

# sendmail usually lives in /usr/sbin, which often isn't on a user's PATH.
find_sendmail() {
  local p
  for p in "$(command -v sendmail 2>/dev/null)" /usr/sbin/sendmail /usr/lib/sendmail; do
    [[ -n $p && -x $p ]] && { echo "$p"; return 0; }
  done
  return 1
}

# sendmail can't print ESC or UTF-8, so the engine returns each frame as glyph
# tokens on a "Game returns:" line, and this fixed table turns every token
# into its bytes. Tokens not in the table, such as the score digits, pass
# through unchanged. The table holds no logic: what to draw and where comes
# from sendmail.cf.
decode() {
  local E=$'\e' line out tok
  local B="$E[38;5;60m" D="$E[38;5;244m" R="$E[m" W="$E[1m"
  local -a toks
  local -A G=(
    [hh]="$E[H" [nl]="$E[K"$'\n' [cj]="$E[J"
    [tt]="  $E[1;38;5;75mS E N D M A I L T R I S$R"
    [tp]=" ${B}╔════════════════════╗$R" [bt]=" ${B}╚════════════════════╝$R"
    [lb]=" ${B}║$R" [rb]="${B}║$R" [e]="$E[38;5;237m ·$R"
    [i]="$E[38;5;51m██$R" [o]="$E[38;5;226m██$R" [t]="$E[38;5;135m██$R" [s]="$E[38;5;46m██$R"
    [z]="$E[38;5;196m██$R" [j]="$E[38;5;33m██$R" [l]="$E[38;5;208m██$R" [ns]="  "
    [go]="$E[1;7m     GAME  OVER     $R"
    [pn]="   ${B}╭──$R ${D}next$R ${B}──────╮$R" [pb]="   ${B}│$R              ${B}│$R"
    [na]="   ${B}│$R   " [nz]="   ${B}│$R" [pz]="   ${B}╰──────────────╯$R"
    [ps]="   ${D}score$R" [sc]="   $W" [re]="$R"
    [lv]="   ${D}level$R $W" [lm]="$R  ${D}lines$R $W" [pc]="   ${D}controls$R"
    [k1]="   ${W}← a$R  ${D}move left$R" [k2]="   ${W}→ d$R  ${D}move right$R"
    [k3]="   ${W}↑ w$R  ${D}rotate$R" [k4]="   ${W}↓ s$R  ${D}soft drop$R"
    [k5]="   ${W}␣ z$R  ${D}hard drop$R" [k6]="   ${W}  q$R  ${D}quit$R"
  )
  while IFS= read -r line; do
    case $line in
      *"Infinite loop"*|*"excessive recursion"*|*"too long"*|*"== Ruleset"*)
        echo "$GAME: sendmail: $line" >&2; return 1 ;;
      Game*" returns:"*) ;;
      *) continue ;;
    esac
    IFS=' ' read -ra toks <<<"${line#*returns:}"
    out=""
    for tok in "${toks[@]}"; do
      case $tok in
        quit) return 0 ;;
        fin) printf '%s' "$out"; return 0 ;;
      esac
      out+=${G[$tok]-$tok}
    done
    printf '%s' "$out"
  done
}

# Each event number N becomes the -bt input line "Game N" (run ruleset Game on N).
# DontProbeInterfaces stops sendmail from reverse-resolving every network
# interface address at start-up, which can stall for tens of seconds when a
# lookup times out.
run_engine() {
  local sm line
  sm=$(find_sendmail) || { echo "$GAME: sendmail not found" >&2; return 1; }
  while IFS= read -r line; do printf 'Game %s\n' "$line"; done |
    "$sm" -ODontProbeInterfaces=true -C "$1" -bt 2>&1 | decode
}

check_tool() { find_sendmail >/dev/null || { echo "$GAME: '$NEEDS' is not installed" >&2; return 1; }; }

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
