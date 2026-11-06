# dctris

A falling-block puzzle game written in [dc](https://en.wikipedia.org/wiki/Dc_(computer_program)),
the reverse-Polish desk calculator from 1970s Bell Labs Unix.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/dc/dctris.sh | bash
# or, from a clone:
./dc/dctris.sh
```

Needs GNU dc (it ships with GNU bc) and bash 4+. Tested with GNU dc 1.4.1.

Install: Debian/Ubuntu `apt install dc` · Fedora `dnf install bc` (it includes `dc`) · macOS `brew install bc`, then put `$(brew --prefix bc)/bin` first on your `PATH`.

## How it works

dc has a stack, registers with one-character names, an array attached to every
register, and strings that can be executed as macros. That's all the game uses.

- **Loops** are macros that call themselves. A conditional such as `lq 0<f` means
  "run register `f` if q > 0". dc compares the operands in reverse order of how they
  read, which makes every condition a small puzzle.
- **Main loop:** `?` reads one line from stdin and *executes* it, so the launcher sends
  plain numbers. At end of input `?` pushes nothing, so the loop pushes a `-1` sentinel
  first and checks whether it is still on top.
- **Board:** array `B[0..199]`. Pieces are 16-bit masks in array `M`, peeled off one
  bit at a time with `2%` and `2/`. Line clears copy the rows that aren't full
  downwards into the same array.
- **Escape codes:** a `[` can't appear unbalanced inside a dc string, so the
  `ESC [` prefix is printed as raw bytes with `27P91P`.
- **Side panel:** dc has no `if/else` and no `switch`. Each panel row is a macro
  stored in array `G`, and rendering just runs `G[row]`. The next-piece cells work the
  same way, through an array of two printers, "empty" and "block".
- About 60 registers are in use, so after the letters ran out the punctuation was
  pressed into service as register names (`(`, `{`, `~`, `|`, `@`, …).

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
(echo 42; yes 0 | head -50; echo 5) | DC_LINE_LENGTH=0 dc dctris.dc
```

## Golfed version

[`dctris.min.dc`](dctris.min.dc) is the golfed twin of the engine: 2,131 bytes instead of 5,357 (60% smaller), with exactly the same output. `_tests/check.sh --min dc` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to dc:

- **Self-contained colour macros:** `l<`, `l>` and `l/` print the string on top of the stack and reset the colour themselves. So `l<x[X]PlRx` became `[X]l<x`, used 28 times. Further macros cover the three-space indent (`l.x`), the controls rows (`l?x`) and the row counter (`l!x`).
- **Tables from the stack:** the mask and colour tables are pushed as plain numbers and stored by a stack-depth loop, `[z1-:Mz0<Z]dsZx`, instead of 35 separate `N:M` stores. Unset array cells are already 0, so zero entries are omitted.
- **Dispatch through an array:** the six event handlers live in array `#` and are called with `;#x`, instead of an `lz0=0…lz5=5` comparison chain. Each handler draws its own frame, so the redraw flag is gone.
- **Collision check:** the fit routine takes x and y from the stack, and the two bit loops share one body. Rotation restores the saved rotation itself after trying its kicks.
- **A clean stack:** the main loop starts every event with `c` (clear the stack), so values left behind by failed moves and unused kicks can't pile up during long games.
- **What dc refused:** an unbalanced `[` inside a string. ESC-`[` is still printed as `27P91P`.
