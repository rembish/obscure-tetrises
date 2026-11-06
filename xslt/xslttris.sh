#!/usr/bin/env bash
# xslttris.sh - launcher for xslttris, a falling-block puzzle game written in XSLT 1.0 and run by xsltproc.
#
#   ./xslttris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/xslt/xslttris.sh | bash
#
#   ./xslttris.sh --pipe    events on stdin, frames on stdout (used by tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *xslttris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/xslt/xslttris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=xslttris DIR=xslt ENGINE=xslttris.xsl NEEDS=xsltproc
# An XSLT processor transforms a whole document and can't read a stream. So
# xsltproc runs once per batch of events: the input document is the state so
# far, $ev holds the new events, and the stylesheet prints the batch's frames
# and writes the next state to $out. It writes no state when the game is over.
# A reader appends stdin to a queue file while a batch runs, and the next run
# takes everything that has arrived since (up to CHUNK events). xsltproc starts
# in a few milliseconds, so in play a batch is usually one event or two.
# Each event is one level of template recursion, and libxslt's default limits
# (3000 levels, 15000 variables) are too low for a big batch; --maxvars and
# --maxdepth raise them. Keep CHUNK to a few thousand at most: far deeper
# recursion overflows the C stack and xsltproc crashes.
CHUNK=${XSLTTRIS_CHUNK:-500}
XSLTFLAGS="--maxdepth 100000 --maxvars 10000000"
run_engine() {
  local seed line ev quit=0 done=0 total eof first=1 reader
  IFS= read -r seed || return 0
  seed=$(printf '%s' "$seed" | tr -cd 0-9)
  echo "<s seed=\"${seed:-1}\"/>" > "$work/state.xml"
  : > "$work/queue"
  { while IFS= read -r line || [ -n "$line" ]; do printf '%s\n' "$line"; done >> "$work/queue"
    : > "$work/eof"; } <&0 & reader=$!
  while [ "$quit" = 0 ]; do
    [ -e "$work/eof" ] && eof=1 || eof=0              # check before counting
    total=$(wc -l < "$work/queue")
    if [ "$total" -eq "$done" ] && [ "$first" = 0 ]; then
      [ "$eof" = 1 ] && break
      sleep 0.02; continue
    fi
    [ "$total" -gt $((done + CHUNK)) ] && total=$((done + CHUNK))
    : > "$work/batch"
    [ "$total" -gt "$done" ] && sed -n "$((done + 1)),${total}p" "$work/queue" | tr -d ' \t\r' > "$work/batch"
    done=$total
    ev=""
    while IFS= read -r line; do
      case $line in ''|*[!0-9]*) continue ;; esac     # blank or not a code: ignored
      [ ${#line} -gt 18 ] && continue
      line=$((10#$line))
      [ "$line" = 9 ] && { quit=1; break; }           # quit: stop here
      ev="$ev$line "
    done < "$work/batch"
    [ -z "$ev" ] && [ "$first" = 0 ] && continue      # nothing to play
    first=0
    rm -f "$work/next.xml"
    xsltproc $XSLTFLAGS --stringparam ev "$ev" --stringparam out "$work/next.xml" "$1" "$work/state.xml" || break
    [ -e "$work/next.xml" ] || break                  # game over
    mv "$work/next.xml" "$work/state.xml"
  done
  kill "$reader" 2>/dev/null
  return 0
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
