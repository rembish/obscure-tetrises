# sedtris

A falling-block puzzle game written in **GNU sed**. One sed script reads events as input
lines and prints a frame after each one, and does all the game logic itself: the
Park–Miller random numbers, gravity, rotation with wall kicks, line clears, score and
level. sed has no numbers, so everything is done by rewriting strings.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sed/sedtris.sh | bash
# or, from a clone:
./sed/sedtris.sh
```

Needs GNU sed (tested with 4.9) and bash 4+. The launcher runs
`LC_ALL=C sed -n -E -u -f sedtris.sed`.

## How it works

sed is built for streams. It reads a line, runs the script on it, and goes on to the next
line, so every event is one cycle. The game lives in the hold space between cycles. A cycle
appends it to the event with `G`, plays the move, saves the new game with `h`, and turns the
pattern space into the frame.

- **Input.** One number per line, as `../SPEC.md` describes. Line 1 is the seed, `9`
  branches to the end, and anything other than `0`–`5` is dropped with `d`. `-u` makes
  sed read its input line by line instead of waiting for a full buffer.
- **Output.** `p` prints the frame, and `-u` flushes it at once. ESC comes from `\x1b` in
  the replacement text, and the box-drawing characters are plain UTF-8 in the script.
- **State.** The hold space holds two lines. The first is the state:
  `Ta;J;Cxxxx;Gxxxxxxxxxx;S,,;L;Vx;R0000…0101`. That is the current piece and its
  rotation (`a`–`d`), the next piece, the gravity countdown and interval, score, lines,
  level and the 31-bit seed. The second line is the board: rows of ten cells and six `#`
  walls, with a wall row on top and a floor below. `.` is empty, an upper-case letter is a
  locked cell, and the falling piece is always drawn into the board in lower case. `@`
  marks the corner of its 4×4 box.
- **Shapes are regexes.** One row down is 16 characters further along, so each piece and
  rotation is one substitution that finds four empty cells at fixed gaps after the `@`
  and writes the piece into them. T in rotation 0 is `s/@(.)\.(.{14})\.\.\./@\1t\2ttt/`.
  If the substitution happened, the piece fits. A wall character in one of those places
  makes the match fail, so bounds checks come for free. Every move does the same three
  steps:
  - `y/iotszjl/......./` erases the falling piece;
  - the `@` moves;
  - the shape substitution runs.

  If the shape doesn't fit, `g` takes the old game back from the hold space.
- **Numbers.**
  - **Counters** are unary runs of `x`.
  - **Score and lines** are "column unary": one run of `x` per decimal digit, so 1203 is
    `x,xx,,xxx`. Adding means inserting `x`s into a column. A loop then carries ten `x`s
    to the column on the left. For the frame, each run becomes its digit.
  - **The seed** goes from decimal to binary once, by halving it 31 times. Each halving
    marks the odd digits, halves every digit with one `y`, and adds 5 after each mark.
  - **Park–Miller:** 16807 is 7⁵, and modulo 2³¹−1 doubling is a rotation of the 31
    bits, while negation is the bitwise complement. So `7s = 8s − s` is "rotate by three and add
    the complement", using eight rules for a bit-serial adder with end-around carry.
    Five rounds of that give `s * 16807 mod (2^31 - 1)`.
  - **`s mod 7`** is the sum of the octal digits mod 7, done by grouping the bits in threes.

### Traps

- **`p` always adds a newline.** The frame has to end with `ESC[J` and no newline. So
  every frame after the first starts with the previous frame's `ESC[J`, and the newline
  from `p` ends the last row. On quit, game over or end of input, the last `ESC[J` is
  printed on its own. That one comes with a newline, the same single extra byte as
  maketris, gnuplottris and textris: the `nl` option in `tests/check.sh`. sed only leaves
  out the newline when the input line it read had none, and it can't make that happen.
- **No subroutines.** The shape substitutions are needed after every kind of move, and
  sed can only branch, not return. So the caller puts a one-character return code in
  front of the state (`M` for a move, `1`–`5` for the kick attempts, `D`, `H` or `S`
  for a step down, a hard drop or a spawn). After the shapes, a dispatch on that code
  jumps back.
- **The `t` flag is sticky.** It remembers any substitution since the last input line or
  the last `t`, and `b` doesn't clear it. The shape routine starts with a `t` to the next
  line, which clears the flag, so that afterwards it means "this piece fits".
- **`y` works on the whole pattern space.** So the letters it rewrites (`iotszjl`, `abcd`,
  digits while halving) must not appear anywhere else, and the state uses only upper-case
  labels, `x`, commas and `0`/`1`. Some work, like the random numbers, is done on a pattern
  space with everything else parked in the hold space.
- **`s//` reuses the last regex used, addresses included.** `/full row/{s///…}` deletes
  exactly what the address found, which is handy. A plain `s//` after an unrelated address
  is a bug.
- **The frame is built in an order.** All the side-panel text is lower case, and the title
  `S E D T R I S` and the `GAME  OVER` banner have upper-case piece letters in them. So the
  order is:
  1. the falling piece becomes upper case;
  2. the panel text goes in at the row ends, one `s/|/…/` per row;
  3. the cells are coloured;
  4. the banner and the title go on last.
