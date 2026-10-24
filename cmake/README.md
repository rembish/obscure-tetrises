# cmaketris

A falling-block puzzle game written in **CMake**'s scripting language (`cmake -P`). It
uses no `project()` and no build, just the language.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cmake/cmaketris.sh | bash
# or, from a clone:
./cmake/cmaketris.sh
```

Needs CMake (tested with 3.28) and bash 4+.

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
