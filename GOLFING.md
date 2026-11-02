# How the `.min` versions were golfed

Every engine has a golfed twin, `<name>.min.<ext>`, next to its readable source. The
rule: the golfed file must produce **exactly the same bytes** as the readable one.
`tests/check.sh --min` holds them to it. Each one is replayed against the reference on
bot games and fuzzed key streams. sedtris is compared against the original
`sedtris.sed` instead.

| Engine | Source (bytes) | Golfed (bytes) | Saved |
|---|---:|---:|---:|
| bc | 5,561 | 2,262 | 59% |
| CMake | 8,562 | 3,660 | 57% |
| dc | 5,365 | 2,138 | 60% |
| gnuplot | 6,887 | 2,122 | 69% |
| jq | 5,321 | 1,845 | 65% |
| m4 | 8,838 | 2,083 | 76% |
| make | 12,757 | 4,196 | 67% |
| sed | 8,357 | 4,250 | 49% |
| sendmail | 13,395 | 2,291 | 82% |
| TeX | 9,600 | 2,597 | 72% |
| troff | 7,382 | 2,887 | 60% |

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

- **bc**
  - All tables come out of big numbers with `/` and `%`. The only array left is the board.
  - Loops count down with `for(i=16;i--;)`, and the read sits in the loop condition:
    `while(!g&&(e=read())-9)`.
  - A bare `y++` statement prints its value, so increments are written `y+=1`.
- **CMake**
  - Cells are named `b<row><col>` rather than `b<index>`, which saves a `math()` per access.
  - Piece numbers are 1-based, so the `+1`s disappear.
  - `cmake_minimum_required` and the usage guard went.
  - The control rows come from one `foreach` over `"key|label"` strings.
  - **Not possible:** `foreach(RANGE -1)` still runs, so clearing top rows needs `while`.
    Frame strings contain `;`, so they can't be passed as macro arguments.
- **dc**
  - The colour macros print the string on top of the stack and reset the colour themselves.
  - The tables are loaded by stack-depth loops (`[z1-:Mz0<Z]dsZx`).
  - Events dispatch through an array of macros: `;#x`.
  - The main loop clears the stack (`c`) at every event, so nothing piles up during long games.
- **gnuplot**
  - `local` and `return 0` are gone. `do for` variables are already scoped, and a function
    block without `return` is fine as long as it's only assigned.
  - gnuplot has assignment inside expressions, the comma operator and short-circuiting
    `&&`, `||` and `?:`, so the collision test fits in one `if`.
  - The side panel is one array literal, filled with `sprintf` and spare arguments.
  - **Not possible:** there's no `+=`, and most keywords can't be abbreviated.
- **jq**
  - Moves are `first((move | select(fits)), .)`.
  - Soft drop is `(.y+=1 | select(F)) // lock`.
  - Quitting uses `try … error` instead of `label`/`break`.
  - Drawing is decided by a `select` in the `foreach` extractor.
- **m4**
  - `defn` copies give the builtins one-letter names.
  - The board is one string, rendered and cleared with `patsubst`.
  - One nth-argument macro replaces all the lookup tables.
  - **Not possible:** any single letter that appears as a word in the output (title letters,
    control keys, `m K H J` from the escape codes) can't be a macro name.
- **make**
  - The random 7-way pick joins the bits with weighted x-strings and removes groups of
    seven with `subst`.
  - The score is kept as reversed digits.
  - Events dispatch by variable name (`$(E$J)`).
  - Each frame is one `$(info)`.
  - **Not possible:** a recursive variable can't name itself, and restarts only happen when
    the state file is written from a recipe.
- **sed**
  - The frame is built with one-byte placeholders that are expanded by a few `s///g` at the end.
  - The side panel is one list consumed by a cursor loop.
  - The board, the current piece and the preview share one colour mapping.
  - Shifts are fixpoint loops.
- **sendmail**
  - The board is one macro, and rotation is a formula on rot-0 coordinates.
  - The preview reuses the board-drawing rulesets.
  - Frequent rule fragments are `D` macros expanded when the file is read; a search script
    kept only the ones that passed.
  - **Not possible:** `|` is not an operator character. Nested `$>` calls are slow, because
    `-bt` traces every one.
- **TeX**
  - `\let` aliases for the long primitives.
  - Control symbols (`\!`, `\$`, `\@`) as names, since they need no space after them.
  - One recursive `\countdef` allocator.
  - The board in count registers.
  - Tables as `\ifcase`.
  - Every line's `ESC[m ESC[K` tail is appended by the write macro.
  - **Not possible:** `\+` is `\outer`.
- **troff**
  - One recursive table loader for masks, scores and colours.
  - groff evaluates strictly left to right, which removes most parentheses.
  - `.e\$1` dispatches events to macros `e0`–`e9`.
  - The init macro renames itself away (`.rn S GO`).
  - **Not possible:** `.nr x \nA+1` becomes relative when `A` is negative, so it's written
    `1+\nA`.

## Caveats

- **`jqtris.min.jq` needs jq 1.7.** It relies on native `%` on large numbers and raw
  control characters in strings.
- **Speed:** measured on the 300-piece bot game:
  - **bc:** the golfed version does more big-number arithmetic and runs about 2.7× slower
    than the readable one. That's around 8 ms per frame, still far under the 100 ms tick.
  - **m4:** about 25% slower.
  - **dc and troff:** about the same speed.
  - **TeX, make and sendmail:** faster than their sources.
