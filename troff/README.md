# trofftris

A falling-block puzzle game written in **troff**, the 1970s typesetter that still
formats every `man` page.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/troff/trofftris.sh | bash
# or, from a clone:
./troff/trofftris.sh
```

Needs GNU troff (groff, tested with 1.23.0) and bash 4+. If `man` works on your machine, you almost certainly have it.

Install: Debian/Ubuntu `apt install groff-base` · Fedora `dnf install groff-base` · macOS `brew install groff` (recent macOS uses mandoc for `man`).

## How it works

troff is a text formatter with a macro language bolted on: number registers
(`.nr`), string registers (`.ds`, `.as`), conditionals (`.if`, `.ie`/`.el`), loops
(`.while`, `.break`) and macros (`.de`). trofftris never formats a single page;
it runs with `-z` (discard formatted output) and only uses the language.

- **Input.** `.rd` reads text from stdin up to a blank line and executes it as troff
  input. The launcher sends each event as the request `.GO 3` followed by an empty
  line, and a `.while 1` loop keeps calling `.rd`. At end of input `.rd` spins forever,
  so the quit event (`9`, sent on `q`) ends the game with `.ex`.
- **State** is number registers: `b0` … `b199` for the board, with names built on
  the fly (`\n[b\n[k]]`), plus `x`, `y`, `r`, `score` and so on. Registers are 32-bit, so
  the Park–Miller step uses Schrage's trick, as m4tris does.
- **Output.** Every troff output request (`.tm`, `.write`) works in *copy mode*: it
  prints printable ASCII only, and escape characters or UTF-8 bytes in the source
  are thrown away as invalid input. So the frame is written with C-style escapes
  (`\033[1;38;5;51m██`) to stderr, one `.tm1` per line, and the launcher
  prints each line with `printf '%b'`. That is the whole decoder. troff also strips
  trailing spaces from request lines, so the two spaces that end a row use `\x20`.
- **Traps on the way:**
  - `.nr x -1` doesn't set `x` to -1; it *decrements* it. A value that starts with a sign
    is relative. So `.nr x \n[nx]` turns into a decrement as soon as `nx` is negative. Every
    interpolated value is therefore wrapped in parentheses: `.nr x (\n[nx])`.
  - Macros and strings share one namespace. A macro named `E` silently replaced the
    string `E` that held `\033[`, which is why the event macro is called `GO`.
  - Arithmetic runs strictly left to right, with no precedence: `(a*4)+b`, never `a*4+b` by habit.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
printf '.GO 42\n\n.GO 5\n\n.GO 9\n\n' | troff -z -Ww trofftris.tr 2>&1 >/dev/null | head -3
```

## Golfed version

[`trofftris.min.tr`](trofftris.min.tr) is the golfed twin of the engine: 2,887 bytes instead of 7,382 (60% smaller), with exactly the same output. `tests/check.sh --min troff` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to troff:

- **One table:** the masks, line-clear scores and colours sit in one list, loaded by a recursive macro (`.shift` plus `.X \\$@`). The same macro defines the colour-block strings, so a cell value points straight at its string. The masks are ordered so the preview reads one entry directly.
- **No powers-of-two table:** the bit test checks `C%2` and halves `C`. The loop ends when `C` reaches 0.
- **Left-to-right arithmetic:** groff has no operator precedence, so most parentheses go. The random step is one line, and the bounds check is `\nK>?(9-\nK)>9:(\nL>19):\n[b\nJ]`.
- **Merged macros:**
  - **Stamping a piece:** this is the collision macro with a 4th argument.
  - **Left, right and rotate:** one macro taking a rotation delta and a list of kick offsets.
  - **Hard drop:** a recursive macro over soft drop. Spawn ends with `u=0`, which stops the recursion.
- **Dispatch by name:** `.e\$1` calls macros `e0`–`e5`, and `.als e9 ex` quits. Unknown events have no macro, so nothing runs.
- **Init:** the first-call macro is `GO` itself and ends with `.rn S GO`, so the init flag goes away. Unset registers read as 0, so nothing is zeroed at start.
- **Line clear:** every row is copied down, and a full row is detected with the minimum operator `<?`.
- **Strings:**
  - **Shared escapes:** repeated escapes are shared strings, for example `\*T` for `ESC[38;5;`.
  - **Border:** the 20-wide border is built by doubling a string.
  - **Trailing spaces:** these survive in `.ds`/`.as`, so the `\x20` escapes went.
- **What troff refused:**
  - **Relative `.nr`:** `.nr I \nA+1` becomes a relative change when `A` is −1, so it's written `1+\nA`.
  - **Overflow:** squaring cell values to test a full row would overflow, hence the minimum.
  - **Strings can't dispatch:** a string can't serve as the event dispatcher, because its body isn't run as requests.
