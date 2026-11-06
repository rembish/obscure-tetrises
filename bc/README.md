# bctris

A falling-block puzzle game written in [bc](https://www.gnu.org/software/bc/), the
arbitrary-precision calculator language.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/bc/bctris.sh | bash
# or, from a clone:
./bc/bctris.sh
```

Needs GNU bc, which provides `void` functions, `halt` and `read()`, and bash 4+. Tested with GNU bc 1.07.1.

Install: Debian/Ubuntu `apt install bc` · Fedora `dnf install bc` · macOS `brew install bc`, then put `$(brew --prefix bc)/bin` first on your `PATH`.

## How it works

bc is a calculator with a C-like language on top: functions, `if`, `while`, `for`,
arrays and local variables. What it lacks is everything a game usually leans on:

- **No strings.** Text exists only as literals inside `print`. Variables, arrays and
  return values are all numbers, so the board is `b[0..199]`, pieces are 16-bit
  masks in `m[]`, and every panel row is a run of `if (row == …) print …` statements.
- **No bit operations.** A mask bit is `(mask / 2 ^ i) % 2`.
- **No ESC.** bc's `print` understands `\n`, `\t` and a few others, but not `\e`.
  So the escape sequences in [`bctris.bc`](bctris.bc) contain raw ESC bytes; `cat -v` shows
  them as `^[`.
- **Input** comes from `read()`, which reads one number per call. GNU bc's `read()`
  never returns at end of input; it spins forever. That's why the shared protocol has
  an explicit quit event, `9`, which the launcher sends when you press `q`.
- `define void` functions (a GNU extension) keep bc from printing every return value.
  `halt` ends the program; `quit` would stop bc as soon as it was *parsed*.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
(echo 42; yes 0 | head -50; echo 5; echo 9) | BC_LINE_LENGTH=0 bc -q bctris.bc
```

## Golfed version

[`bctris.min.bc`](bctris.min.bc) is the golfed twin of the engine: 2,259 bytes instead of 5,558 (59% smaller), with exactly the same output. `_tests/check.sh --min bc` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to bc:

- **Tables in big numbers.**
  - **Piece masks:** all 28 piece masks are one base-2¹⁶ literal, read with `t(a,i)=P/2^(16*a+i)%2`.
  - **Colours:** `208033196046135226051/1000^v%1000`.
  - **Scores:** `120030010004000/1000^e%1000*10`.
  - **What's left:** the board is the only array.
- **No kick table:** the rotation loop walks 0, −1, 1, −2, 2 with `for(j=0;j>-3;j=-j-(j>=0))`.
- **Fewer functions:** most small functions, `scale=0` and most `auto`s are gone. The escapes are inlined into merged `print` strings, and the `═`/`─` runs are loops.
- **Side panel:** the panel is a flat list of `if(r==N)` statements. A shared flag `i=(r-8)*(r-12)` adds the indent and the trailing reset.
- **Line clear:** every row is copied down, and a row is kept only if the product of its cells is 0.
- **Shorter idioms:**
  - Count-down loops: `for(i=16;i--;)`.
  - `+=` and chained assignment: `y=h=t=0`.
  - The read inside the loop condition: `while(!g&&(e=read())-9)`.
  - The tick becomes a soft-drop event (`e=4`), and hard drop falls through to the same code.
- **What bc refused:**
  - **Statements print:** a bare `y++` prints its value into the output, so increments are `y+=1`.
  - **`halt` stays:** without it, bc would go on to execute the leftover input.
