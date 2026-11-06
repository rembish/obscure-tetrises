# The shared game spec

Every engine in this collection plays exactly
the same game. Given the same seed and the same events, each one prints the
same bytes. [`_tests/reference.py`](_tests/reference.py) is the executable version of this
document, and [`_tests/check.sh`](_tests/check.sh) diffs every engine against it.

## Input: one number per line

The launcher reads the keyboard and writes lines to the engine's stdin. Only
numbers are sent, because some engines can't parse anything else (`dc` executes
its input, for example, and `bc` reads it with `read()`).

- **First line:** the seed, an integer in `1 … 2147483646`.
- **Every line after that** is one event:

| Code | Event | Keys |
|---|---|---|
| `0` | tick, sent every 100 ms | (timer) |
| `1` | move left | `a`, ← |
| `2` | move right | `d`, → |
| `3` | rotate clockwise | `w`, ↑ |
| `4` | soft drop (one row down) | `s`, ↓, Enter |
| `5` | hard drop | `z`, Space |
| `9` | quit: stop at once, printing nothing | `q` |

The engine also stops when the game is over or its input ends. The explicit
`9` exists because some tools can't detect end of input: GNU bc's `read()`
spins forever at EOF.

## Random numbers

Park–Miller "minimal standard" generator: `s = s * 16807 mod 2147483647`, and
then the piece is `s mod 7`. Every intermediate value fits in 2^53, so jq's
doubles compute it exactly.

At start-up the engine draws the current piece and then the next piece, in that order.

## Pieces

Piece numbers are `0 I, 1 O, 2 T, 3 S, 4 Z, 5 J, 6 L`. A cell on the board holds
`0` for empty or `piece + 1`.

A piece sits in a 4×4 box. Each rotation is a 16-bit mask with bit `y*4 + x`;
`x` runs 0–3 to the right and `y` runs 0–3 downwards:

| Piece | r0 | r1 | r2 | r3 | Colour (256-colour) |
|---|---|---|---|---|---|
| I | 240 | 17476 | 3840 | 8738 | 51 |
| O | 102 | 102 | 102 | 102 | 226 |
| T | 114 | 610 | 624 | 562 | 135 |
| S | 54 | 1122 | 864 | 561 | 46 |
| Z | 99 | 612 | 1584 | 306 | 196 |
| J | 113 | 550 | 1136 | 802 | 33 |
| L | 116 | 1570 | 368 | 547 | 208 |

The board is 10 columns by 20 rows, with row 0 at the top. A piece's box sits
at `(x, y)` on the board. A position *fits* when every cell lands inside the
board on an empty square.

## Rules

- **Spawn:** `x = 3, y = 0, r = 0, t = 0`. If the new piece doesn't fit, the game is over.
- **Level:** `lines / 10 + 1`, using integer division. **Gravity:** every `max(1, 11 - level)` ticks.
- **Tick (`0`):** `t += 1`. When `t` reaches the gravity interval, `t = 0` and the piece *steps down*.
- **Step down:** move down if the piece fits one row lower, otherwise *lock* it.
- **Left/right (`1`, `2`):** move if it fits.
- **Rotate (`3`):** try `r + 1 mod 4` at horizontal offsets `0, -1, +1, -2, +2`, in that order, and take the first that fits. If none fits, nothing happens.
- **Soft drop (`4`):** step down.
- **Hard drop (`5`):** move down while it fits, then lock.
- **Lock:**
  1. Write `piece + 1` into the piece's cells.
  2. Remove full rows, and add empty rows at the top.
  3. Add `[0, 40, 100, 300, 1200][rows] × level` to the score, using the level *before* the cleared rows count.
  4. Add the cleared rows to the line count.
  5. The next piece becomes the current one, draw a new next piece, and spawn.
- Unknown event codes are ignored.

## Output

The engine prints a frame after every event except ticks that didn't move
anything. It also prints a frame once at start-up. When the game ends, it prints the
game-over frame and exits.

`B(s)` below is `ESC[38;5;60m` + `s` + `ESC[m` (border colour), and `D(s)` is
`ESC[38;5;244m` + `s` + `ESC[m` (dim). The frame is `ESC[H`, then 23 lines each
followed by `ESC[K\n`. Every frame ends with a complete line, so tools that can only
print whole lines (make's `$(info)`, gnuplot's `print`, TeX's `\write`, sed) print
exactly this. TeX adds a banner line at start-up and one empty line when it exits; frame
lines are never empty, so textris's launcher drops both. The launcher clears the screen once at start-up and every frame has the
same size, so nothing below the frame needs clearing. sendmail can't print ESC or UTF-8 at all, so
sendmailtris returns the frame as glyph tokens and its launcher decodes them with a
fixed table; the decoded bytes follow this format exactly. troff can only print printable ASCII,
so trofftris writes the frame with C-style escapes (`\033`, `\u2588`) and its launcher
prints each line with `printf '%b'`.

- **Line 0:** two spaces, then `ESC[1;38;5;75m` + the engine's spaced-out title (`J Q T R I S`, `D C T R I S`, …) + `ESC[m`.
- **Line 1:** a space, then `B("╔" + 20×"═" + "╗")`.
- **Lines 2–21 (board rows 0–19):** a space, `B("║")`, ten cells, `B("║")`, and that row's side-panel text.
  - An empty cell is `ESC[38;5;237m ·ESC[m`.
  - A filled cell is `ESC[38;5;<colour>m██ESC[m`. The falling piece is drawn on top of the board.
  - On the game-over frame the falling piece isn't drawn. Board row 9 is replaced by `ESC[1;7m     GAME  OVER     ESC[m`.
- **Line 22:** a space, then `B("╚" + 20×"═" + "╝")`.

The side panel, by board row (rows not listed have no panel text):

| Row | Text |
|---|---|
| 0 | `   ` `B("╭──")` ` ` `D("next")` ` ` `B("──────╮")` |
| 1, 6 | `   ` `B("│")` 14 spaces `B("│")` |
| 2–5 | `   ` `B("│")` `   ` four next-piece cells `   ` `B("│")`. These are box rows 0–3; an empty cell is two spaces, a filled one is coloured `██`. |
| 7 | `   ` `B("╰" + 14×"─" + "╯")` |
| 9 | `   ` `D("score")` |
| 10 | `   ` `ESC[1m` score `ESC[m` |
| 11 | `   ` `D("level")` ` ` `ESC[1m` level `ESC[m` `  ` `D("lines")` ` ` `ESC[1m` lines `ESC[m` |
| 13 | `   ` `D("controls")` |
| 14–19 | `   ` `ESC[1m` key `ESC[m` `  ` `D(action)`: `← a` move left, `→ d` move right, `↑ w` rotate, `↓ s` soft drop, `␣ z` hard drop, `  q` quit |
