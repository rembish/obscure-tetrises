# gnuplottris.gp - a falling-block puzzle game written in gnuplot's command language.
#
#   gnuplot gnuplottris.gp -
#
# After loading this file, gnuplot reads commands from stdin. The launcher
# sends one statement per event: the seed first, then the event numbers from
# ../SPEC.md (0 tick, 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop, 9 quit),
# each as
#     if ($step(N)) { exit }
# $step returns 1 once the game is over or you quit. (exit inside a function block
# only leaves the function, so leaving gnuplot happens at the top level.)
#
# Uses gnuplot 6 function blocks (function $name(args) << EOD), arrays (which start
# at index 1) and 64-bit integer arithmetic with C-style operators. Frames go to
# stdout with print. print always ends with a newline, so each frame is one string
# and print adds the newline after the last row.

set print "-"

# ---- tables ---------------------------------------------------------------------
array M[28] = [240, 17476, 3840, 8738,  102, 102, 102, 102,  114, 610, 624, 562, \
               54, 1122, 864, 561,  99, 612, 1584, 306,  113, 550, 1136, 802, \
               116, 1570, 368, 547]
array COL[7] = [51, 226, 135, 46, 196, 33, 208]
array PTS[5] = [0, 40, 100, 300, 1200]
array KICK[5] = [0, -1, 1, -2, 2]
array b[200]

# ---- output pieces -------------------------------------------------------------------
E = "\033["
R = E . "m"
K = E . "K\n"
B = E . "38;5;60m"
D = E . "38;5;244m"
W = E . "1m"
array CELL[8]
CELL[1] = E . "38;5;237m ·" . R
do for [p=0:6] { CELL[p + 2] = sprintf("%s38;5;%dm██%s", E, COL[p + 1], R) }
array PANEL[20]
do for [p=1:20] { PANEL[p] = "" }
PANEL[1] = "   " . B . "╭──" . R . " " . D . "next" . R . " " . B . "──────╮" . R
PANEL[2] = "   " . B . "│" . R . "              " . B . "│" . R
PANEL[7] = PANEL[2]
PANEL[8] = "   " . B . "╰──────────────╯" . R
PANEL[10] = "   " . D . "score" . R
PANEL[14] = "   " . D . "controls" . R
PANEL[15] = "   " . W . "← a" . R . "  " . D . "move left" . R
PANEL[16] = "   " . W . "→ d" . R . "  " . D . "move right" . R
PANEL[17] = "   " . W . "↑ w" . R . "  " . D . "rotate" . R
PANEL[18] = "   " . W . "↓ s" . R . "  " . D . "soft drop" . R
PANEL[19] = "   " . W . "␣ z" . R . "  " . D . "hard drop" . R
PANEL[20] = "   " . W . "  q" . R . "  " . D . "quit" . R

started = 0

# ---- game --------------------------------------------------------------------------
# Park-Miller: s = s * 16807 mod (2^31 - 1); the next piece is s mod 7
function $draw() << EOD
  s = (s * 16807) % 2147483647
  nxt = s % 7
  return 0
EOD

# 1 if the current piece fits at (px, py) with rotation pr
function $fits(px, py, pr) << EOD
  local m = M[cur * 4 + pr + 1]
  local i = 0
  local fx = 0
  local fy = 0
  do for [i=0:15] {
    if ((m >> i) & 1) {
      fx = px + i % 4
      fy = py + i / 4
      if (fx < 0 || fx > 9 || fy < 0 || fy > 19) { return 0 }
      if (b[fy * 10 + fx + 1] != 0) { return 0 }
    }
  }
  return 1
EOD

# write v into the current piece's cells
function $paint(v) << EOD
  local m = M[cur * 4 + r + 1]
  local i = 0
  do for [i=0:15] {
    if ((m >> i) & 1) { b[(y + i / 4) * 10 + x + i % 4 + 1] = v }
  }
  return 0
EOD

function $spawn() << EOD
  x = 3
  y = 0
  r = 0
  t = 0
  if (!$fits(3, 0, 0)) { over = 1 }
  return 0
EOD

