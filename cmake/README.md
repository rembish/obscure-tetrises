# cmaketris

A falling-block puzzle game written in **CMake**'s scripting language (`cmake -P`). It
uses no `project()` and no build, just the language.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cmake/cmaketris.sh | bash
# or, from a clone:
./cmake/cmaketris.sh
```

Needs CMake (tested with 3.28) and bash 4+.

Install: Debian/Ubuntu `apt install cmake` · Fedora `dnf install cmake` · macOS `brew install cmake`.

## How it works

Next to make, CMake is a luxury: `while()`, `foreach()`, `break()`, macros and
64-bit `math(EXPR)` with bit operators. The masks from the spec are tested with
`(mask >> bit) & 1`, and Park–Miller needs no tricks.

- **Output is exact.** `file(APPEND /dev/stdout "${frame}")` writes the bytes as
  given, with no added newline, and `string(ASCII 27 ESC)` makes the escape character.
  It's the only late engine with no byte-level allowance at all.
- **Input was the hard part.** CMake can't read from a pipe:
  - `file(READ)` and `file(STRINGS)` see a named pipe as an empty file and return at once.
    Reading `/dev/stdin` with `LIMIT` would lose events to stream buffering.
  - What works is `file(DOWNLOAD "file:///path/to/pipe" scratch.txt)`. It goes through the
    libcurl built into CMake, which opens the pipe, blocks until a writer arrives, and
    reads to end of file. Then `file(READ)` picks the event up from the scratch file.
  - Each download reads to end of file, so the launcher gives every event its own pipe
    (`events.0`, `events.1`, …), exactly as maketris does. It creates the next pipe before
    writing the current one.
- **State** is plain variables: `b_0` … `b_199` for the board, read back with nested
  expansion: `${cell_${b_${k}}}`.
- **One trap:** `if(NOT events)` is true for the list `0`, because `0` is a false
  constant in CMake. So the first tick looked like end of input. The loop checks
  `list(LENGTH)` instead.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own, use the launcher's pipe mode:

```sh
(echo 42; yes 0 | head -50; echo 5; echo 9) | ./cmaketris.sh --pipe
```

## Golfed version

[`cmaketris.min.cmake`](cmaketris.min.cmake) is the golfed twin of the engine: 3,654 bytes instead of 8,554 (57% smaller), with exactly the same output. `_tests/check.sh --min cmake` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to CMake:

- **Cell names:** the board cells are `b<row><col>` instead of `b<row*10+col>`. Columns are always one digit, so names never clash and no `math()` is needed for an index.
- **Off-board test:** one expression, `math(EXPR q "(${E}+10)/10-1|${G}/20")`, is non-zero off the board, then `if(q OR b${G}${E})`. That also replaces `if(NOT b… EQUAL 0)`.
- **Masks per piece:** the masks are stored as one list per piece, `M1`…`M7`, and piece numbers are 1-based. `list(GET M${F} ${r} …)` needs no arithmetic.
- **One shape macro:** the collision test and stamping a piece are the same macro. It writes the cells when it gets a 4th argument (`if(${ARGC} EQUAL 4)`).
- **Merged moves:**
  - **Left, right and rotate:** these share one kick loop.
  - **Hard drop:** `set(t -1)` followed by `while(t)` soft drop. The spawn after the lock resets `t` to 0, which ends the loop.
- **Fewer flags:**
  - `continue()` and `return()` replace the frame and quit flags.
  - `if(NOT DEFINED s)` replaces the init flag.
  - Game over is `math(EXPR l "1-${X}")`.
- **Full rows:** each row's values are joined into a string and tested with `if(k MATCHES 0)`. A `while` macro clears the top rows, and the same macro builds the empty board at start.
- **Fixed text:**
  - **Control rows:** one loop over `"← a|move left"`-style strings with `string(REPLACE | …)`, so no string containing `;` is passed as a macro argument.
  - **Box lines:** `string(REPEAT ═ 20)`.
- **Boilerplate gone:** no `cmake_minimum_required` (3.28 prints no warning without it) and no usage guard. Input is read with `file(STRINGS)` instead of `file(READ)` plus a regex.
- **What CMake refused:**
  - **Ranges:** `foreach(RANGE -1)` still loops over 0 and −1, and `RANGE -1 0 -1` is an error. Clearing a variable number of top rows needs `while`.
  - **`;` splits arguments:** frame strings contain `;` (`38;5;60m`), so they can't be passed as unquoted macro arguments; they would be split into lists.
  - **`if(NOT C)` for end of input:** this is false for a batch holding just the event `0`, so end of input is `C STREQUAL ""`.
