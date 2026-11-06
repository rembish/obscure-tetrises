# sqlitetris

A falling-block puzzle game written in **SQL**, run by the `sqlite3` command-line shell
on an in-memory database. The game lives in tables, a trigger, a recursive CTE and
views. The shell just reads statements and prints rows.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sqlite/sqlitetris.sh | bash
# or, from a clone:
./sqlite/sqlitetris.sh
```

Needs the sqlite3 shell 3.44 or newer (tested with 3.45) and bash 4+. It needs 3.44 for
`group_concat(… ORDER BY …)`.

Install: Debian/Ubuntu `apt install sqlite3` (3.44+ from Debian 13 and Ubuntu 24.04) · Fedora `dnf install sqlite` · macOS `brew install sqlite`, then put `$(brew --prefix sqlite)/bin` first on your `PATH`.

## How it works

SQL has no loops, no variables and no `print`. It does have `UPDATE … FROM`, scalar
subqueries, recursive CTEs, triggers that run a list of statements, and aggregates.
Every piece of control flow becomes a `WHERE` clause.

- **Input.** The launcher starts one `sqlite3 -batch -init /dev/null :memory:`, pipes in
  the engine, then sends one fixed line per input number:
  `INSERT INTO ev VALUES(N);SELECT*FROM frame;`. Inserting into `ev` fires the trigger
  that plays the event. The first number is the seed. The trigger knows it is the seed
  because the generator state is still 0. The launcher only skips blank lines, because
  `VALUES()` is a syntax error.
- **Output.** `.separator "" ""` empties both the column and the row separator. `.mode`
  resets the separators, so it comes first. Then a one-column row is printed as exactly
  its bytes, with no newline of its own after it. `char(27)` gives ESC.
  The whole frame is one row of the view `frame`, built with `group_concat(… ORDER BY …)`.
  When the event doesn't draw, the aggregate prints NULL, which shows as nothing. The
  shell flushes stdout after each statement, even into a pipe, so interactive play needs
  no extra flushing.
- **Stopping.** SQL can't exit the shell, but an error can, with `.bail on`. After the
  game-over frame, or after a quit, `frame` returns a second row whose value is
  `abs(-9223372036854775807 - over - quit)`. That is abs(−2⁶³), an *integer overflow*
  error, so the shell exits. The error message goes to stderr, and the interactive
  launcher sends it to `/dev/null` so it doesn't land on the final frame.
- **State.**
  - `g` is a single row holding the generator, the pieces, the position, the score and so on.
  - `b(x, y, v)` holds one row per settled cell.
  - `cell(p, r, cx, cy)` is unpacked once from the spec's masks by joining with a table
    of numbers.
  - Collision is `NOT EXISTS` over the piece's cells: off the board, or on a row of `b`.
- **Moves.** Left, right and rotate try the positions listed in a `try(k, o, dx, dr)`
  table (rotate holds the five kicks). `ORDER BY o LIMIT 1` picks the first one that
  fits, and `UPDATE g … FROM` applies it.
- **Drops.** A cell can fall until just above the first settled cell (or the floor)
  below it in its column. The piece falls the smallest of those distances, so a hard
  drop needs no loop. A soft drop moves `min(distance, 1)`.
- **Locking** is a second trigger, fired by inserting a row into `lk`. It stamps the piece
  into `b` and puts the full rows (`GROUP BY y HAVING count(*) = 10`) in a scratch table.
  It then scores, deletes those rows, and moves every cell down by the number of
  cleared rows below it. Last it spawns the next piece.
- **Traps:**
  - **Column names ignore case.** `g.r` clashed with the view column `R` (reset), and a
    view `G` collided with the table `g`.
  - **NULL spreads.** `'x' || NULL` is NULL, and `printf('')` returns NULL rather than `''`.
    Either one silently drops a whole row from `group_concat`.
  - **No UNIQUE key on `b`.** The line-clear `UPDATE` renumbers `y`, and a unique key
    would collide halfway through.
  - **Constant sub-expressions can run up front.** A constant `abs(-2^63)` inside a
    `WHERE` conjunct errored even though the other conjunct was false. So the exit
    expression depends on a column, and it only runs for a row that qualifies.
  - **`RAISE()` can't be used to stop.** It would roll back the very insert that ended
    the game, and that frame with it.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own:

```sh
(cat sqlitetris.sql; printf 'INSERT INTO ev VALUES(%s);SELECT*FROM frame;\n' 42 5 9) |
  sqlite3 -batch -init /dev/null :memory:
