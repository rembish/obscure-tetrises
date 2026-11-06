# awktris

A falling-block puzzle game written in **awk**: one POSIX awk program that reads
events as input records and prints a frame after each one.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/awk/awktris.sh | bash
# or, from a clone:
./awk/awktris.sh
```

Needs any POSIX awk and bash 4+. The launcher runs plain `awk`. Both files give the same
bytes under mawk 1.3.4, gawk 5.2 (also with `--posix` and with `LC_ALL=C`) and busybox
awk; `_tests/check.sh` passes with each of them put first on `PATH` as `awk`.

Install: Debian/Ubuntu, Fedora and macOS all have an `awk` preinstalled.

## How it works

awk is built for this: it reads stdin one record at a time and runs the rules against
each one. The game is a `BEGIN` block that builds tables, a handful of functions, and two
rules: the first line is the seed, and every later line is an event.

- **Input.** One number per line, as `../SPEC.md` describes. `$1 + 0` turns a line into
  a number, blank lines are skipped, and `9` runs `exit`.
- **Output.** Each frame is built as one string and written with `printf "%s"`, then
  `fflush()`. Without `fflush()`, awk block-buffers stdout when it goes to a pipe, and
  you'd see nothing until the game ended. ESC is `"\033"` and the box-drawing characters
  are octal UTF-8 bytes (`"\342\225\220"` is `═`), so the source is plain ASCII.
- **State.** The board is an array `board[y*10+x]`, holding 0 or piece+1. awk has no
  bitwise operators, so the 28 rotation masks are decoded once, in `BEGIN`, into cell
  lists `CX[p,r,k]` and `CY[p,r,k]`. Fitting, locking and drawing all walk those four
  cells.
- **Numbers.** awk only has doubles. `seed * 16807` stays below 2^46, so Park–Miller
  is exact, and `%` on doubles is exact for integers.

### Traps

- **mawk reads its input in blocks.** When stdin is a pipe, mawk waits for a whole buffer of
  input before running any rule, so keys would show up seconds late. `-W interactive`
  makes it read line by line. The launcher sniffs `awk -W version` and adds the flag only
  for mawk, because the other awks reject or ignore it.
- **`-W interactive` also leaves stdout unbuffered.** With a computed format
  (`printf frame`), mawk then writes each frame a few bytes at a time, thousands of
  `write()` calls per frame. A test run went from 0.2 s to 41 s. `printf "%s", frame`
  writes the frame in one call.
- **`name(` is a function call.** `line (c ? a : b)` concatenates, but `line(c ? a : b)`
  calls a function called `line`. When squeezing out spaces, the space before `(` has to
  stay after a variable.
- **One namespace.** Function names and global variables share one namespace, and gawk
  stops with an error if a name is used as both. Locals are extra function parameters,
  so a short global name can also be shadowed by a local by mistake.
- **No `^` in busybox.** Busybox awk built without its math library says "Math support
  is not compiled in" for `2^i`. Bits are tested by halving instead:
  `m % 2`, then `m = int(m / 2)`.
- **Evaluation order.** `K[i] = c K[++i]` worked in gawk and broke in mawk.
- **UTF-8.** gawk in a UTF-8 locale counts characters and mawk counts bytes, so
  `substr`, `length` and regexes are only ever used on ASCII data.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
printf '42\n5\n9\n' | awk -f awktris.awk
```

(mawk needs `-W interactive` to play it live through a pipe. It isn't needed for a
finished input like this one.)

## Golfed version

[`awktris.min.awk`](awktris.min.awk) is the golfed twin of the engine: 1,717 bytes instead of 6,966 (75% smaller), with exactly the same output. `_tests/check.sh --min awk` replays it against the reference. A mechanical pass (comments, whitespace, short names) got it to 3,128 bytes, and the rest came from restructuring by hand. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to awk:

- **Board as a string:**
  - **Layout:** the board is one 240-character string, `<          >` repeated 20 times. Each cell is a space or the piece digit `1`–`7`.
  - **Bounds for free:** `substr` past either end returns `""`, so the fit test is just `substr(B,j,1)!=" "`. The `<` and `>` sentinels block the side walls, and the rows past the end block the floor.
  - **Stamping:** a piece is written in with `substr(G,1,j-1)p substr(G,j+1)`.
- **Line clear by regex:** `n=gsub(/<[1-7]+>/,"",B)` deletes every full row and counts them in one call. Then `while(n--)B=Z B` pushes empty rows on top.
- **One cell iterator:** `f(X,Y,R,v)` walks the piece's cells. It tests the fit, or stamps the piece into the render buffer `G` when `v` is set. Locking stamps into a copy of the board and copies it back.
- **Rotations computed:** only rotation 0 of each piece is stored. `f` turns each cell `R` times with (x,y) → (n−y, x), with n = 3 for I and 2 for the rest, and skips O. One `split` holds those 7 masks, the 7 colours and the score table.
- **Cell lookup table:** `K[c]` maps a board character straight to its coloured `██`, or to ` ·` for a space. A frame row is then `K[substr(G,i,1)]` ten times.
- **Merged moves:**
  - **Tick, drop and hard drop:** a gravity tick becomes `e=4`, and a hard drop falls as far as it can and then also becomes `e=4`, so one `f(x,y+1,r)?y++:l()` serves all three.
  - **Kicks:** the offsets come from `d=-d-(d>=0)`.
  - **Left and right:** a move is `x+=d*f(x+d,y,r)`, because `f` returns `1` or `""`.
- **Spawn twice:** the lock routine ends by spawning. Called twice at start-up on an empty board, it draws the current and next pieces. The first call stamps an undefined piece, whose mask is empty, so nothing is drawn.
- **Stored level:** `v=int(L/10)` is updated only when lines are cleared. The gravity test becomes `++t+v<10`.
- **Raw bytes:** the ESC bytes and box-drawing characters are written into the source as they are.
- **What awk refused:**
  - **Bit operations:** POSIX awk has no bitwise operators. `and()`/`rshift()` are gawk only, and busybox can't even do `2^i`.
  - **`printf frame`:** it is 5 bytes shorter, but mawk with `-W interactive` writes it a few bytes at a time and became 170 times slower.
  - **`++` in an index:** `K[i]=c M[++i]` depends on evaluation order, which differs between awks.
  - **`substr` on UTF-8:** it would have sliced `──────` out of one run of `─`, but gawk counts characters and mawk counts bytes.

Earlier games in the same tool are listed under [Prior art](../README.md#prior-art) in the main README.
