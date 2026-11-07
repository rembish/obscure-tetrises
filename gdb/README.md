# gdbtris

A falling-block puzzle game written in **gdb's command language**, the one for scripting
breakpoints, run by `gdb` with no program to debug.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/gdb/gdbtris.sh | bash
# or, from a clone:
./gdb/gdbtris.sh
```

Needs GDB (tested with 17.1) and bash 4+. The launcher runs `gdb -q -nx -x gdbtris.gdb`.

Install: Debian/Ubuntu `apt install gdb` · Fedora `dnf install gdb` · macOS `brew install gdb`
(Intel Macs only; Homebrew's GDB doesn't support Apple Silicon). Unverified on Fedora and macOS.

## How it works

Without a program, gdb still has its whole command language: convenience variables
(`$name`), C expressions on them, `while` and `if`, `printf`, and user-defined commands
(`define … end`). That's enough for the game.

- **Input.** gdb reads commands on stdin after it has run the engine file (`-x`). The
  launcher turns each input line into one: `seed 42` for the first, then `event 3`, the way
  m4tris gets `E(3)`. 9 (quit) stops the launcher; at game over the engine runs `quit` itself.
- **Output** is `printf`. gdb's `printf` knows `\n` but not `\033` or `\e` in a format, so every
  escape sequence is `%c` with the argument 27. The box-drawing characters go through as
  bytes.
- **State** is convenience variables. They hold integers of C's types (`(long long) $arg0`
  makes the seed 64-bit, so `s * 16807` can't overflow) and arrays: `set $masks = {240, 17476, …}`. An
  element of an array in a convenience variable can be assigned (`set $board[$i] = 5`), and
  a whole array copied (`set $grid = $board`).
- **Commands take words, not values.** A user-defined command gets its arguments as text,
  pasted into its body as `$arg0`, split at spaces and returning nothing. So the commands
  work on globals: the caller sets `$tx`, `$ty` and `$tr`, runs `fits`, and reads `$ok`.
  Where an argument is passed, it has no spaces (`cell $next+1`).
- **Settings.** `set prompt` with nothing after it turns off the `(gdb) ` that gdb would
  print before each command it reads; `pagination`, `height` and `width` keep it from
  stopping or wrapping.

### Traps

- **No array of a given size.** gdb can only make an array from a literal, so the empty
  board is written out as 200 zeros, and a new game copies it.
- **An array literal has type `int[]`.** That's fine for the board, but the seed has to be a
  `long long` from the start, or the multiplication would overflow in 32 bits. `long` was
  not enough on x86-64 in CI, though it is 64 bits on ARM: most likely, with no program
  loaded, x86 gdb starts in a 32-bit i386 architecture. `long long` is 64 bits in all.
- **Some names are registers.** On x86, `$cx` is the CX register, and with no program
  running, reading it fails with "No registers." So no variable is named like one: the
  cell being tested is `$px`, `$py`.
- **Speed.** A frame takes about 20 ms, printing 200 cells one `printf` at a time; the
  big bot game in the tests (1,955 frames) takes about 40 s.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To play a few events by hand:

```sh
printf 'seed 42\nevent 5\n' | gdb -q -nx -x gdbtris.gdb
```

## Golfed version

[`gdbtris.min.gdb`](gdbtris.min.gdb) is the golfed twin of the engine: 3,255 bytes instead of 8,993 (64% smaller), with exactly the same output. `_tests/check.sh --min gdb` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to gdb:

- **Raw ESC in the formats:** `printf` can't spell ESC as an escape, but the byte itself in the format string goes through. That removes every `%c` and `27`.
- **A row is one int:** ten 3-bit cells. The empty board is 20 zeros instead of 200, a cell is `$b[$y]>>3*$x&7`, and writing a piece is `|=`.
- **C operators:** gdb's expressions have `|=`, `&=`, `+=` and post-increment, so `set $b[$j--]=$b[$f]` copies a row and moves on. The key names and actions of the panel come from one `?:` chain each.
- **Gravity in one comparison:** a tick makes the piece fall when `$t+$l/10>9`.
- **Watch the pasted arguments:** an argument is pasted into the command as text, so `$C[$arg0-1]` with the argument `$e[$j]>>3*$i&7` became `…&7-1`, which is `&6`. It needs `($arg0)`.
- **`||` doesn't save the right side here:** with the board as shifts, the fit test warned about a negative shift count for cells left of the board, so the bounds and the cell are two `if`s.