```

## Golfed version

[`sqlitetris.min.sql`](sqlitetris.min.sql) is the golfed twin of the engine: 2,613 bytes instead of 11,971 (78% smaller), with exactly the same output. The mechanical pass alone gave 4,821 bytes. `_tests/check.sh --min sqlite` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to SQL:

- **Shell defaults:** `-batch` already means list mode with no header, so only `.sep '' ''` and `.bai 1` remain. Dot-commands accept prefixes.
- **The board is a string:** `g.b` holds 200 digits, followed by 60 `8`s. A cell is `substr(b,i+1,1)`, and that text is already a truth value: `'0'` is false. The `8` rows below the board are the floor sentinel. They also hold the next-piece preview, where `8` means "two spaces". The walls are `(a+u+10)/10-1`, which is non-zero off the board.
- **One candidate view for everything.** `Q` lists the positions to try for the current event, each with a hit flag:
  - **Moves and rotate:** the kicks come from the formula `(1-j%2*2)*(j+1)/2`. Left and right are kicks 1 and 2 alone.
  - **Drops:** row offsets 0 … 20.
  - **How it's used:** moving takes the first candidate that doesn't hit. Dropping takes `min(j)` of the hits, and so does the game-over test at spawn (`j=0`). In drop mode, the move's "first free candidate" is the current position, so one `UPDATE … FROM (move) , (drop)` handles every event.
- **One overlay view:** `V` draws the falling piece and the preview piece into the board string with one correlated subquery over a two-row `UNION ALL`. Rendering groups `V` into rows. Locking does the same grouping, keeps the rows with `instr(q,0)`, and pads the top with `hex(zeroblob(e*5))`, which is `e×10` zeros.
- **Generated tables:**
  - **Rotations:** only rotation 0 is listed, as a `json_each` array. A recursive CTE derives the other three with `(x,y) → (2+(p<1)-y, x-(p=1))`, which covers I, O and the 3×3 pieces in one formula.
  - **Numbers:** `generate_series` provides them; the CLI has it built in.
- **Generator one step ahead.** `s` always holds the state that produced the *next* piece, so there's no next-piece column: it's `s%7`. A spawn is `c=s%7, s=s*16807%M`. Start-up seeds `s` and then runs the ordinary lock, with a dummy piece 7 that has no cells, pretending to be a hard drop.
- **Tick in the main `UPDATE`:** `t=(t+NOT e)%G` and `k=max(e,(t+NOT e)/G*4)`. A tick that reaches the gravity interval becomes event 4.
- **Panel:**
  - **One `json_each` array:** it holds the side-panel rows, run through `printf` with the arguments `(preview, score, level, lines)`. Rows skip the arguments they don't use with `%.0s`, and rows 1–6 share one template.
  - **Placeholders:** six `replace()` calls at the end expand one-byte placeholders into the border, dim, bold and reset sequences, `═`×20 (`printf('%.20c','═')`) and `─`.
- **A shorter exit:** `zeroblob(o*2e9)`, *string or blob too big*, replaces the integer overflow.
- **Raw ESC bytes** sit inside the string literals.
- **What SQL refused:**
  - **Unordered aggregates:** `group_concat` without `ORDER BY` makes no ordering promise, so every aggregate keeps its `ORDER BY`.
  - **`printf` arguments:** there are no positional arguments (`%2$s`), hence the `%.0s` skips.
  - **Aliases:** a result-column alias can't be used in a subquery of the same `SELECT`, so `Q` needs a nested derived table.
  - **Case:** names ignore case, so one-letter names run out fast (`g`/`G`, `r`/`R`, `c`/`C`).
  - **Speed:** `CREATE INDEX I ON C(p,q)` stays, at 24 bytes. Without it the overlay scans the cell table 260 times per frame, and the golfed engine runs 2.5× slower. With it, it takes about 6 ms per event on the 300-piece bot game, against 3 ms for the readable version.

Earlier games in the same tool are listed under [Prior art](../PRIOR-ART.md).
