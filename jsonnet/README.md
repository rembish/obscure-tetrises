# jsonnettris

A falling-block puzzle game written in **Jsonnet**, the configuration language that turns
one program into one JSON document.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/jsonnet/jsonnettris.sh | bash
# or, from a clone:
./jsonnet/jsonnettris.sh
```

Needs Jsonnet (tested with the C++ `jsonnet` v0.20.0) and bash 4+.

Install: Debian/Ubuntu `apt install jsonnet` · Fedora `dnf install jsonnet` · macOS
`brew install jsonnet`. Unverified on Fedora and macOS, and with go-jsonnet.

## How it works

Jsonnet is pure and lazy. It has no input, no output, no state and no loops: a program is
an expression, evaluated once to a JSON value. So the game is a function from the old
state and one event to the new state and the frame, and Jsonnet runs once per event, the
way the C preprocessor and ghci do in their games:

```sh
jsonnet -S -m DIR --ext-str input=3 --ext-code state="$(<DIR/state.json)" jsonnettris.jsonnet
```

- **Input** is two external variables. `input` is the line (the seed first, then an event),
  and `state` is the state the run before wrote, as Jsonnet code (`null` the first time).
- **Output** is an object of two strings, and `-m` writes each to a file of its own:
  `frame`, the bytes to print (empty for a tick that moved nothing), and `state.json`, the
  next state, empty at game over. `-S` writes strings raw instead of as JSON.
- **The state** is a plain object: seed, pieces, position, ticks, score, lines, and the board
  as 20 numbers, one per row, with ten octal digits (0 empty, or piece + 1). The
  launcher only keeps it and hands it back.
- **Loops are recursion and comprehensions:** a hard drop calls itself until the piece
  doesn't fit, and clearing rows keeps those that aren't full,
  `[row for row in stamp(g) if !full(row)]`.
- **Numbers are doubles,** exact up to 2^53, so Park–Miller's `s * 16807` (below 2^46) needs
  no tricks; `std.floor` makes the integer divisions.

### Traps

- **`-m` adds a newline** after each file's string, so the launcher reads the frame with
  `$(<…)`, which drops it, and prints it with one newline of its own.
- **A run costs about 25 ms before it does anything:** `jsonnet -e 1` alone takes that
  long with the C++ `jsonnet`. An event takes about 40 ms in all,
  which keeps up with 10 ticks a second, but the bot game in the tests (1,955 frames) takes
  over three minutes. Working the piece cells out from the masks on every run, and a
  board of 200 numbers to parse and write, both made it slower still; the cells are now a
  table, and the board is 20 numbers. Writing the state by hand instead of with
  `std.manifestJsonMinified` saved time in isolation but nothing measurable in the tests,
  so it wasn't kept.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To play a few events by hand:

```sh
jsonnet -S -m . --ext-str input=42 --ext-code state=null jsonnettris.jsonnet
cat frame
jsonnet -S -m . --ext-str input=5 --ext-code state="$(<state.json)" jsonnettris.jsonnet
```

## Golfed version

[`jsonnettris.min.jsonnet`](jsonnettris.min.jsonnet) is the golfed twin of the engine: 3,370 bytes instead of 8,292 (59% smaller), with exactly the same output. `_tests/check.sh --min jsonnet` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to Jsonnet:

- **One `local` with every binding:** functions and values, separated by commas, and the result after the `;`.
- **Shorter standard library:** `std.pow`, `std.floor`, `std.range` and `std.join` are bound to one letter each.
- **The preview from the cell table:** a preview cell is on if `[x, y]` is in the piece's cells (`std.member`), so the masks aren't needed at all.
- **Gravity in one comparison:** `g.t+F(g.lines/10)>8`.
- **"show" as a hidden field:** `w`, added with `+{w:1}` and dropped from the state by `g{w::0}`.

