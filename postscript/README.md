# postscripttris

A falling-block puzzle game written in **PostScript** and run by Ghostscript. No page is
rendered. PostScript is a complete stack language, and this game uses only that: the
operand stack, dictionaries, strings, `for`/`loop`, `print` and a file read.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/postscript/postscripttris.sh | bash
# or, from a clone:
./postscript/postscripttris.sh
```

Needs Ghostscript (`gs`, tested with 10.02.1) and bash 4+. No display or printer is
involved: the launcher runs `gs -q -dNODISPLAY -dBATCH`, so there is no output device.

Install: Debian/Ubuntu `apt install ghostscript` · Fedora `dnf install ghostscript` · macOS `brew install ghostscript`.

## How it works

PostScript is a printer language, but it's also a general-purpose language underneath. Procedures
are executable arrays (`{ … }`), variables are dictionary entries (`/x 3 def`), and
`exit` leaves the innermost loop. Ghostscript lets a program open its own standard
streams, so the game is a normal filter.

- **Input.** `(%stdin) (r) file` opens standard input, and `readline` reads one event per
  line into a buffer, which `cvi` turns into an integer. Empty lines are skipped. At end
  of input `readline` returns `false` along with whatever partial line it read; the last
  line counts even without a newline, and then the game quits. The launcher passes
  stdin straight through, so there's no wrapping as in gnuplottris or m4tris.
- **Output.** `print` writes a string to stdout exactly as given, with no newline added. String
  literals take octal escapes, so `(\033[H)` is `ESC[H`, and box-drawing characters are just
  their UTF-8 bytes (`(\342\225\224)` is `╔`). Numbers go through `12 string cvs`. Every frame
  ends with `flush`, so interactive play sees each frame right away and there is no
  byte-level deviation.
- **`-dSAFER` stays on.** That's Ghostscript's default. Reading `%stdin` and writing
  `%stdout` are allowed under it, so `-dNOSAFER` isn't needed.
- **State.** The board is a 200-byte string. A new string is all zero bytes, which
  already means "empty", and a cell holds `piece + 1`. A full row is one with no zero byte:
  `(\000) search`. Rows that stay are copied down with `getinterval`/`putinterval`.
  Everything else is a global in `userdict`.
- **One cell iterator.** `cells` runs a procedure on the board index of each of the
  piece's cells, or on −1 for a cell off the board. The fit test, stamping the piece into the board and
  drawing all use it. Procedures are ordinary values, so the per-cell action is just an
  argument.
- **Events** are an array of procedures indexed by the event code. Each one returns whether
  to draw a frame.

Traps:

- **Integers are 64-bit here.** The PostScript manual says integers are 32-bit and
  overflow to reals, which would break Park–Miller (`s * 16807` reaches about 2^45).
  Ghostscript 10 uses 64-bit integers: `2147483646 16807 mul` is the exact
  `integertype` 36092757638322, and `mod` works on it. So the game multiplies directly,
  with no Schrage decomposition. On a 32-bit interpreter you'd need one.
- **`exit` only leaves the innermost loop,** not the procedure around it, and there is
  no `return`. So the fit test can't bail out of `cells` with a result; `fits` sets an
  `ok` flag that the callback clears.
- **`readline` at end of file** still returns the partial line under the `false`.
  Dropping it without checking would lose a final event that has no newline.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
printf '42\n5\n5\n9\n' | gs -q -dNODISPLAY -dBATCH postscripttris.ps
```

## Golfed version

[`postscripttris.min.ps`](postscripttris.min.ps) is the golfed twin of the engine: 1,501 bytes instead of 7,753 (81% smaller), with exactly the same output. `_tests/check.sh --min postscript` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to PostScript:

- **Binary tokens.** The file is mostly not text. PostScript Level 2 has a binary encoding: byte `0x92` followed by an index from the system name table is an operator name. So `getinterval`, `putinterval`, `exch`, `def`, `print` and the rest are 2 bytes each. Small integers are `0x88` plus one signed byte, larger ones `0x86` plus two bytes, and `2147483647` is 5 bytes. Binary tokens delimit themselves, so the spaces between them go too. Ghostscript accepts all of this from a program file under `-dSAFER`. The file was hand-golfed as text first (2,102 bytes) and then re-encoded token by token.
- **Tables in strings.** `get` on a string returns a byte, so the colours (`K`), the rotation-0 masks (`M`), the per-piece rotation size and the line-score table (divided by 20) are all raw-byte string literals. That's 1 byte per entry instead of 2–3 for binary numbers.
- **An 11-wide board with walls.** The board is 253 bytes: rows are 11 bytes, the 11th column is a wall, and there are wall rows below. The position `p = y*11 + x + 11` is one number, so left/right/down are `p±1` and `p+11`. A piece fits when the *sum* of the bytes under its cells is 0, with no bounds checks. A brute force over every reachable test position showed that this wrapping never gives a false fit, even with the padding row above the board left empty.
- **Rotations computed, not listed.** Only rotation 0 is stored. The iterator turns each cell r times with (x, y) → (n − y, x), where n is 3 for I and 2 for the rest. O can't be rotated that way, so rotating an O is skipped: its shape and position don't change either way.
- **Commit-or-undo moves.** `F` takes a candidate (pos, rot), stores it into `p`/`r` and tests it. `T` keeps the old pair on the stack and on failure calls `F` again with it, which puts it back.
- **Line clear by overlapping copy.** A full row `i` is removed with `b 11 b 0 i*11 getinterval putinterval`. That copies everything above it down one row in place. `getinterval` shares memory and Ghostscript's `putinterval` behaves like `memmove`. The top padding row, all empty, slides into row 1 as the new empty row. The empty board itself comes from a board full of walls, cleared by the same routine.
- **Output helpers.** `w` prints and resets, and `Q` prints `ESC[38;5;` followed by its argument, which gives the border (`A`/`B`), dim (`E`) and cell (`Y`) helpers. Rows 1–6 of the panel are one preview procedure (`//V`, inserted when the array is scanned). Box rows −1 and 4 have no bits, so they come out as the 14 blank columns for free. Every non-empty panel row starts with three spaces, so the frame prints them unless the row's procedure is empty (`length 0 gt`). `U` draws a `═` bar with the end-of-line of the line before it.
- **Events as a procedure array** indexed by the value `token` reads. `token` also skips blank lines, and it returns `false` at end of file. Left and right are `{-1 H}`/`{1 H}`, and hard drop is "step down until it locks". Codes outside 0–9 are ignored by running the lookup under `stopped`. `{get exec}stopped{pop pop}if` catches the `rangecheck` and drops the array and index the error leaves behind. That costs 12 bytes, less than a range test.
- **What PostScript refused:**
  - **Binary names:** `quit`, `true`, `false` and `==` aren't among the first 256 system names, so they can't be 2-byte names. `true`/`false` became binary booleans (`0x8D`), and `quit` stays text.
  - **Delimiters:** text names don't delimit themselves. A golfed `}forA(` reads as the name `forA`.
  - **No string concatenation:** every frame is printed in pieces.
  - **Signed bytes:** the 8-bit integer token is signed, so 128–255 cost 3 bytes. That's one more reason the tables are strings.
  - **`repeat`** consumes its operand once, so repeating a printed string needs `{dup print}repeat pop`.
  - **Negative bytes:** strings can't hold negative numbers, so the wall-kick list `[0 -1 1 -2 2]` stays an array.

Earlier games in the same tool are listed under [Prior art](../PRIOR-ART.md).
