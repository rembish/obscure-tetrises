# vimtris

A falling-block puzzle game written in **Vim script**, and once more in Vim's **normal
mode** alone ([below](#normal-mode-variant)). The Vim script engine runs two ways:

- **With the launcher**, Vim is only the interpreter: it runs headless, no window is
  opened, no buffer is edited, and no key goes through Vim's normal mode. bash reads the
  keys and passes them on as numbers, like every other game here.
- **On its own** ([native mode](#native-mode)), full-screen Vim reads the keys and keeps
  the time itself. One command, no bash.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/vim/vimtris.sh | bash
# or, from a clone:
./vim/vimtris.sh
./play.sh --native vim                              # or: vim -Nu NONE -i NONE -n -S vim/vimtris.native.vim
```

Needs Vim (tested with 9.1), and bash 4+ for the launcher. It doesn't need `+python`,
`+channel` or a GUI. The launcher runs it as `vim -Nu NONE -i NONE -es`.

Install: Debian/Ubuntu `apt install vim` (`vim-tiny` has no Vim script) · Fedora `dnf install vim-enhanced` · macOS has it preinstalled.

## Native mode

Vim can also play on its own, with no launcher: one command, Vim and a source file.

```sh
vim -Nu NONE -i NONE -n -S vim/vimtris.native.vim
SEED=42 vim -Nu NONE -i NONE -n -S vim/vimtris.native.vim     # a fixed game
./play.sh --native vim                                        # the same, from the menu's launcher
```

It needs Vim in a terminal; `getchar(0)` and `reltime()` are in every Vim 8 and 9. Without
`SEED`, the seed comes from `rand()` (Vim 8.2 and newer) or from the clock.

[`vimtris.native.vim`](vimtris.native.vim) sources `vimtris.vim` for the game, so the
rules and the frames are the same, and does the launcher's job itself:

- **Keys:** Vim starts full-screen, which puts the terminal in raw mode, so `getchar(0)`
  returns each key as it is pressed, or 0 when there is none. Arrows come back as
  `"\<Left>"` and so on.
- **Ticks:** `reltime()` keeps the time, and the loop sends a tick every 100 ms, sleeping
  10 ms between looks at the keyboard.
- **Frames:** the engine still writes them to `/dev/stdout`, which is now the terminal,
  but ends each line with `\r\n`. Raw mode also turns off the terminal's output
  processing, so a bare newline only moves the cursor down, and the frame would come out
  as a staircase. Vim draws nothing meanwhile: it only redraws when a script is done or
  asks for it, and this script runs until the game ends.
- **Hooks:** `vimtris.vim` checks for `g:vimtris_native`. When it's set, the file hands its
  start, event and render functions to the driver as funcrefs, and skips its own stdin loop.

- **Quitting:** `q`, or Ctrl-C (caught as `Vim:Interrupt`).

When the game ends, the last frame stays up until a key is pressed, because Vim gives the
terminal back as it found it when it quits. `_tests/launchers.sh` plays a few keys through
it on a pseudo-terminal and compares the frames with the reference.

## Normal-mode variant

[`vimtris.normal.keys`](vimtris.normal.keys) is the same game with no Vim script at all:
only normal-mode keys, the ones you type to edit text. The file is a buffer, and the game
is the editing of it: the board is 20 lines of text, the state is lines like `score 120`,
and the code is lines of keystrokes that run with `@`.

```sh
./play.sh vim.normal
ENGINE_FILE=vim/vimtris.normal.keys ./vim/vimtris.sh
```

The launcher loads the file into `vim -es` and types four commands per input line: put
the input into line 1 (`:norm! ggS3`), run the keys on line 2 (`:norm! 2G"ay$@a`),
write the frame lines to stdout, and run register q, which holds `ZQ` once the game is
over. Everything the game does happens in those keys:

- **Calls.** Code lives on lines `:name keys`. `/^:name <CR>f l"ay$@a` finds the line,
  yanks its keys into register a and runs them. Running a register puts its keys in
  front of the keys still waiting, so when it ends, the caller's keys run on: a call
  that returns.
- **No failure allowed.** A command that fails, like a search that finds nothing, aborts
  every key still waiting, all the way out to the `:norm`. So a failure can't be an `if`.
- **Ifs are searches that can't fail.** `gg/<pattern>\|^ELSE|<CR>` finds the pattern or
  the `ELSE|` line near the end of the file, and every line it can land on ends in `|@s`
  or `|@f`. `$h"ay$@a` runs that ending: `@s` and `@f` are trampolines that call the code
  named on the `then` and `else` lines, which the code sets just before the search.
  Searches find the first match in the buffer, so each fallback comes after what it
  stands in for. Loops are a branch that calls its own code again.
- **Fit tests are regexes over the board,** as in [sedtris](../sed/), but across lines:
  `\%3l\%8c\.\_.\{20}\.\.\.` is T at line 3, column 8: `\%l` and `\%c` pin the search
  to the piece's place, and `\_.` crosses line ends. A board line is four walls, ten
  cells, four walls and `|@s`, 22 bytes with its newline, so a wall or the floor in the
  way makes the search fall through to `ELSE`.
- **Numbers** are decimal text, changed with `<C-A>` and `<C-X>` and a count. A count
  that comes from the buffer is typed into a `cmd` line with insert-mode `<C-R>` and yanked
  into a register to run. Lookup tables are lines found by a search built the same way:
  `/^x<C-R>m<C-R>n:` finds the digit and carry of 7 × n + m.
- **The frame** is the board's 20 lines copied between the lines `F` and `E`, with the
  walls cut off and the borders put on by block-wise inserts (`<C-V>19jI`). The side panel,
  20 template lines with the numbers filled in, goes on as one block-wise paste. The cells
  are painted one at a time from a colour table, until the search falls through to
  `PAINTED`.

### Traps

- **Vim caps a count at 999,999,999.** `2147483647<C-X>` subtracts 999,999,999, so 2^31 − 1
  is three counts, and the seed (up to 2^31 − 2) can't be added with a count at all. So
  `s × 7` is long multiplication, one digit at a time from a table, and `s mod 7` is long
  division the same way.
- **A count can't start with 0,** because `0` is a motion. So the row is kept as its line
  number (y + 3) and the column as x + 5, and a value that can be 0 is never a count.
- **`cw` on a negative number changes only the `-`.** Copying 2 over `-9` gave `29`; a
  value that can be negative is replaced with `C`.
- **`\V` makes `^` literal.** In a very-nomagic pattern it has to be `\^`.
- **Every search costs a pass over the file,** and painting takes about 216 of them per
  frame. Starting the search at the frame, keeping the colour table just above it (found
  with a backward `?`), and holding the paint loop in a register instead of looking it up
  each round cut a frame from 145 ms to about 50 ms.
- **`'fileformats'`.** A code line ending in `<CR>` makes Vim take the file for a DOS
  file. The launcher sets `ffs=unix`.

The keys are written in the file as `<Esc>`, `<CR>`, `<C-A>`, `<C-X>`, `<C-R>` and
`<C-V>`, and the launcher turns them into the bytes before Vim reads it. The file was
generated once by a script that worked out the fit regexes, stamp paths and lookup
tables from the piece masks; the result is what's here.

## How it works

The engine is plain legacy Vim script (`let`, `if`/`elseif`, `for`, `while`, `function!`),
not vim9script. Numbers are 64-bit, so Park–Miller needs no tricks. Lists hold the board,
and `and()` and `<<` read the rotation masks.

- **Headless Vim.** `-es` is silent Ex mode, and `-Nu NONE -i NONE` skips every vimrc and
  plugin and the viminfo file. In this mode Vim draws no screen, sends no terminal codes
  and prints no messages, even when its stdout is the terminal.
- **Input.** In silent Ex mode, `input('')` reads one line from stdin. So the script reads
  the seed and then one event per line by itself, and the launcher passes the event lines
  through unchanged. There's no adapter line and no FIFO. At end of input Vim exits on its own.
- **Output.** `writefile(lines, '/dev/stdout', 'aS')` writes the bytes as given:
  - Without the `b` flag every list item is followed by a newline, the last one too. The
    frame goes out as its 23 lines, each ending in `ESC[K`, so the newlines land exactly
    where the frame format wants them.
  - `a` appends. Without it, every frame would truncate whatever stdout points at, and
    `_tests/check.sh` redirects it to a regular file.
  - `S` turns off the `fsync()` that `writefile()` does by default. On a regular file
    that made each frame wait for the disk: the 300-piece bot game took 20 s instead of 4 s.
  - Each call opens, writes and closes the file, so every frame reaches the terminal at once.
- **State** is script-local variables: a flat list of 200 cells for the board, plus the
  piece, position, score and lines. The masks are turned into lists of `[dx, dy]` cell
  offsets once, at load time.
- **Traps on the way:**
  - **Ctrl-C.** A SIGINT sends Vim's Ex mode into a busy loop at 100% CPU. After that it
    no longer reads stdin and even ignores SIGTERM. Ignoring the signal doesn't help,
    because Vim installs its own handler. So the launcher runs Vim in the background (passing
    stdin on with `<&0`) and `wait`s for it, with an INT trap that kills it outright. I
    first tried `stty -isig`, to turn Ctrl-C into a plain key, but bash's `read -n1`
    switches ISIG back on.
  - **Speed.** Legacy Vim script is slow: a bare million-step `while` loop takes 4.4 s
    here, where vim9script needs 0.1 s. The first version looped over the 16 mask bits on
    every collision test and spent most of its time there. Precomputing the cell offsets
    once, and the `S` flag above, bring it to about 2 ms a frame.
  - **Encoding.** The box-drawing characters are raw UTF-8 bytes in the source, and there's
    no `:scriptencoding` on purpose. With `-u NONE` under `LC_ALL=C`, Vim's `'encoding'` is
    latin1, and `:scriptencoding utf-8` would then convert every `█` into something else.
    Without it the bytes pass through untouched in any locale.
  - **Lambdas don't see script variables.** At script level, `{_, v -> b[p + v]}` doesn't
    see the globals `b` and `p`, but the string form `map(l, 'b[p + v:val]')` does, because
    it is evaluated in the caller's scope.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
printf '42\n5\n9\n' | vim -Nu NONE -i NONE -es -S vimtris.vim | head -3
```

## Golfed version

[`vimtris.min.vim`](vimtris.min.vim) is the golfed twin of the engine: 1,847 bytes instead of 7,771 (76% smaller), with exactly the same output. `_tests/check.sh --min vim` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to Vim script:

- **No functions at all.** The whole game is script-level code in one `wh !o` loop. That
  removes every `s:` and `a:` prefix and every `fu`/`endf`/`retu`, because at script level
  a bare name is already a global. The only subroutine left is spawn, kept as a string `S`
  and run with `exe S` at start-up and after each lock.
- **One loop for the seed and the events.** The first line read is the seed: `q` is still 0,
  so that iteration seeds and spawns twice (current, then next) instead of running an event.
  Every later line is an event. Ticks that don't move anything, and unknown codes, `con`
  past the drawing code.
- **Command abbreviations:** `wh`, `endw`, `endfo`, `en`, `el`, `cal`, `exe`, `con`, `unl`
  and `q!`. `let` can't be shortened (`:le` is `:left`), but `let[c,m,p,r,t,k]=[...]`
  sets six variables in one statement.
- **Position as one number.** The board is 12 cells wide (two wall columns) with a full
  wall row underneath, and the piece position is a single index `p = y*12 + x`. Left, right
  and down are `p-1`, `p+1` and `p+12`, and a cell is just `b[p+offset]`. The collision
  test is `max(map(O[c][U]+[],'b[p+d+v:val]'))`. `+[]` is a cheaper `copy()`, and the walls
  hold 9. Kicks to x = −1 or −2 on row 0 reach `b[-1]` and `b[-2]`, which Vim reads from the
  end of the list: the floor. So negative indices are free sentinels too.
- **One candidate loop for every move.** Each event indexes a list of position deltas:
  `[[12],[-1],[1],[0,-1,1,-2,2],[12],repeat([12],20)][e]`. The first delta that fits wins.
  Hard drop just has twenty `12`s and never stops early. The loop ends with `d` holding the last
  delta, so `d>9&&!n` ("tried to go down and couldn't") is the lock condition for soft
  drop, hard drop and gravity alike. A gravity tick is event 0, which is soft drop's `[12]`.
- **Rotations generated** from the rotation-0 cells, written as a 28-digit string. One
  formula covers all seven pieces: (x, y) → (2 + [I] − y, x − [O]). The O piece turns about
  its own centre, so it maps onto itself.
- **The frame is one string with markup.** `` `60║` `` means `ESC[38;5;60m║ESC[m`. A single
  `substitute()` with `` \v`(\d*)([^`]*)` `` expands every border, dim label and cell at
  the end, and the cell table holds `` `51██` `` instead of the full escape. Every line
  ends in `ESC[K`, so splitting after each `ESC[K` (`\zs`) cuts the frame into the list
  `writefile()` wants.
- **Panel from one literal.** The side panel is one `;`-separated string, split into rows. The
  six control rows are written as `← a,move left;…`, and one more `substitute()` turns each
  one into `   ESC[1m← aESC[m  ` + dim label. The next-piece box rows 1–6 come from the
  same `index()` lookup, which finds nothing on rows 1 and 6 and prints 8 spaces.
- **Line clear in place:** `unl b[y*12:y*12+11]` and then `let b=Z+b` for every full row,
  top to bottom. The rows above shift down, but those have already been checked.
- **Raw ESC bytes** everywhere and `/dev/fd/1` instead of `/dev/stdout`.
- **What Vim script refused:**
  - **`input()`** requires its prompt argument, so it's `input('')`.
  - **`split(s,'')`** doesn't split into characters. It has to be `'\zs'`.
  - **`printf()`** errors on unused arguments, so one format string can't serve every panel row,
    even with positional `%1$s`.
  - **Output:** `:echon` prints nothing in silent Ex mode. `writefile()` turns a newline
    inside an item into NUL, so the frame can't be written as one string either.
  - **Lambdas:** they can't see script-level variables without `g:`.
- **Speed:** about 3 ms a frame against 2 ms for the readable version, because the falling
  piece is now looked up per cell with `index()` instead of being stamped into a copy of the
  board. That is still far under the 100 ms tick.

Earlier games in the same tool are listed under [Prior art](../PRIOR-ART.md).
