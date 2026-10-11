# bctris

A falling-block puzzle game written in [bc](https://www.gnu.org/software/bc/), the
arbitrary-precision calculator language.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/sedtris/master/bc/bctris.sh | bash
# or, from a clone:
./bc/bctris.sh
```

Needs GNU bc (1.07 or newer) and bash 4+.

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
