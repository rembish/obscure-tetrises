# textris

A falling-block puzzle game written in **plain TeX**. It uses Knuth's original
`tex`, with no e-TeX, no LaTeX and no packages.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/tex/textris.sh | bash
# or, from a clone:
./tex/textris.sh
```

Needs `tex` (tested with TeX 3.141592653 from TeX Live 2023) and bash 4+.

Install: Debian/Ubuntu `apt install texlive-base` · Fedora `dnf install texlive-tex` · macOS `brew install --cask basictex` (it puts `tex` in `/Library/TeX/texbin`; open a new terminal afterwards).

## How it works

TeX is a typesetting language that happens to be Turing complete. textris never
typesets anything (no `.dvi` is written); it uses TeX only as a programming language.

- **Input.** `\read-1 to\ev` reads one line from the terminal without printing a
  prompt. With `\endlinechar=-1`, the line is exactly the event number. The game loop is a
  macro whose last token is itself (`\def\go{…\step\go}`), which TeX runs without
  growing its input stack.
- **Output.** `\immediate\write16{…}` writes a line to the terminal.
  - `tex -8bit` lets ESC and UTF-8 bytes out raw. The source writes ESC as `^^[`, TeX's
    own notation for character 27.
  - `max_print_line=100000` stops TeX breaking lines at 79 columns.
  - TeX's tokenizer collapses runs of spaces, so every space in the frame is `\S`, a macro
    that expands to a space character in category "other".
  - TeX writes the frame itself, so no decoder is involved.
- **Quiet.** TeX starts in `\batchmode`, which keeps its file-opening chatter off the
  terminal, switches to `\scrollmode` for the game, and returns to `\batchmode` before `\end`. Two
  things still get through: the banner line, and one empty line, because switching modes
  always ends the terminal line once more. The launcher drops both with `sed '1d;/^$/d'`;
  frame lines are never empty.
- **Arithmetic.** There are only `\count` registers with `\advance`, `\multiply` and
  `\divide`, which truncates. Modulo is built from those, and the Park–Miller step
  uses Schrage's trick, because counts are 32-bit.
- **The board** is 200 macros `\b0` … `\b199`, created and read with `\csname`. Every
  loop is a macro ending in `\expandafter\loopname\fi`.
- Plain TeX's own names had to be avoided. `\over` is a primitive (fractions) and `\line`
  is a plain macro, so the game uses `\gover` and `\Line`.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
(echo 42; echo 5; echo 9) | max_print_line=100000 tex -8bit -interaction=batchmode -output-directory=/tmp textris.tex
```

## Golfed version

[`textris.min.tex`](textris.min.tex) is the golfed twin of the engine: 2,563 bytes instead of 9,467 (73% smaller), with exactly the same output. `_tests/check.sh --min tex` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to TeX:

- **Short names:**
  - **`\let` aliases:** for `\advance`, `\divide`, `\multiply`, `\ifnum` and `\count`. The `by` keyword and `=` signs are dropped.
  - **Control symbols:** two-letter macros became `\!`, `\$`, `\&`, `\@` and so on, which need no space after them.
- **One counter allocator:** 41 `\newcount`s became one recursive `\countdef` loop numbering registers from 211.
- **Board in count registers:** the board lives in registers 10–209 instead of 200 csnames. The one-row offset means out-of-bounds reads still hit a valid register, which removes a guard.
- **Tables:**
  - **`\ifcase` tables:** for the piece masks, the colours and the line-clear scores.
  - **No powers-of-two table:** the mask is shifted instead.
- **One cell loop:** the per-cell action is an argument. It serves the collision test, writing the piece and erasing it.
- **Moves:** moves and rotations change X, Y and R directly and undo themselves on failure. Rotation tries its kicks as relative steps 0, −1, +2, −3, +4.
- **Line clear:** one unrolled copy also detects full rows. Rows above the top read as zero, so the zero-fill loop is gone.
- **Gravity:** the tick counter resets to the level instead of 0, so the gravity test is just `>10`.
- **Frame drawing:**
  - **Side panel:** one `\ifcase` over the row number.
  - **Line ends:** every line ends in `ESC[m ESC[K`, so the write macro appends it.
  - **Preview mask:** pre-shifted, so the empty box rows come out of the same loop as the piece rows.
- **Event loop:** one tail-recursive `\read` loop with an `\ifcase` dispatch.
- **What TeX refused:**
  - **`\+`:** it is `\outer` in plain TeX, so it can't be a macro name inside a `\def`.
  - **Recursion:** the recursive allocator needs `\expandafter`, or it takes the following `\fi` as its argument.
  - **Spaces:** a control symbol doesn't swallow the space after it, and a number followed by an `\ifnum` macro is evaluated early. So terminator spaces stay where order matters.
- **Faster:** about 40% faster than `textris.tex`.
