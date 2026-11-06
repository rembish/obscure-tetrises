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

Install: Debian/Ubuntu `apt install gnuplot-nox` (gnuplot 6 from Debian 13 and Ubuntu 24.04) · Fedora `dnf install gnuplot` · macOS `brew install gnuplot`.

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

## Golfed version

[`gnuplottris.min.gp`](gnuplottris.min.gp) is the golfed twin of the engine: 2,122 bytes instead of 6,887 (69% smaller), with exactly the same output. `_tests/check.sh --min gnuplot` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to gnuplot:

- **No `local`:** `do for` loop variables are already scoped (unset again after the loop), and the other temporaries don't collide.
- **No `return 0`:** a function block without `return` is fine when called as `d=$f()`.
- **Collision test in one expression:** gnuplot has assignment inside expressions, the `,` operator, and short-circuiting `&&`, `||` and `?:`. So the whole test is one `if`, which looks like `if(M[..]>>i&1&&((F=a+i%4)<0||F>9||(N=m+i/4)>19||b[N*10+F+1])){return 0}`. Chained `y=r=t=0` works too.
- **Flat event chain:** a gravity tick and a hard drop (after its `while`) both set `e=4`, so one soft-drop/lock branch serves all three. Left and right share one test using `x+2*e-3`, and the kick offsets come from `q/2*(q%2*2-1)`.
- **Fewer functions:** only collision, stamping the piece, spawning and `$step` remain. Init calls spawn twice instead of repeating the random-number code.
- **Side panel:**
  - **One array literal:** the side panel is built from one-line helpers such as `X(a)=B.a.R`.
  - **One `sprintf`:** the score and level rows hold `%d`, and every row goes through `sprintf(c[h+1],h>10?g/10+1:l,g)`. gnuplot ignores spare arguments.
- **Smaller tables:** the colour and score tables are `word()` lists; strings turn into numbers in arithmetic.
- **Flag as string:** the "already drew a frame" flag is the `ESC[J` string itself.
- **Line ends:** `K=E."K\n "` carries the next line's leading space.
- **What gnuplot refused:**
  - **Assignment:** there is no `+=`.
  - **Abbreviations:** only `set pr`/`pr` shorten; `ret`, `wh`, `do fo` and `fu` are rejected.
  - **Bare calls:** a `$f()` statement on its own doesn't parse.
  - **Strings:** `sprintf("%s",number)` errors, and so does `"x".5`.
  - **`!e`:** this errors on a non-integer.
  - **Return value:** a function block with no `return` counts as *true* inside `if()`, so `$step` keeps its explicit returns.
