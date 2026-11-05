# vimtris

A falling-block puzzle game written in **Vim script**. Vim is only the interpreter:
no window is opened, no buffer is edited, and no key goes through Vim's normal mode.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/vim/vimtris.sh | bash
# or, from a clone:
./vim/vimtris.sh
```

Needs Vim (tested with 9.1) and bash 4+. It doesn't need `+python`, `+channel`,
a GUI or a terminal Vim can drive. It runs as `vim -Nu NONE -i NONE -es`.

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
- **Output.** `writefile(lines, '/dev/stdout', 'abS')` writes the bytes as given:
  - `b` puts a newline *between* the list items but not after the last one. The frame
    goes out as its 23 lines plus a final `ESC[J` item, so there's no extra newline at the
    end and no `nl` allowance.
  - `a` appends. Without it, every frame would truncate whatever stdout points at, and
    `tests/check.sh` redirects it to a regular file.
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

[`vimtris.min.vim`](vimtris.min.vim) is the golfed twin of the engine: 1,851 bytes instead of 7,806 (76% smaller), with exactly the same output. `tests/check.sh --min vim` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to Vim script:

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

## Prior art

Tetris in Vim script had been done before this one. vimtris was written from scratch to
`../SPEC.md` without looking at it:

- [TeTrIs.vim](https://github.com/pihentagy/TeTrIs.vim) by Gergely Kontra (vim.org script #172, around 2002): plays inside
  a Vim buffer with Vim's own UI. vimtris uses Vim only as an interpreter, in silent Ex mode with no screen.
