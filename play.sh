#!/usr/bin/env bash
# play.sh - one starting point for every game in this repo.
#
#   ./play.sh                 pick a game from a menu
#   ./play.sh jq              start jqtris straight away
#   ./play.sh --min tex       start the golfed textris (tex/textris.min.tex)
#   ./play.sh --native vim    vimtris played by Vim itself, without the launcher
#   ./play.sh --list          list the games and which tools are installed
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/play.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/play.sh | bash -s -- --min m4
#
# From a clone it runs the game's own launcher (<dir>/<game>.sh). Under
# curl | bash it downloads that launcher (and the .min engine, if asked for)
# to a temporary directory, which is deleted afterwards. The native mode runs
# the tool itself on the game's .native file instead, where there is one.

BASE_URL="${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}"

# POSIX part: under plain sh (e.g. `curl ... | sh`), hand over to bash.
if [ -z "${BASH_VERSION:-}" ]; then
  command -v bash >/dev/null 2>&1 || { echo "play.sh: bash is required" >&2; exit 1; }
  case "$0" in *play.sh*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$BASE_URL/play.sh" | bash -s -- "$@"
  else
    wget -qO- "$BASE_URL/play.sh" | bash -s -- "$@"
  fi
  exit $?
fi

# bash from here on; everything runs from main() so `curl | bash` parses it all first.

# dir|game|engine file|tool to look for|written in (_tests/check.sh reads this table too)
GAMES=(
  "awk|awktris|awktris.awk|awk|POSIX awk (mawk, gawk, busybox)"
  "bc|bctris|bctris.bc|bc|bc, the arbitrary-precision calculator"
  "cmake|cmaketris|cmaketris.cmake|cmake|CMake script (cmake -P)"
  "cpp|cpptris|cpptris.cpp|g++|C++ templates, computed by g++"
  "dc|dctris|dctris.dc|dc|dc, the reverse-Polish desk calculator"
  "emacs|emacstris|emacstris.el|emacs|Emacs Lisp, in emacs --batch"
  "ghci|ghcitris|ghcitris.hs|ghci|Haskell type families, reduced by ghci"
  "gnuplot|gnuplottris|gnuplottris.gp|gnuplot|gnuplot 6's command language"
  "jq|jqtris|jqtris.jq|jq|jq, the JSON processor"
  "m4|m4tris|m4tris.m4|m4|m4, the macro processor"
  "make|maketris|maketris.mk|make|GNU make"
  "postscript|postscripttris|postscripttris.ps|gs|PostScript, run by Ghostscript"
  "preprocessor|preprocessortris|preprocessortris.h|cpp|the C preprocessor, fed its own output"
  "rewrite|rewritetris|rewritetris.conf|httpd|Apache mod_rewrite rules, one request per event"
  "sed|sedtris|sedtris.sed|sed|GNU sed, the stream editor"
  "sendmail|sendmailtris|sendmailtris.cf|sendmail|sendmail.cf rewriting rules"
  "sqlite|sqlitetris|sqlitetris.sql|sqlite3|SQL: SQLite triggers and views"
  "tex|textris|textris.tex|tex|plain TeX"
  "troff|trofftris|trofftris.tr|troff|troff, the typesetter behind man"
  "vim|vimtris|vimtris.vim|vim|Vim script, in headless vim -es"
  "xslt|xslttris|xslttris.xsl|xsltproc|XSLT 1.0 stylesheet, run by xsltproc"
)

# dir|native file|command that plays it (the file goes last): the games whose
# tool can read the keys and keep the time itself.
NATIVE=(
  "emacs|emacstris.native.el|emacs -Q -nw -l"
  "vim|vimtris.native.vim|vim -Nu NONE -i NONE -n -S"
)

native_of() {   # native_of DIR: prints its NATIVE entry
  local spec
  for spec in "${NATIVE[@]}"; do [[ ${spec%%|*} == "$1" ]] && { echo "$spec"; return 0; }; done
  return 1
}

have() {
  [[ $1 == sendmail ]] && { [[ -x /usr/sbin/sendmail || -x /usr/lib/sendmail ]] && return 0; }
  [[ $1 == httpd ]] && { command -v apache2 >/dev/null 2>&1 && return 0; }
  command -v "$1" >/dev/null 2>&1
}

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  else echo "play.sh: need curl or wget to download $1" >&2; return 1
  fi
}

list() {   # list [native]: in native mode, the games without one are marked
  local i=0 spec d game file tool what mark
  for spec in "${GAMES[@]}"; do
    IFS='|' read -r d game file tool what <<<"$spec"
    if [[ ${1:-} == native ]] && ! native_of "$d" >/dev/null; then mark=$'\e[2m– no native mode\e[m'
    elif have "$tool"; then mark=$'\e[32m✓\e[m'; else mark=$'\e[31m✗ no '"$tool"$'\e[m'; fi
    printf '  \e[1m%2d\e[m  %-15s %-44s %s\n' $((++i)) "$game" "$what" "$mark"
  done
}

