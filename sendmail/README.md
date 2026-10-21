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
own user in *address test mode* (`sendmail -C sendmailtris.cf -bt`), which only
rewrites the lines you type.

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
The decoded frames are byte-for-byte identical to [`../tests/reference.py`](../tests/reference.py).

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
printf 'Game 42\nGame 5\n' | sendmail -C sendmailtris.cf -bt | grep '^Game *returns'
```
