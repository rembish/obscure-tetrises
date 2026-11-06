#!/usr/bin/env bash
# rewritetris.sh - launcher for rewritetris, a falling-block puzzle game written in Apache mod_rewrite.
#
#   ./rewritetris.sh
#   curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/rewrite/rewritetris.sh | bash
#
#   ./rewritetris.sh --pipe    events on stdin, frames on stdout (used by _tests/check.sh)
#
# Keys, ticks, the engine download and the terminal are handled by ../_lib/launcher.sh.

# Under plain sh (e.g. `curl ... | sh`), hand over to bash first.
if [ -z "${BASH_VERSION:-}" ]; then
  case "$0" in *rewritetris*) [ -f "$0" ] && exec bash "$0" "$@" ;; esac
  u=${TRIS_URL:-https://raw.githubusercontent.com/rembish/obscure-tetrises/master}/rewrite/rewritetris.sh
  { curl -fsSL "$u" 2>/dev/null || wget -qO- "$u"; } | bash -s -- "$@"
  exit $?
fi

GAME=rewritetris DIR=rewrite ENGINE=rewritetris.conf NEEDS=httpd

# The engine is a config file for a private Apache httpd: this launcher starts
# one on a free port of 127.0.0.1, with nothing but mod_rewrite and the engine,
# and plays it over HTTP. Each event is one request, GET /<n>, on a connection
# that bash opens itself (/dev/tcp). The game lives in a cookie, which the
# launcher keeps like a browser would. A 404's body is a frame, 204 means no
# frame, and 410 Gone is the game-over frame.
#
# A new connection per request, not keep-alive: bash's builtins write a line
# at a time, and on a connection that has been open for a while the server's
# delayed ACK of the first line holds the rest back for 40 ms (Nagle). A new
# connection ACKs at once.
httpd="" mods=""

check_tool() {
  local d
  httpd=$(command -v apache2 || command -v httpd) || {   # Debian calls it apache2
    echo "$GAME: needs Apache httpd (apache2 on Debian and Ubuntu, httpd elsewhere)" >&2; return 1; }
  for d in ${APACHE_MODULES:-} /usr/lib/apache2/modules /usr/lib64/httpd/modules /usr/lib/httpd/modules \
           /opt/homebrew/lib/httpd/modules /usr/local/lib/httpd/modules /usr/libexec/apache2; do
    [[ -f $d/mod_rewrite.so ]] && { mods=$d; return 0; }
  done
  echo "$GAME: can't find Apache's mod_rewrite.so (set APACHE_MODULES to its directory)" >&2
  return 1
}

# httpd.conf: the modules that aren't built in, a port, and the engine.
write_conf() {   # write_conf PORT ENGINE
  local static m f mpm=""
  static=$("$httpd" -l 2>/dev/null)
  {
    printf 'ServerRoot "%s"\n' "$work"
    if [[ $static != *event.c* && $static != *prefork.c* && $static != *worker.c* ]]; then
      for m in event prefork worker; do
        [[ -f $mods/mod_mpm_$m.so ]] && { mpm=$m; break; }
      done
      printf 'LoadModule mpm_%s_module "%s/mod_mpm_%s.so"\n' "$mpm" "$mods" "$mpm"
    fi
    for m in unixd authz_core rewrite; do
      f=$mods/mod_$m.so
      [[ $static == *"mod_$m.c"* || ! -f $f ]] || printf 'LoadModule %s_module "%s"\n' "$m" "$f"
    done
    cat <<EOF
Listen 127.0.0.1:$1
ServerName localhost
PidFile "$work/httpd.pid"
ErrorLog "$work/error.log"
DefaultRuntimeDir "$work"
DocumentRoot "$work"
KeepAlive Off
Include "$2"
EOF
  } > "$work/httpd.conf"
}

# get PATH: one request; prints the body. Sets code, and state from Set-Cookie.
get() {
  local line len=0 body cookie=""
  [[ -n $state ]] && cookie="Cookie: tris=$state"$'\r\n'
  exec 3<>"/dev/tcp/127.0.0.1/$port" || return 1
  printf 'GET %s HTTP/1.1\r\nHost: localhost\r\n%s\r\n' "$1" "$cookie" >&3
  IFS=' ' read -r _ code _ <&3 || return 1
  while IFS= read -r line <&3; do
    line=${line%$'\r'}
    [[ -z $line ]] && break
    case ${line,,} in
      content-length:*) len=${line#*: } ;;
      set-cookie:\ tris=*) state=${line#*tris=}; state=${state%%;*} ;;
    esac
  done
  if (( len > 0 )); then
    IFS= read -r -N "$len" body <&3 || return 1
    printf '%s' "$body"
  fi
  exec 3>&-
}

run_engine() {
  local engine=$1 port pid="" i seed line state="" code=""
  local LC_ALL=C    # byte counts for read -N
  for _ in 1 2 3 4 5; do       # five ports, in case one is taken
    port=$(( 20000 + (RANDOM << 15 | RANDOM) % 40000 ))
    write_conf "$port" "$engine"
    "$httpd" -X -f "$work/httpd.conf" </dev/null >"$work/httpd.out" 2>&1 &
    pid=$!
    # httpd writes its pid file once it has the port, so wait for that first:
    # if the port is taken, whatever has it must not get our requests.
    for (( i = 0; i < 100; i++ )); do
      kill -0 "$pid" 2>/dev/null || break                 # it didn't start (port taken?)
      [[ -s $work/httpd.pid ]] && { exec 3<>"/dev/tcp/127.0.0.1/$port"; } 2>/dev/null &&
        { exec 3>&-; break 2; }
      sleep 0.05
    done
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; pid=""
  done
  if [[ -z $pid ]]; then
    echo "$GAME: httpd didn't start:" >&2; cat "$work/httpd.out" "$work/error.log" >&2 2>/dev/null
    return 1
  fi
  IFS= read -r seed && {
    seed=${seed//[!0-9]/}
    get "/${seed:-1}"
    while [[ $code != 410 ]] && IFS= read -r line; do
      line=${line//[!0-9]/}
      [[ -z $line ]] && continue
      [[ $line == 9 ]] && break
      get "/$line" || break
    done
  }
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
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
