// jsonnettris.jsonnet - a falling-block puzzle game written in Jsonnet.
//
//   ./jsonnettris.sh       (runs jsonnet once per event and plays it)
//
// Jsonnet is a configuration language: pure, lazy, with no input, no output
// and no state, that turns one program into one JSON document. So it plays
// one event per run, as a function from the old state and the event to the
// new state and the frame:
//
//   jsonnet -S -m DIR --ext-str input=3 --ext-code-file state=DIR/state.json jsonnettris.jsonnet
//
// The input is the seed on the first run (the state is null then) and an
// event after that (../SPEC.md: 0 tick, 1 left, 2 right, 3 rotate, 4 soft
// drop, 5 hard drop; 9 quit stops the launcher). The result is an object of
// two strings, and -m writes each to its own file: "frame", the bytes to
// print (empty for a tick that moved nothing), and "state.json", the next
// state, which the next run reads back. At game over there is no next state.

local input = std.parseInt(std.extVar('input'));
local old = std.extVar('state');

// ---- tables ------------------------------------------------------------------------

// The four rotations of I O T S Z J L: bit y*4 + x of the 4x4 box.
local masks = [
  [240, 17476, 3840, 8738], [102, 102, 102, 102], [114, 610, 624, 562], [54, 1122, 864, 561],
  [99, 612, 1584, 306], [113, 550, 1136, 802], [116, 1570, 368, 547],
];
local colours = [51, 226, 135, 46, 196, 33, 208];
local points = [0, 40, 100, 300, 1200];

// The same, as the [x, y] cells of each piece and rotation. (Working them out
// from the masks on every run costs more than the rest of a quiet tick.)
local cellTable = [
  [[[0, 1], [1, 1], [2, 1], [3, 1]], [[2, 0], [2, 1], [2, 2], [2, 3]], [[0, 2], [1, 2], [2, 2], [3, 2]], [[1, 0], [1, 1], [1, 2], [1, 3]]],
  [[[1, 0], [2, 0], [1, 1], [2, 1]], [[1, 0], [2, 0], [1, 1], [2, 1]], [[1, 0], [2, 0], [1, 1], [2, 1]], [[1, 0], [2, 0], [1, 1], [2, 1]]],
  [[[1, 0], [0, 1], [1, 1], [2, 1]], [[1, 0], [1, 1], [2, 1], [1, 2]], [[0, 1], [1, 1], [2, 1], [1, 2]], [[1, 0], [0, 1], [1, 1], [1, 2]]],
  [[[1, 0], [2, 0], [0, 1], [1, 1]], [[1, 0], [1, 1], [2, 1], [2, 2]], [[1, 1], [2, 1], [0, 2], [1, 2]], [[0, 0], [0, 1], [1, 1], [1, 2]]],
  [[[0, 0], [1, 0], [1, 1], [2, 1]], [[2, 0], [1, 1], [2, 1], [1, 2]], [[0, 1], [1, 1], [1, 2], [2, 2]], [[1, 0], [0, 1], [1, 1], [0, 2]]],
  [[[0, 0], [0, 1], [1, 1], [2, 1]], [[1, 0], [2, 0], [1, 1], [1, 2]], [[0, 1], [1, 1], [2, 1], [2, 2]], [[1, 0], [1, 1], [0, 2], [1, 2]]],
  [[[2, 0], [0, 1], [1, 1], [2, 1]], [[1, 0], [1, 1], [1, 2], [2, 2]], [[0, 1], [1, 1], [2, 1], [0, 2]], [[0, 0], [1, 0], [1, 1], [1, 2]]],
];
local cells(p, r) = cellTable[p][r];

// ---- the rules ---------------------------------------------------------------------

// Park-Miller. Jsonnet's numbers are doubles, exact up to 2^53, and
// s * 16807 stays below 2^46.
local rand(s) = s * 16807 % 2147483647;

local level(g) = std.floor(g.lines / 10) + 1;

// The board is 20 numbers, one per row, top first: ten octal digits, the
// lowest one column 0, each 0 for empty or piece + 1. (The state is read and
// written on every run, and 20 numbers are much less to parse than 200.)
local pow8 = [std.pow(8, i) for i in std.range(0, 10)];
local at(row, x) = std.floor(row / pow8[x]) % 8;

// Does piece g.cur fit at (x, y) in rotation r?
local fits(g, x, y, r) =
  std.all([
    local cx = x + c[0], cy = y + c[1];
    cx >= 0 && cx < 10 && cy < 20 && at(g.board[cy], cx) == 0
    for c in cells(g.cur, r)
  ]);

// The board with the piece written in: its cells are empty, so that is adding.
local stamp(g) =
  local add(y) = std.foldl(function(a, c) if g.y + c[1] == y then a + (g.cur + 1) * pow8[g.x + c[0]] else a,
                           cells(g.cur, g.r), 0);
  [g.board[y] + add(y) for y in std.range(0, 19)];