# paint, copy the rows that aren't full down to dst, clear the rest, score, next piece
function $lock() << EOD
  local d = $paint(cur + 1)
  local dst = 19
  local src = 0
  local j = 0
  local cnt = 0
  do for [src=19:0:-1] {
    cnt = 0
    do for [j=0:9] { if (b[src * 10 + j + 1] != 0) { cnt = cnt + 1 } }
    if (cnt < 10) {
      do for [j=0:9] { b[dst * 10 + j + 1] = b[src * 10 + j + 1] }
      dst = dst - 1
    }
  }
  local cl = dst + 1
  if (cl > 0) { do for [j=1:cl * 10] { b[j] = 0 } }
  score = score + PTS[cl + 1] * (lines / 10 + 1)
  lines = lines + cl
  cur = nxt
  d = $draw()
  d = $spawn()
  return 0
EOD

function $down() << EOD
  if ($fits(x, y + 1, r)) { y = y + 1 } else { local d = $lock() }
  return 0
EOD

function $shift(dx) << EOD
  if ($fits(x + dx, y, r)) { x = x + dx }
  return 0
EOD

function $rotate() << EOD
  local nr = (r + 1) % 4
  local q = 0
  do for [q=1:5] {
    if ($fits(x + KICK[q], y, nr)) {
      x = x + KICK[q]
      r = nr
      break
    }
  }
  return 0
EOD

function $drop() << EOD
  while ($fits(x, y + 1, r)) { y = y + 1 }
  local d = $lock()
  return 0
EOD

# ---- rendering ------------------------------------------------------------------------
function $render() << EOD
  local d = 0
  if (!over) { d = $paint(cur + 1) }
  local f = E . "H  " . E . "1;38;5;75mG N U P L O T T R I S" . R . K
  f = f . " " . B . "╔════════════════════╗" . R . K
  local nm = M[nxt * 4 + 1]
  local row = 0
  local j = 0
  local q = 0
  do for [row=0:19] {
    f = f . " " . B . "║" . R
    if (over && row == 9) {
      f = f . E . "1;7m     GAME  OVER     " . R
    } else {
      do for [j=0:9] { f = f . CELL[b[row * 10 + j + 1] + 1] }
    }
    f = f . B . "║" . R
    if (row >= 2 && row <= 5) {
      f = f . "   " . B . "│" . R . "   "
      do for [q=0:3] {
        f = f . (((nm >> ((row - 2) * 4 + q)) & 1) ? CELL[nxt + 2] : "  ")
      }
      f = f . "   " . B . "│" . R
    } else {
      if (row == 10) {
        f = f . sprintf("   %s%d%s", W, score, R)
      } else {
        if (row == 11) {
          f = f . sprintf("   %slevel%s %s%d%s  %slines%s %s%d%s", D, R, W, lines / 10 + 1, R, D, R, W, lines, R)
        } else {
          f = f . PANEL[row + 1]
        }
      }
    }
    f = f . K
  }
  f = f . " " . B . "╚════════════════════╝" . R . E . "K"
  print f
  if (!over) { d = $paint(0) }
  return 0
EOD

# ---- events -----------------------------------------------------------------------------
function $step(e) << EOD
  local d = 0
  local k = 0
  if (!started) {
    s = e
    do for [k=1:200] { b[k] = 0 }
    score = 0
    lines = 0
    over = 0
    d = $draw()
    cur = nxt
    d = $draw()
    d = $spawn()
    started = 1
    d = $render()
    return 0
  }
  if (e == 9) { return 1 }
  local emit = 1
  if (e == 0) {
    t = t + 1
    if (t + lines / 10 >= 10) { t = 0; d = $down() } else { emit = 0 }
  } else {
    if (e == 1) { d = $shift(-1) } else {
      if (e == 2) { d = $shift(1) } else {
        if (e == 3) { d = $rotate() } else {
          if (e == 4) { d = $down() } else {
            if (e == 5) { d = $drop() } else { emit = 0 }
          }
        }
      }
    }
  }
  if (emit) {
    d = $render()
  }
  return over
EOD
