# preprocessortris

A falling-block puzzle game written in the **C preprocessor**: nothing but `#define`,
`#if` and `#include`, run by GCC's `cpp` in traditional mode. No C is compiled.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/preprocessor/preprocessortris.sh | bash
# or, from a clone:
./preprocessor/preprocessortris.sh
```

Needs GCC's `cpp` (tested with GCC 15.2 and 13) and bash 4+. Clang's `cpp` won't do: the
engine depends on how GCC's `-traditional-cpp` treats spaces and macros.

Install: Debian/Ubuntu `apt install cpp` · Fedora `dnf install cpp` · macOS `brew install gcc`, then put its `cpp-NN` first on your `PATH` as `cpp` (Apple's `cpp` is Clang). Unverified on macOS.

## How it works

The preprocessor is not Turing complete on its own: it can't loop, and it can't change
a macro to a value it has just computed. It becomes Turing complete when its output is
fed back to it as input, which is how Herrmann's 2001 [IOCCC entry](https://www.ioccc.org/2001/herrmann1/index.html)
runs a Turing machine. preprocessortris works the same way: one `cpp` run per event,
with the state from the run before.

- **Input.** The launcher keeps the state in `state.h`, as function-like macros:
  `SEED()`, `CUR()`, `PX()`, `SCORE()`, `ROW0()` … `ROW19()` and so on. Each run is
  `cpp -P -traditional-cpp -include state.h -DEV=3 preprocessortris.h`. Before the
  first run, `state.h` holds only `START()`, the seed. Quit never reaches the engine;
  the launcher just stops.
- **Output.** Every output line starting with `@` is part of the next state:
  `@PY (PY() + 1)@TICK 0@ROW3 10000340000`, written back as `#define PY() (PY() + 1)`
  and so on. Everything else is the frame. Each directive leaves an empty line in the
  output, so the launcher drops empty lines (frame lines never are). When the game is
  over the engine prints the game-over frame and no state, and the launcher stops.
- **Printing a name.** The state is function-like macros because the engine has to
  print their names: `ROW3` stays plain text when no `(` follows it, while `ROW3()`
  expands to the row's value. The `()` can't be printed right after the name, since
  then it *would* be called; that's why the launcher writes the `#define NAME()` part.
- **Arithmetic** happens only in `#if`. Expressions are 64-bit, with `?:`, so `CELL(y, x)`
  is one expression that picks one of the 20 row macros and takes a decimal digit, and
  `FITS(mask, x, y)` tests all 16 bits of a piece's box with it. A new value is never
  computed, only printed: `@PY (PY() + 1)` writes the expression `(3 + 1)` into the next
  state. Values like that only grow until the next spawn writes plain numbers again.
- **The digit printer.** Rows, the seed, score, lines and level must be plain numbers, or
  their expressions would grow without end. The printer turns `V()` into digit macros
  `D10()` … `D0()` with one `#if` chain per digit. Each digit is drawn in the current
  "font": `F3()` is `3` for numbers, and the colour block of piece 3 when a board row
  is drawn. So a board row is the number `1d0d1…d9`, a leading 1 and then one digit per
  cell, and drawing it prints its digits.
- **Locks take three runs.** `PHASE()` says what comes next, and the launcher runs the
  engine again, without a new event, until it is 0: phase 0 plays the event and, if the
  piece locks, writes it into the board; phase 1 removes full rows and scores; phase 2
  takes the next piece and spawns it, or ends the game.
- **Traditional mode** (`-traditional-cpp`) is what makes the frame possible. Standard mode
  collapses every run of spaces to one; traditional mode keeps text exactly as written.
  It has its own quirks:
  - **No computed names.** Macro arguments aren't expanded before they are pasted, so
    the engine can't build `ROW3` from `ROW` and a computed 3. The 20 rows have a table
    of literal names (`RY` and `RN` per row), which runs the row code once for each.
  - **Merged words.** `nextRS()` is one name, and so is `75mW`, which is a number. `W(x)`
    expands to `x`, and its `)` ends the word before the next macro call.
  - **Lost spaces.** A macro body loses its leading and trailing spaces. `W()   text`
    and `W(  )` keep them.
  - **Skipped `#if` lines still expand.** GCC expands the macros on every `#if` line, even
    in a group it is skipping. So the engine includes itself for its repeated parts (the
    digit printer, a row, a frozen mask), and each include would expand every fit test
    in the main part on its way past. The launcher copies the parts block into a file of
    its own, `parts.h`, once at start-up and passes it as `PARTS`. Without it the engine
    includes itself; that gives the same output, only slower.
- **Frozen values.** A piece's mask, as an expression, is the whole 28-entry table. Where
  it is used many times, a 25-way `#if` chain turns it into a plain number first.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To play a few events by hand without the launcher:

```sh
echo '#define START() 42' > /tmp/state.h
cpp -P -traditional-cpp -include /tmp/state.h preprocessortris.h | grep '^@'
```

That prints the first state; the launcher would now write it into `state.h` and run again.
