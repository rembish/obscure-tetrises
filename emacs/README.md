# emacstris

A falling-block puzzle game written in **Emacs Lisp**. It runs headless, with
`emacs --batch`. No buffer, window, keymap or timer is involved; Emacs is used only as a
Lisp interpreter that reads lines on stdin and prints to stdout. The game is written from
scratch. It doesn't load, call or copy the `tetris.el` that ships with Emacs, and `-Q` keeps
it from loading anything else either.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/emacs/emacstris.sh | bash
# or, from a clone:
./emacs/emacstris.sh
```

Needs GNU Emacs (tested with 29.3) and bash 4+. No display or terminal is needed for
the engine itself. Frames are plain bytes on stdout.

Install: Debian/Ubuntu `apt install emacs-nox` · Fedora `dnf install emacs-nox` · macOS `brew install emacs`.

## How it works

The launcher runs `emacs --batch -Q -l emacstris.el` and pipes the seed and the event
numbers straight into it. The file starts with a `lexical-binding: t` cookie.

- **Input.** In batch mode, `read-from-minibuffer` doesn't open a minibuffer. It reads
  one line of stdin and returns it without the newline. At end of input it signals an
  error, so the engine wraps it in `condition-case` and treats the error as "stop". Don't
  use `(read t)` or `read-number`: in batch mode they print their prompt
  (`Lisp expression: `) to stdout, in the middle of the frames.
- **Output.** `princ` with the default `standard-output` writes to stdout. Each frame is
  built as one string and printed with one `princ`.
  - **Encoding:** the box characters come out as UTF-8 under `en_US.UTF-8`, `C.UTF-8` and
    even `LC_ALL=C`; the output is byte-identical in all three. `\e` in a string is the ESC
    byte.
  - **Flushing:** each frame reaches the pipe before Emacs reads the next line, with no
    explicit flush and no trailing newline. So interactive play updates on every key, and
    the output has no extra final byte (it is not on the `NL` list in `_tests/check.sh`).
- **State.** The board is a vector of 200 cells. The piece, position, score and the rest
  are `defvar` globals named `emacstris-…`. Fixnums are 62 bits wide, so the Park–Miller
  product `s * 16807` never overflows.
- **Exit.** `-l` loads the file and then batch mode exits by itself, after a quit (`9`),
  game over or end of input. Blank lines are skipped, because `string-to-number` would
  read them as `0`, a tick.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
printf '42\n5\n9\n' | emacs --batch -Q -l emacstris.el
```

## Golfed version

[`emacstris.min.el`](emacstris.min.el) is the golfed twin of the engine: 2,112 bytes instead of 11,797 (82% smaller), with exactly the same output. `_tests/check.sh --min emacs` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to Emacs Lisp: It was tested on Emacs 29.3 and uses features that are new in 29: `mapconcat` without a separator, and a preloaded `seq-filter`. The readable version uses neither.

- **No `defvar`:** the globals are created by one top-level `setq`.
  - **Why it matters:** `defvar` makes a symbol special everywhere. A `let` or `dotimes` variable with the same one-letter name would then rebind the global dynamically, even under lexical binding. That was the first golfing bug.
  - **What it buys:** undeclared globals stay unspecial, so all the one-letter names are free for locals too.
  - **The short cookie:** `;-*-lexical-binding:t-*-` is still honoured.
- **Reading numbers:** `(read-from-minibuffer "" nil nil t nil "7")` parses the line as Lisp, so events arrive as numbers. A blank line returns the default `7`, an unknown event. `ignore-errors` turns end of input into `nil`.
- **Masks in a string:**
  - **One character per mask:** all 28 rotation masks are the characters of one UTF-8 string (`ð䑄ༀ∢ffff…`, 50 bytes). `aref` returns a character, which is just its code.
  - **1-based pieces:** four padding characters at the front let pieces be numbered 1–7. A piece number is then also its board value and its index into the cell-string vector.
- **Board as a list of row lists:**
  - **Full rows:** a row is full when `(memq 0 row)` fails. `seq-filter` (preloaded in Emacs 29) drops full rows, and spawning pushes fresh rows until `(nth 19 B)` exists. The same loop builds the empty board at start.
  - **Free bounds:** `nth` past the end returns `nil`, which is never `eq` to 0, so only the left wall needs a test, `(< -1 a)`.
  - **Game over:** row 9 becomes `(8)`, and index 8 of the cell-string vector is the `GAME  OVER` bar.
- **One cell iterator:** `(I x y r &optional v)` tests the fit without `v` and writes `v` into the cells with it. It stamps the piece when locking, and it stamps and erases the falling piece around each frame.
- **One `format` per frame:**
  - **The template:** the whole frame is one template, built once at load time. Every board row is `%N$s`, the side panel uses `%24$s`… for the preview and `%1$d %2$d %d` for score, level and lines. So the call is `(apply 'format T S v l rows)`, and the board and preview rows come from the same `mapconcat`.
  - **Markup:** the template is written in a small markup that one `mapconcat` over its characters expands through a `plist-get` table: `{` border colour, `<` dim, `^` bold, `}` reset, `|` three spaces, newline → `ESC[K\n`.
- **Merged moves:**
  - **Left, right and rotate:** the offsets come from `(nth e '(() (-1) (1) (0 -1 1 -2 2)))`, the new rotation is `(% (+ r (/ e 3)) 4)`, and one `dolist` tries them.
  - **Ticks:** a falling tick becomes event 4. A tick that does nothing becomes 7, so no frame is printed.
  - **Drops:** soft and hard drop are one `while` that keeps going only for event 5. Gravity is `(< (+ k v) 11)`, because `k` is always at least 1 there.
- **Raw ESC bytes** in the strings, and no newlines between top-level forms.
- **What Emacs refused:**
  - **Bit tests:** there is no `logbitp`, and `cl-oddp` isn't loaded under `-Q`, so they cost `(> (logand m (ash 1 i)) 0)`.
  - **Variable names:** `t` can't be one (`setting-constant`), so the tick counter is `k`.
  - **Negative indices:** `(nth -1 row)` returns the first cell instead of failing, so the left wall needs its own check.
  - **Reading:** `(read t)` prints `Lisp expression: ` to stdout, so input stays on `read-from-minibuffer`.

Earlier games in the same tool are listed under [Prior art](../README.md#prior-art) in the main README.
