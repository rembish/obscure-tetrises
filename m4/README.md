# m4tris

A falling-block puzzle game written in [m4](https://www.gnu.org/software/m4/), the
macro processor that sits underneath autoconf and sendmail's configuration.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/sedtris/master/m4/m4tris.sh | bash
# or, from a clone:
./m4/m4tris.sh
```

Needs GNU m4 and bash 4+.

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
