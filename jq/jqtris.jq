# jqtris.jq - a falling-block puzzle game written in jq.
#
#   jq -nrj --unbuffered -f jqtris.jq
#
# stdin: the seed on the first line, then one event number per line
# (0 tick, 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop, 9 quit).
# stdout: ANSI frames. The rules and the exact output are in ../SPEC.md.
#
# The whole game is one `foreach inputs`: the state object goes in, an event
# is applied, and a frame comes out. That is the same loop sedtris builds out
# of sed's hold space.

def MASKS: [
  [240, 17476, 3840, 8738],   # I
  [102, 102, 102, 102],       # O
  [114, 610, 624, 562],       # T
  [54, 1122, 864, 561],       # S
  [99, 612, 1584, 306],       # Z
  [113, 550, 1136, 802],      # J
  [116, 1570, 368, 547]       # L
];
def COLOURS: [51, 226, 135, 46, 196, 33, 208];

# Exact integer modulo. Older jq truncates `%` to 32 bits, so avoid it for big numbers.
def mod($a; $b): ($a - $b * (($a / $b) | floor)) | if . < 0 then . + $b elif . >= $b then . - $b else . end;
def bit($m; $i): mod(($m / pow(2; $i) | floor); 2) == 1;

# Cells [x, y] of every piece and rotation, decoded once from the masks.
(MASKS | map(map(. as $m | [range(16) | select(bit($m; .)) | [mod(.; 4), (. / 4 | floor)]]))) as $CELLS

| def E: "\u001b";
  def R: E + "[m";
  def B($s): E + "[38;5;60m" + $s + R;
  def D($s): E + "[38;5;244m" + $s + R;
  def block($p): E + "[38;5;\(COLOURS[$p])m██" + R;
  def dot: E + "[38;5;237m ·" + R;

  def level: (.lines / 10 | floor) + 1;
  def gravity: [1, 11 - level] | max;

  # Park–Miller: s = s * 16807 mod (2^31 - 1); piece = s mod 7.
  def draw: .s = mod(.s * 16807; 2147483647) | mod(.s; 7) as $p | .nxt = $p;

  def fits($x; $y; $r):
    . as $g
    | all($CELLS[$g.cur][$r][];
          ($x + .[0]) as $bx | ($y + .[1]) as $by
          | $bx >= 0 and $bx < 10 and $by >= 0 and $by < 20 and $g.board[$by * 10 + $bx] == 0);

  def spawn:
    .x = 3 | .y = 0 | .r = 0 | .t = 0
    | if fits(.x; .y; .r) then . else .over = true end;

  def lock:
    reduce $CELLS[.cur][.r][] as $c (.; .board[(.y + $c[1]) * 10 + .x + $c[0]] = .cur + 1)
    | ([range(20) as $row | .board[$row * 10 : $row * 10 + 10] | select(any(.[]; . == 0))]) as $kept
    | (20 - ($kept | length)) as $n
    | .board = [range($n * 10) | 0] + ([$kept[][]])
    | .score += [0, 40, 100, 300, 1200][$n] * level
    | .lines += $n
    | .cur = .nxt | draw | spawn;

  def step_down: if fits(.x; .y + 1; .r) then .y += 1 else lock end;

  def rotate:
    (mod(.r + 1; 4)) as $nr
    | . as $g
    | (first(0, -1, 1, -2, 2 | select(. as $dx | $g | fits($g.x + $dx; $g.y; $nr))) // null) as $dx
    | if $dx == null then . else .x += $dx | .r = $nr end;

  def step($e):
    .emit = true
    | if   $e == 0 then .t += 1 | if .t < gravity then .emit = false else .t = 0 | step_down end
      elif $e == 1 then (if fits(.x - 1; .y; .r) then .x -= 1 else . end)
      elif $e == 2 then (if fits(.x + 1; .y; .r) then .x += 1 else . end)
      elif $e == 3 then rotate
      elif $e == 4 then step_down
      elif $e == 5 then until(fits(.x; .y + 1; .r) | not; .y += 1) | lock
      else .emit = false end;

  def KEYS: [["← a", "move left"], ["→ d", "move right"], ["↑ w", "rotate"],
             ["↓ s", "soft drop"], ["␣ z", "hard drop"], ["  q", "quit"]];

  def panel($y):
    if   $y == 0 then "   " + B("╭──") + " " + D("next") + " " + B("──────╮")
    elif $y == 1 or $y == 6 then "   " + B("│") + "              " + B("│")
    elif $y >= 2 and $y <= 5 then
      MASKS[.nxt][0] as $m | .nxt as $p
      | "   " + B("│") + "   "
        + ([range(4) as $x | if bit($m; ($y - 2) * 4 + $x) then block($p) else "  " end] | add)
        + "   " + B("│")
    elif $y == 7 then "   " + B("╰──────────────╯")
    elif $y == 9 then "   " + D("score")
    elif $y == 10 then "   " + E + "[1m\(.score)" + R
    elif $y == 11 then "   " + D("level") + " " + E + "[1m\(level)" + R
                      + "  " + D("lines") + " " + E + "[1m\(.lines)" + R
    elif $y == 13 then "   " + D("controls")
    elif $y >= 14 then KEYS[$y - 14] as $k | "   " + E + "[1m" + $k[0] + R + "  " + D($k[1])
    else "" end;

  def render($title):
    . as $g
    | (if .over then .board
       else reduce $CELLS[.cur][.r][] as $c (.board; .[($g.y + $c[1]) * 10 + $g.x + $c[0]] = $g.cur + 1)
       end) as $grid
    | ["  " + E + "[1;38;5;75m" + $title + R,
       " " + B("╔════════════════════╗"),
       (range(20) as $y
        | " " + B("║")
          + (if $g.over and $y == 9 then E + "[1;7m     GAME  OVER     " + R
             else [$grid[$y * 10 : $y * 10 + 10][] | if . == 0 then dot else block(. - 1) end] | add
             end)
          + B("║") + ($g | panel($y))),
       " " + B("╚════════════════════╝")]
    | E + "[H" + (map(. + E + "[K\n") | add) + E + "[J";

  def title: $ENV.JQTRIS_TITLE // "J Q T R I S";

  (input | {s: ., board: [range(200) | 0], score: 0, lines: 0, over: false}
         | draw | .cur = .nxt | draw | spawn) as $start
  | ($start | render(title)),
    (label $done
     | foreach inputs as $e ($start;
         if .over or $e == 9 then break $done else step($e) end;
         if .emit then render(title) else empty end))
