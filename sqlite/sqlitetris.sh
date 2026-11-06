#!/usr/bin/env bash
# sqlitetris.sh - launcher for sqlitetris, a falling-block puzzle game written in SQL for sqlite3.
#
#   ./sqlitetris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sqlite/sqlitetris.sh | bash
#
#   ./sqlitetris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *sqlitetris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/sqlite/sqlitetris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=sqlitetris DIR=sqlite ENGINE=sqlitetris.sql NEEDS=sqlite3

# One long-running sqlite3 shell with an in-memory database plays the game. It
# first reads the engine (dot-commands and SQL), then one fixed statement pair
# per input line: "INSERT INTO ev VALUES(N);SELECT*FROM frame;". The INSERT
# fires the trigger that plays event N, the SELECT prints the frame. Blank lines
# are skipped, since "VALUES()" would be a syntax error. -init /dev/null keeps a
# ~/.sqliterc out of it. When the game ends the engine stops the shell with a
# deliberate SQL error (it runs with .bail on). That message goes to stderr
# under --pipe and is dropped on the terminal, where it would mess up the screen.
run_engine() {
  local line err=/dev/null
  (( pipe )) && err=/dev/stderr
  {
    cat "$1"
    while IFS= read -r line; do
      [[ -n $line ]] && printf 'INSERT INTO ev VALUES(%s);SELECT*FROM frame;\n' "$line"
    done
  } | sqlite3 -batch -init /dev/null :memory: 2>"$err"
  return 0   # sqlite3 exits 1 after that deliberate error; the game ended normally
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
