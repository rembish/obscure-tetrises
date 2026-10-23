# textris

A falling-block puzzle game written in **plain TeX**. It uses Knuth's original
`tex`, with no e-TeX, no LaTeX and no packages.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/tex/textris.sh | bash
# or, from a clone:
./tex/textris.sh
```

Needs `tex` (tested with TeX 3.141592653 from TeX Live 2023) and bash 4+.

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
  things still get through: the banner line, which the launcher drops, and the newline TeX
  prints on exit. `\write16` always ends its line, so each frame begins with the previous
  frame's `ESC[J`, and the final `ESC[J` is followed by that one extra newline. That is the
  same single-byte allowance maketris gets.
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
