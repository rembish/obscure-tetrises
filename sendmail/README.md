# sendmailtris

A falling-block puzzle game written in **sendmail.cf rewriting rules**, the
configuration language of the [sendmail](https://www.proofpoint.com/us/products/email-protection/open-source-email-solution)
mail server. Famously, nobody can read it.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sendmail/sendmailtris.sh | bash
# or, from a clone:
./sendmail/sendmailtris.sh
```

Needs sendmail (tested with 8.18.1, the Debian/Ubuntu `sendmail-bin` package) and bash 4+.
Nothing is configured or started as a mail server. The game runs sendmail as your
own user in *address test mode* (`sendmail -ODontProbeInterfaces=true -C sendmailtris.cf -bt`; the option skips a reverse DNS lookup of every network interface at start-up, which can take tens of seconds), which only
rewrites the lines you type.

Install: Debian/Ubuntu `apt install sendmail-bin` · Fedora `dnf install sendmail` · not available on macOS, whose `sendmail` is Postfix's wrapper without `-bt`. The package replaces any other mail server (Postfix, Exim) and may start a daemon, which the game doesn't need.

## The one thing sendmail can't do: draw

sendmail can't print an escape character or a UTF-8 byte. It drops control
characters and shows 8-bit bytes as `M-x`, on every output path, including macro
display. So [`sendmailtris.cf`](sendmailtris.cf) returns each frame as a line of
**glyph tokens**:

```
Game             returns: hh tt nl tp nl lb e e e i i i i e e e rb pb nl …
```

The launcher's `decode` function turns each token into its bytes using a fixed
table: `e` → a dim `·`, `i` → a cyan `██`, `nl` → `ESC[K` plus a newline, and so on.
Tokens that aren't in the table, such as the score digits, pass through unchanged. The table has
no conditions and no state. Every decision about what to draw, where, and in what
order is made by sendmail. That makes this the one engine in the collection that
needs a renderer outside the tool, and that is why it's disclosed up front.
The decoded frames are byte-for-byte identical to [`../_tests/reference.py`](../_tests/reference.py).

## How it works

- **Input.** `-bt` reads lines like `Game 3` and runs ruleset `Game` on the
  address `3`. The launcher sends one such line per event (see [`../SPEC.md`](../SPEC.md)).
  The first event carries the seed.
- **State** lives in macros: `{r0}` … `{r19}` hold the board rows, ten tokens each.
  The `macro` map writes them (`$(put {score} $@ 120 $)`) and `$&{score}` reads them.
- **Arithmetic** comes from the `arith` map: `$(calc + $@ 3 $@ 4 $)`, plus `*`, `/`,
  `%` and `l` (less than). It is 64-bit, so Park–Miller needs no tricks.
- **Control flow.** A ruleset is a list of rules that run in order, and a rule repeats
  while its pattern matches. Rulesets can't jump backwards. So every loop is one rule
  that keeps matching and consumes one row, cell or offset per pass, and every
  "if" is a pattern on a result like `yes`/`no` or `TRUE`/`FALSE`.
- **Lookups.** Patterns match shortest-first, so `< $* / $* >` peels off exactly
  one row. `Get` walks to a cell by dropping rows and then tokens while an `arith`
  counter runs down.
- **Calls.** `$>Name` runs another ruleset, but only on the *rest of the line*. So
  every call is written last, and its result lands at the end of the workspace.
- **Limits.** sendmail stops a rule after 100 repetitions ("Infinite loop in
  ruleset"), nests calls at most 50 deep, and caps a workspace at about 2 KB. No
  loop here walks more than 20 rows, and the glyph tokens are one or two letters so a
  whole frame fits.
- **Lag.** sendmail flushes its output when it reads the next line. A frame therefore
  appears with the next event, which with 100 ms ticks is never more than 100 ms later.
- sendmail can't stop by itself. After the game-over frame it emits the token `fin`,
  and the launcher exits when it sees it (or `quit`, for event 9).

To run the engine without the launcher and see the raw tokens:

```sh
printf 'Game 42\nGame 5\n' | sendmail -ODontProbeInterfaces=true -C sendmailtris.cf -bt | grep '^Game *returns'
```

## Golfed version

[`sendmailtris.min.cf`](sendmailtris.min.cf) is the golfed twin of the engine: 2,291 bytes instead of 13,395 (82% smaller), with exactly the same output. `_tests/check.sh --min sendmail` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to sendmail:

- **One board macro:** the board is a single macro `{b}` instead of `{r0}`…`{r19}`. That dropped the 3×20 row lists and 40 row-splitting rules; macro values keep their spaces.
- **Rotation by formula:** the 28-entry piece table became 7 rotation-0 entries plus a box size `m`. One ruleset computes rotation r as (x,y), (m−y,x), (m−x,m−y) or (y,m−x).
- **Preview with the board code:** the next-piece preview reuses the board-drawing rulesets on a small grid.
- **Frame assembly in one loop:** one rule interleaves board rows with a `/`-separated panel string. GAME OVER is written into row 9 by one extra rule.
- **Cell access:** cells are read and written by walking rows and columns with `$~` on a one-token class. Out-of-range coordinates simply don't match, so the bounds-check ruleset is gone.
- **Merged rulesets:**
  - **Moves:** one move-and-check ruleset covers left, right and soft drop.
  - **Hard drop:** a two-rule loop.
  - **Next piece:** picking it also spawns it.
  - **Game-over flag:** it doubles as the decoder's end token.
- **Read-time text macros:** frequent rule fragments are `D` macros expanded when the file is read, about 440 bytes saved. A search script kept a fragment only if a 400-event replay still matched and the file loaded silently.
- **What sendmail refused:**
  - **`|`:** this is not an operator character, so it needs spaces around it.
  - **Arguments and maps:** there is no `$10`, and maps can't be nested.
  - **Nested `$>` calls:** these make it about 3.5× slower, because `-bt` prints a trace line for every one and the decoder has to read them all. So the walks are loops.
  - **Macro boundaries:** a text macro can't split a `{name}` across its boundary.
- **Leftover from pass 1:** `V10` stays, so the file loads with no out-of-date warning.