// The next piece falls from x = 3, y = 0, and a new next piece is drawn. If it
// doesn't fit there, the game is over.
local spawn(g) =
  local seed = rand(g.seed);
  local h = g { cur: g.next, next: seed % 7, seed: seed, x: 3, y: 0, r: 0, t: 0 };
  h { over: !fits(h, 3, 0, 0) };

// Write the piece into the board, remove the full rows (empty ones come in on
// top), score with the level before the clear, then spawn.
local full(row) = std.all([at(row, x) != 0 for x in std.range(0, 9)]);
local lock(g) =
  local kept = [row for row in stamp(g) if !full(row)];
  local n = 20 - std.length(kept);
  spawn(g {
    board: std.repeat([0], n) + kept,
    score: g.score + points[n] * level(g),
    lines: g.lines + n,
  });

local stepDown(g) = if fits(g, g.x, g.y + 1, g.r) then g { y: g.y + 1 } else lock(g);

local hardDrop(g) = if fits(g, g.x, g.y + 1, g.r) then hardDrop(g { y: g.y + 1 }) else lock(g);

// Rotate: the new rotation at the kicks 0, -1, +1, -2, +2; the first that fits.
local rotate(g) =
  local r = (g.r + 1) % 4;
  local ok = [dx for dx in [0, -1, 1, -2, 2] if fits(g, g.x + dx, g.y, r)];
  if std.length(ok) > 0 then g { x: g.x + ok[0], r: r } else g;

// One event. "show" says whether it gets a frame: a tick only when the
// piece falls (every max(1, 11 - level) ticks).
local event(g, e) =
  if e == 0 then
    local t = g.t + 1;
    if t >= std.max(1, 11 - level(g)) then stepDown(g { t: 0 }) { show: true } else g { t: t, show: false }
  else if e == 1 || e == 2 then
    local dx = if e == 1 then -1 else 1;
    (if fits(g, g.x + dx, g.y, g.r) then g { x: g.x + dx } else g) { show: true }
  else if e == 3 then rotate(g) { show: true }
  else if e == 4 then stepDown(g) { show: true }
  else if e == 5 then hardDrop(g) { show: true }
  else g { show: false };

local start(seed) =
  local s = rand(seed);
  spawn({ seed: s, next: s % 7, board: std.repeat([0], 20), score: 0, lines: 0, cur: 0, x: 0, y: 0, r: 0, t: 0 })
  { show: true };

// ---- the frame ---------------------------------------------------------------------

local E = '\u001b[';
local B(s) = E + '38;5;60m' + s + E + 'm';
local D(s) = E + '38;5;244m' + s + E + 'm';
local Bold(s) = E + '1m' + s + E + 'm';
local cell(v) = if v == 0 then E + '38;5;237m ·' + E + 'm' else E + '38;5;' + colours[v - 1] + 'm██' + E + 'm';

local keys = [['← a', 'move left'], ['→ d', 'move right'], ['↑ w', 'rotate'],
              ['↓ s', 'soft drop'], ['␣ z', 'hard drop'], ['  q', 'quit']];

local panel(g, row) =
  local box(s) = '   ' + B('│') + s + B('│');
  if row == 0 then '   ' + B('╭──') + ' ' + D('next') + ' ' + B('──────╮')
  else if row == 1 || row == 6 then box('              ')
  else if row >= 2 && row <= 5 then
    local m = masks[g.next][0];
    box('   ' + std.join('', [if std.floor(m / std.pow(2, (row - 2) * 4 + x)) % 2 == 1 then cell(g.next + 1) else '  '
                              for x in std.range(0, 3)]) + '   ')
  else if row == 7 then '   ' + B('╰──────────────╯')
  else if row == 9 then '   ' + D('score')
  else if row == 10 then '   ' + Bold(std.toString(g.score))
  else if row == 11 then '   ' + D('level') + ' ' + Bold(std.toString(level(g))) + '  ' + D('lines') + ' ' + Bold(std.toString(g.lines))
  else if row == 13 then '   ' + D('controls')
  else if row >= 14 then '   ' + Bold(keys[row - 14][0]) + '  ' + D(keys[row - 14][1])
  else '';

// The falling piece is drawn on top of the board, unless the game is over:
// then board row 9 is the banner.
local frame(g) =
  local grid = if g.over then g.board else stamp(g);
  local row(y) =
    ' ' + B('║') +
    (if g.over && y == 9 then E + '1;7m     GAME  OVER     ' + E + 'm' else std.join('', [cell(at(grid[y], x)) for x in std.range(0, 9)])) +
    B('║') + panel(g, y);
  local lines = ['  ' + E + '1;38;5;75mJ S O N N E T T R I S' + E + 'm', ' ' + B('╔' + std.repeat('═', 20) + '╗')]
                + [row(y) for y in std.range(0, 19)]
                + [' ' + B('╚' + std.repeat('═', 20) + '╝')];
  E + 'H' + std.join('', [l + E + 'K\n' for l in lines]);

// ---- one run -----------------------------------------------------------------------

local g = if old == null then start(input) else event(old, input);

{
  frame: if g.show then frame(g) else '',
  // No next state once the game is over: the launcher stops.
  'state.json': if g.over then '' else std.manifestJsonMinified(g { show:: false }),
}
