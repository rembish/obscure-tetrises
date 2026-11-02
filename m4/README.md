# m4tris

A falling-block puzzle game written in [m4](https://www.gnu.org/software/m4/), the
macro processor that sits underneath autoconf and sendmail's configuration.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/m4/m4tris.sh | bash
# or, from a clone:
./m4/m4tris.sh
```

Needs GNU m4 and bash 4+. Tested with GNU m4 1.4.19.

## How it works

m4 does one thing: it reads text, and whenever it sees a macro name it replaces the
name with the macro's definition and reads the result again. There are no variables, only
macros that get redefined.

- **Input.** m4 only acts on macro calls, so the launcher passes each event number
  on as a call: `E(3)`. m4 expands `E(3)` as soon as the closing parenthesis arrives.
  That is the only thing the launcher adds; the game logic is all in
  [`m4tris.m4`](m4tris.m4).
- **State is macros.** `_b0` … `_b199` hold the board, and `_x`, `_y`, `_r`, `_score`
  and the rest are redefined with `define()` on every event. Loops are a
  self-calling `_for` macro. Conditions are `ifelse`, and arithmetic is `eval`.
- **Silence by default.** Everything runs inside `divert(-1)`, which throws output away,
  so whitespace and newlines from the definitions never reach the screen. The
  renderer switches to `divert(0)` just long enough to print one frame.
- **32-bit `eval`.** `s * 16807` overflows, so the Park–Miller step uses Schrage's
  trick: `16807 * (s mod 127773) - 2836 * (s div 127773)`, plus `2^31-1` if the result
  is negative.
- **Words join across expansions.** m4 rescans a macro's output together with the
  text that follows it. So `ESC[m` (ending in `m`) followed by a call to `_eol` reads
  as the single word `m_eol`, and neither part expands. Every expansion that ends
  in a letter therefore finishes with an empty quoted string `` `' ``, which breaks
  the word.
- Every internal macro starts with `_`, so no word in the frame text (`score`,
  `next`, …) can be expanded by accident.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
(echo 42; yes 0 | head -50; echo 5) | sed 's/.*/E(&)/' | m4 m4tris.m4 -
```

## Golfed version

[`m4tris.min.m4`](m4tris.min.m4) is the golfed twin of the engine: 2,083 bytes instead of 8,838 (76% smaller), with exactly the same output. `tests/check.sh --min m4` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to m4:

- **One-letter builtins:** a helper copies builtins under new names with `defn`, so `define`, `ifelse`, `eval`, `patsubst` and `substr` become single letters.
- **The board is one string:** rows like `<0000000000>` replace 200 cell macros. The `<` and `>` markers block every move off the sides, and reading past the end blocks moves off the bottom, so there are no bounds checks. Full rows are removed with one `patsubst(b,<[1-7]*>)`, and a recursive padder tops the board back up to 20 rows. The same padder builds the empty board at start.
- **Generated rotations:** only rotation 0 of each piece is stored, as 56 digits. A recursive `patsubst` builds the other rotations at load time.
- **One cell iterator:** a single macro runs a template over a piece's four cells. It is used for the fit check (the four cells joined and compared with `0000`), for drawing and for erasing.
- **One try-move macro:** it covers left, right, soft drop, hard drop, the rotation kicks (a variadic recursion over `0,-1,1,-2,2`) and the spawn check.
- **An nth-argument macro:** one macro replaces the colour, score and label tables.
- **Rendering with patsubst:** board rows and cells are drawn by `patsubst` over the board string.
- **No `divert(-1)`:** the file is effectively one line, and every event's expansion ends in `dnl`.
- **What m4 refused:**
  - **Joined words:** words join across expansion boundaries. `ESC[m` followed by `f` becomes `mf`, and `m4exit` ran into the next name. Each such spot needs a `` `' `` or `()` separator.
  - **Reserved letters:** a single letter that appears as a word in the output can't be a macro name. That covers the title letters, the control keys and `m K H J` from the escape codes.
  - **Regexes:** GNU m4 regexes have no `\{n\}` intervals.
  - **32-bit `eval`:** this overflows, so the random step keeps Schrage's method.
  - **Replacements:** `patsubst` turns `\(` into `(`.
- **Slower:** about 25% slower than `m4tris.m4`, still a few ms per frame.
