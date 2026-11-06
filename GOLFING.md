# How the `.min` versions were golfed

Every engine has a golfed twin, `<name>.min.<ext>`, next to its readable source. The
rule: the golfed file must produce **exactly the same bytes** as the readable one.
`tests/check.sh --min` holds them to it. Each one is replayed against the reference on
bot games and fuzzed key streams. sedtris is compared against the original
`sedtris.sed` instead.

| Engine | Source (bytes) | Golfed (bytes) | Saved |
|---|---:|---:|---:|
| awk | 6,966 | 1,717 | 75% |
| bc | 5,561 | 2,262 | 59% |
| CMake | 8,562 | 3,660 | 57% |
| C++ templates | 21,530 | 3,980 | 82% |
| dc | 5,365 | 2,138 | 60% |
| Emacs Lisp | 11,797 | 2,112 | 82% |
| gnuplot | 6,887 | 2,122 | 69% |
| jq | 5,321 | 1,845 | 65% |
| m4 | 8,838 | 2,083 | 76% |
| make | 12,757 | 4,196 | 67% |
| PostScript | 7,753 | 1,501 | 80% |
| sed | 8,357 | 4,250 | 49% |
| sendmail | 13,395 | 2,291 | 82% |
| SQLite | 11,993 | 2,616 | 78% |
| TeX | 9,600 | 2,597 | 72% |
| troff | 7,382 | 2,887 | 60% |
| Vim script | 7,806 | 1,851 | 76% |

The golfing came in two passes:

1. **Mechanical.** Comments and whitespace were stripped and identifiers shortened, using
   throwaway per-language scripts. jq and bc were rewritten by hand.
2. **Structural.** Each file was rewritten by hand: tables computed instead of listed,
   routines merged, and repeated text reused. Most of the savings came from this pass.

The `.min` files are not regenerated from the sources. If you change an engine, you have
to golf its `.min` file again by hand.

## Techniques that work almost everywhere

- **Raw ESC bytes.** Most of the files embed the escape character literally in strings
  instead of `\033`, `^^[` or `\u001b`. That saves 3–5 bytes on every colour code.
- **Reuse repeated text.** Every frame repeats `ESC[38;5;…m`, `ESC[m` and `ESC[K` and the
  three-space panel indent. The fixed text and the box-drawing runs are factored into
  variables, macros or helpers (`B("│")`, `\*V`, `$v`). Runs like `═` × 20 are built by
  repetition (`"═"*20`, `string(REPEAT)`, doubling a troff string).
- **Generate tables instead of listing them.**
  - **Piece rotations:** several engines store only rotation 0 of each piece and compute
    the other three when the program loads, with (x,y) → (n−y, x).
  - **Small tables in one number:**
    - bc packs all 28 piece masks into a single base-2¹⁶ number.
    - bc packs the colours as 3-digit groups of one integer.
    - jq turns the pieces into a 112-letter string, one letter per cell.
  - **Wall kicks:** the kick list 0, −1, 1, −2, 2 becomes a formula or a short loop,
    e.g. `j=-j-(j>=0)` in bc, or relative steps 0, −1, +2, −3, +4 in TeX.
- **One cell iterator for everything.** The fit test, stamping a piece into the board and
  erasing it are the same loop over the piece's cells. Only the action per cell differs, so
  most engines ended up with one routine and a flag or argument.
- **Merged moves.**
  - **Left, right and rotate** are one "try with these offsets" routine.
  - **The gravity tick** turns into a soft drop.
  - **Hard drop** repeats soft drop until the piece locks. Spawning resets the counter that
    ends that loop.
- **Bounds for free.**
  - **Sentinels on the board:** the board gets out-of-range sentinels, so the edge checks
    vanish. m4 wraps each row in `<…>` and TeX keeps a spare row of registers above it.
  - **Arithmetic for the rest:** what's left is folded into one expression, such as
    `a*(a-9)<1` for 0 ≤ a ≤ 9 in jq, or CMake's `(x+10)/10-1|y/20`, which is non-zero
    off the board.
- **Line clears without counting.** A row is full when the product (or minimum) of its
  cells is non-zero. Rows are copied down unconditionally, and the destination only
  advances for rows that stay. m4 and jq delete full rows with one regex or `select` and
  pad the board back to 20 rows.
- **Stored instead of recomputed.** Level, the first-frame flag and the game-over flag are
  kept in a form the output can use directly. In gnuplot the "already drew a frame" flag
  *is* the `ESC[J` string to print.

## Per language

The tricks specific to one language, and what each language refused, are in that
engine's README, under "Golfed version":

- [awk](awk/README.md#golfed-version)
- [bc](bc/README.md#golfed-version)
- [CMake](cmake/README.md#golfed-version)
- [C++ templates](cpp/README.md#golfed-version)
- [dc](dc/README.md#golfed-version)
- [Emacs Lisp](emacs/README.md#golfed-version)
- [gnuplot](gnuplot/README.md#golfed-version)
- [jq](jq/README.md#golfed-version)
- [m4](m4/README.md#golfed-version)
- [make](make/README.md#golfed-version)
- [PostScript](postscript/README.md#golfed-version)
- [sed](sed/README.md#golfed-version)
- [sendmail](sendmail/README.md#golfed-version)
- [SQLite](sqlite/README.md#golfed-version)
- [TeX](tex/README.md#golfed-version)
- [troff](troff/README.md#golfed-version)
- [Vim script](vim/README.md#golfed-version)

## Caveats

- **`jqtris.min.jq` needs jq 1.7.** It relies on native `%` on large numbers and raw
  control characters in strings.
- **`emacstris.min.el` needs Emacs 29.** It relies on `mapconcat` without a separator and
  a preloaded `seq-filter`.
- **`cpptris.min.cpp` needs g++.** Like the readable file, it relies on GNU extensions
  (the string literal operator template, `\e`), and adds zero-length arrays, `?:` with
  the middle left out and `__integer_pack`. Clang refuses it.
- **`postscripttris.min.ps` is a binary file.** It uses Ghostscript's binary tokens: one
  byte plus an index into the system-name table per operator, which needs no spaces around
  it. git and GitHub show it as binary.
- **Speed:** measured on the 300-piece bot game:
  - **bc:** the golfed version does more big-number arithmetic and runs about 2.7× slower
    than the readable one. That's around 8 ms per frame, still far under the 100 ms tick.
  - **m4:** about 25% slower.
  - **dc and troff:** about the same speed.
  - **TeX, make and sendmail:** faster than their sources.