# find a game by number, dir name or game name; prints its spec
lookup() {
  local i=0 spec d game
  for spec in "${GAMES[@]}"; do
    IFS='|' read -r d game _ <<<"$spec"
    (( ++i ))
    if [[ $1 == "$i" || $1 == "$d" || $1 == "$game" ]]; then echo "$spec"; return 0; fi
  done
  return 1
}

tmp=""
launch() {   # launch <spec> <mode: readable, golfed or native>
  local d game file tool what here="" launcher engine_file="" native nfile ncmd
  IFS='|' read -r d game file tool what <<<"$1"
  have "$tool" || { echo "play.sh: $game needs '$tool', which is not installed" >&2; return 1; }
  if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
    here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  fi
  if [[ $2 == native ]]; then
    native=$(native_of "$d") || { echo "play.sh: $game has no native mode (only ${NATIVE[*]%%|*})" >&2; return 1; }
    IFS='|' read -r _ nfile ncmd <<<"$native"
    nfile="$here/$d/$nfile"
    if [[ -z $here || ! -f $nfile ]]; then
      # The native file loads the game's engine from next to itself.
      tmp=$(mktemp -d "${TMPDIR:-/tmp}/play.XXXXXX") || return 1
      trap '[[ -n $tmp ]] && rm -rf "$tmp"' EXIT
      nfile="$tmp/${nfile##*/}"
      fetch "$BASE_URL/$d/${nfile##*/}" "$nfile" && fetch "$BASE_URL/$d/$file" "$tmp/$file" || return 1
    fi
    # shellcheck disable=SC2086 # the command is words on purpose
    $ncmd "$nfile" </dev/tty >/dev/tty
    return
  fi
  launcher="$here/$d/$game.sh"
  [[ $2 == golfed ]] && engine_file="$here/$d/${file%.*}.min.${file##*.}"
  if [[ -z $here || ! -f $launcher ]]; then
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/play.XXXXXX") || return 1
    trap '[[ -n $tmp ]] && rm -rf "$tmp"' EXIT
    launcher="$tmp/$game.sh"
    fetch "$BASE_URL/$d/$game.sh" "$launcher" || return 1
    if [[ $2 == golfed ]]; then
      engine_file="$tmp/${file%.*}.min.${file##*.}"
      fetch "$BASE_URL/$d/${engine_file##*/}" "$engine_file" || return 1
    fi
  fi
  TRIS_URL=$BASE_URL ENGINE_FILE=$engine_file bash "$launcher"
}

main() {
  local mode=readable choice spec
  (( BASH_VERSINFO[0] >= 4 )) || { echo "play.sh: needs bash 4 or newer" >&2; return 1; }
  while [[ ${1:-} == -* ]]; do
    case $1 in
      --min|-m) mode=golfed ;;
      --native|-n) mode=native ;;
      --list|-l) list; return 0 ;;
      -h|--help) sed -n '2,15s/^# \{0,1\}//p' "${BASH_SOURCE[0]}" 2>/dev/null || echo "usage: play.sh [--min|--native] [game]"; return 0 ;;
      *) echo "play.sh: unknown option $1" >&2; return 1 ;;
    esac
    shift
  done
  if [[ -n ${1:-} ]]; then
    spec=$(lookup "$1") || { echo "play.sh: no such game '$1' (try --list)" >&2; return 1; }
    launch "$spec" "$mode"; return
  fi
  [[ -r /dev/tty ]] || { echo "play.sh: needs an interactive terminal" >&2; return 1; }
  while :; do
    printf '\e[2J\e[H\n  \e[1;38;5;75mObscure Tetrises\e[m — the same game in unlikely Unix tools\n\n'
    list "$mode"
    printf '\n  version: \e[1m%s\e[m   (g: the golfed .min engines, n: native, the tool reads the keys itself)\n' "$mode"
    printf '\n  game number or name, g, n, q to quit: '
    read -r choice </dev/tty || return 0
    case $choice in
      q|Q|'') return 0 ;;
      g|G) [[ $mode == golfed ]] && mode=readable || mode=golfed; continue ;;
      n|N) [[ $mode == native ]] && mode=readable || mode=native; continue ;;
    esac
    spec=$(lookup "$choice") || continue
    launch "$spec" "$mode"
    printf '\n  press Enter for the menu ' >/dev/tty; read -r </dev/tty || return 0
  done
}

main "$@"
exit $?
