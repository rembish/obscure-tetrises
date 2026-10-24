# gnuplottris

A falling-block puzzle game written in **gnuplot**'s command language. Nothing is plotted;
it uses only the scripting language.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/gnuplot/gnuplottris.sh | bash
# or, from a clone:
./gnuplot/gnuplottris.sh
```

Needs gnuplot 6 (for function blocks; tested with 6.0) and bash 4+. No display is
needed: the launcher sets `GNUTERM=dumb`, and the game only prints text.

## How it works

gnuplot 6 grew a real scripting language. Function blocks
(`function $name(args) << EOD … EOD`) can hold `local` variables, `do for` and `while`
loops, `if`/`else`, `break` and `return`. Arrays (`array b[200]`) start at index 1.
Integers are 64-bit, with C's `% & >> <<`. Strings concatenate with `.`.

- **Input.** After loading the game, `gnuplot gnuplottris.gp -` keeps reading
  commands from stdin. The launcher sends each event as the statement
  `if ($step(3)) { exit }`. `$step` returns 1 when the game is over or you quit,
  because `exit` inside a function block only leaves the function, not gnuplot.
- **Output.** `set print "-"` sends `print` to stdout, and `"\033["` gives ESC inside
  double quotes. `print` always ends with a newline, so each frame is built as one
  string that starts with the previous frame's `ESC[J`, and `print` adds the newline
  after the last row. The very last `ESC[J` comes with one extra newline, the same
  single-byte allowance as maketris and textris.
- **State.** The board is an array of 200 numbers; the piece, position, score and the rest are
  globals. Every helper is a function block whose loop counters are declared
  `local`, so a loop inside `$fits` can't clobber the caller's.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
printf 'if ($step(42)) { exit }\nif ($step(5)) { exit }\nif ($step(9)) { exit }\n' | gnuplot gnuplottris.gp -
```
