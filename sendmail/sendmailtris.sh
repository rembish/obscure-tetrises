#!/usr/bin/env bash
# sendmailtris.sh - launcher for sendmailtris, a falling-block puzzle game written in sendmail.cf.
#
#   ./sendmailtris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sendmail/sendmailtris.sh | bash
#
#   ./sendmailtris.sh --pipe    events on stdin, frames on stdout (used by tests/check.sh)
#
# The launcher turns keys into event numbers and sends a tick every 100 ms.
# Gravity, randomness, scoring and drawing all happen in the engine (see ../SPEC.md).

# ---- per-game settings ------------------------------------------------------
GAME=sendmailtris
ENGINE=sendmailtris.cf
NEEDS=sendmail
BASE_URL="${SENDMAILTRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sendmail}"

# -----------------------------------------------------------------------------

# POSIX part: under plain sh (e.g. `curl ... | sh`), hand over to bash.
if [ -z "${BASH_VERSION:-}" ]; then
  command -v bash >/dev/null 2>&1 || { echo "$GAME: bash is required" >&2; exit 1; }
  case "$0" in *"$GAME"*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$BASE_URL/$GAME.sh" | bash -s -- "$@"
  else
    wget -qO- "$BASE_URL/$GAME.sh" | bash -s -- "$@"
  fi
  exit $?
fi

# bash from here on; everything runs from main() so `curl | bash` parses it all first.

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
run_engine() {
  local sm line
  sm=$(find_sendmail) || { echo "$GAME: sendmail not found" >&2; return 1; }
  while IFS= read -r line; do printf 'Game %s\n' "$line"; done |
    "$sm" -C "$1" -bt 2>&1 | decode
}

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  else echo "$GAME: need curl or wget to download $ENGINE" >&2; return 1
  fi
}

# Keys -> event numbers (0 tick, 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop, 9 quit).
input_loop() {
  local IFS= key rest now t0="" code
  echo "${SEED:-$(( (RANDOM << 15 | RANDOM) % 2147483646 + 1 ))}"
  [[ -n ${EPOCHREALTIME:-} ]] && t0=${EPOCHREALTIME//[.,]/}
  while :; do
    code=""
    if read -rsn1 -t 0.1 key; then
      if [[ $key == $'\e' ]]; then
        read -rsn1 -t 0.01 rest; key+=$rest
        [[ $rest == '[' || $rest == O ]] && { read -rsn1 -t 0.01 rest; key+=$rest; }
      fi
      case $key in
        a|A|$'\e[D'|$'\eOD') code=1 ;;
        d|D|$'\e[C'|$'\eOC') code=2 ;;
        w|W|$'\e[A'|$'\eOA') code=3 ;;
        s|S|$'\e[B'|$'\eOB'|'') code=4 ;;
        z|Z|' ') code=5 ;;
        q|Q) echo 9; return 0 ;;
      esac
      [[ -n $code ]] && echo "$code"
    elif [[ -z $t0 ]]; then
      echo 0                                  # bash 4: tick on every timeout
    fi
    if [[ -n $t0 ]]; then                     # bash 5: steady 100 ms ticks
      now=${EPOCHREALTIME//[.,]/}
      (( now - t0 > 1000000 )) && t0=$now     # don't replay a long pause
      while (( now - t0 >= 100000 )); do echo 0; (( t0 += 100000 )); done
    fi
  done
}

tmp=""   # download dir, if any; global so the EXIT trap can clean it up

main() {
  local dir="" engine

  if (( BASH_VERSINFO[0] < 4 )); then
    echo "$GAME: needs bash 4 or newer (this is $BASH_VERSION)" >&2; return 1
  fi
  find_sendmail >/dev/null || { echo "$GAME: '$NEEDS' is not installed" >&2; return 1; }
  [[ ${1:-} == --pipe || -r /dev/tty ]] || { echo "$GAME: needs an interactive terminal" >&2; return 1; }

  # Use the engine next to this script, or download it (e.g. under curl | bash).
  if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
    dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  fi
  engine="$dir/$ENGINE"
  if [[ -z $dir || ! -f $engine ]]; then
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/$GAME.XXXXXX") || return 1
    engine="$tmp/$ENGINE"
    fetch "$BASE_URL/$ENGINE" "$engine" || return 1
  fi

  if [[ ${1:-} == --pipe ]]; then
    trap '[[ -n $tmp ]] && rm -rf "$tmp"' EXIT
    run_engine "$engine"
    return
  fi

  trap 'printf "\033[?25h\033[m\n" >/dev/tty; stty echo </dev/tty 2>/dev/null; [[ -n $tmp ]] && rm -rf "$tmp"' EXIT
  trap 'exit 130' INT TERM HUP
  printf '\033[2J\033[H\033[?25l' >/dev/tty

  input_loop </dev/tty | run_engine "$engine" >/dev/tty
}

main "$@"
exit $?