- **Extended regexes.** With `-E`, literal `|`, `+` and `?` need a backslash, and a lone
  `{` is an error ("Invalid preceding regular expression").
- **`LC_ALL=C`.** The board is ASCII, so the game also runs in a UTF-8 locale and gives
  the same bytes. In the C locale `.` is a byte, and that is faster.
- **Speed:**
  - **Typical event:** about 0.4 ms, measured on the 300-piece bot game in `tests/check.sh`.
  - **A hard drop:** runs the shape routine up to twenty times.
  - **A lock:** adds the five rounds of bit-serial multiplication, a few milliseconds.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
printf '42\n5\n9\n' | LC_ALL=C sed -n -E -u -f sedtris.sed
```

## Golfed version

[`sedtris.min.sed`](sedtris.min.sed) is the golfed twin of the engine: 2,985 bytes instead of 14,601 (80% smaller), with exactly the same output. `tests/check.sh --min sed` replays it against the reference. A mechanical pass (comments, whitespace, one-letter labels) got it to 7,268 bytes, and the rest came from restructuring by hand. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to sed:

- **Piece code next to the marker:** the falling piece's letter and rotation sit right before the `@` (`Ta@`). So each shape substitution finds its own piece with no address in front: `s/(Ta@.)-(.{14})---/\1t\2ttt/`.
  - **Shared shapes:** I, S and Z in rotations 2 and 3 are rotations 0 and 1 shifted by one row or one column, so they share a line through alternation: `s/(I(a@|c@.{16}).{16})----/\1iiii/`.
  - **No state field for the piece:** the state no longer stores the current piece.
- **Bounds from the string end:**
  - **No floor:** the board stops after row 19. A cell below it runs off the end of the string, so the regex fails just as it does on a wall.
  - **No top row:** each row is written walls first (`######----------`), so the walls before row 0 are all the room the piece needs on the left.
- **Kicks as a walk:** a rotation gets the return code `3uvvuuuvvvv`. Each failed try takes one letter off and steps the box left (`u`) or right (`v`). The spots visited are 0, −1, 0, +1, 0, −1, −2, −1, 0, +1, +2. A repeated spot failed before, so the first fit is still the spec's 0, −1, +1, −2, +2.
  - **Moves are kicks too:** left and right are the codes `u` and `v`, so moves and rotation share one return handler.
- **Gravity without a counter:** each tick adds a `y` after the level's `x`s. The piece falls when `/;V[xy]{11}/` matches, which is exactly every `max(1, 11 - level)` ticks. A spawn deletes the `y`s.
- **Random numbers:**
  - **Windowed adder:** `7s` is computed from `s` alone. The adder keeps the last three bits it read, which are `8s`'s bits for the current column, so there are no operands to line up.
  - **Doubled string:** the adder runs over `ss`, and the top half of the result is the end-around sum. No increment is needed afterwards.
  - **Six rules:** the carry and the window bit can be swapped, so the 8 adder rules fold into 6 with `(0,1|1,0)`.
  - **`s mod 7` by Horner:** for each bit, `y/IOTSZJL/ITZLOSJ/` doubles the residue, which is kept as the piece letter itself, and `y/IOTSZJL/OTSZJLI/` adds the bit. The letter left at the end is the piece.
- **Init folded into the draw:**
  - **Placeholder piece:** the start-up state has `?` for the next piece, and the random draw doubles as the spawn.
  - **Second draw:** the first pass spawns a `?a@` piece that the second draw deletes again.
- **Score from a multiplier string:** `+` marks for the cleared rows become a string of `n`s: 4, 10, 30 or 120, with each `m` standing for ten `n`s. Each `n` pastes the level's run of `x`s into the tens column, and the carry loop sorts out the rest. The carry loop is shared with the frame, which uses it to turn the level into decimal.
- **The frame from a template:**
  - **One substitution:** a single 296-byte substitution pulls the preview, score, level and lines into a 20-segment template.
  - **One loop:** the loop `` s/#+(.*>)([^`]*)`/]\2…\1/ `` then moves each segment onto the next row end.
- **Single-character tokens:**
  - **Expanded last:** a dozen of them are expanded at the very end, for the colour prefix, `ESC[m`, the bars, `══`, `──`, the three-space indent, the bold prefix and the empty preview box row.
  - **Shared colour prefix:** cells are coloured with one `s/[IOTSZJL]/"&m██}/g` plus one digit substitution per piece.
- **Raw bytes:** the ESC bytes are written into the script as they are.
- **What sed refused:**
  - **Fast captures over long text:**
    - **Slow:** glibc fills in `\1` for a match that spans the whole frame very slowly.
    - **The template loop:** it takes about half of the golfed version's frame time, which makes it about twice as slow as the readable one (0.75 ms instead of 0.4 ms per event). Twenty literal `s/#/…/` substitutions would be fast, but roughly 75 bytes longer.
  - **A tenth group:** only `\1` to `\9` exist. That rules out filling the whole template with a fixed-width regex in one go.
  - **A newline-free `p`:** sed won't print without a trailing newline, hence the `nl` option.
  - **A `y` on part of the pattern space:** it always applies to all of it. The seed halving still needs five `s/o0/5/g` substitutions where a positional `y` would do.

This sedtris replaced the 2008 original this collection was forked from; see [Prior art](../README.md#prior-art) in the main README.
