# jqtris

A falling-block puzzle game written in [jq](https://jqlang.org), the JSON processor.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/jq/jqtris.sh | bash
# or, from a clone:
./jq/jqtris.sh
```

Needs jq and bash 4+. Tested with jq 1.7.

Install: Debian/Ubuntu `apt install jq` · Fedora `dnf install jq` · macOS 15+ has it preinstalled, or `brew install jq`.

## How it works

jq looks like a pure filter, but `jq -n` with `foreach inputs` makes it a state
machine that reads a stream:

```jq
foreach inputs as $event ($start; step($event); render)
```

`$start` is a JSON object: a 200-element board array, the current and next
piece, the position, score, line count and the random-number state. Each event
number the launcher sends updates that object. `render` then builds a full
ANSI frame as one string, and `-j --unbuffered` writes it straight to the terminal.

A few details:

- **Pieces** are stored as 16-bit masks and decoded into `[x, y]` cells once at
  start-up. jq has no bitwise operators, so the masks are decoded with
  division and `floor`.
- **Random numbers** use Park–Miller (`s * 16807 mod 2^31-1`). Every product fits
  in a double's 53 bits. Older jq versions truncate `%` to 32 bits, so the
  engine does its modulo with `floor` instead.
- **Game over** uses `label $done | ... break $done` to leave the `foreach`.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine without the launcher:

```sh
(echo 42; yes 0 | head -50; echo 5) | jq -nrj -f jqtris.jq
```

## Golfed version

[`jqtris.min.jq`](jqtris.min.jq) is the golfed twin of the engine: 1,845 bytes instead of 5,321 (65% smaller), with exactly the same output. `tests/check.sh --min jq` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to jq:

- **Raw ESC:** jq 1.7 accepts a raw ESC byte inside string literals, so every `"\u001b[…"` is one byte.
- **Pieces as letters:** the piece table is one 112-letter string, one cell index (0–15) per letter, decoded with `explode|map(.-97|[.%4,./4|floor])|[_nwise(16)|[_nwise(4)]]`. The next-piece preview tests `[$x,$y]|IN(...)` against rotation 0.
- **One fit test, one move helper:**
  - **Fit test:** `F` checks the current state, with `$a*($a-9)<1` for the column bounds.
  - **Moves:** `m(D;$r)` is `first(((D) as $d | move | select(F)), .)`. It covers left, right and rotation with wall kicks.
  - **Soft drop:** `(.y+=1|select(F))//k`.
  - **Gravity tick:** `select(.t+l<11)//(.t=0|u)`.
- **Draw decision:** a `select($e<6 and $e*9>=.t)` in the `foreach` extractor decides whether to draw, so there's no flag. Quitting uses `try(… error …)` instead of `label`/`break`.
- **Line clear:** `[.b|_nwise(10)|select(min<1)[]]`, then `([zeros]+$k)[-200:]`. One `reduce` stamps the piece, for both locking and drawing.
- **Rendering:**
  - **Side panel:** an array `$P`, with the indent added by one `map`.
  - **Board rows:** `_nwise(10)|map($K[.])` over a table of cell strings. Row 9 is overwritten with GAME OVER.
  - **Control rows:** each one is a single string split with `.[:3]` and `.[3:]`.
- **What jq refused:**
  - **`+.end`:** this lexes as the field `.end`, so it needs a space (`+. end`).
  - **Binding:** `A|B as $P|C` binds wrongly unless `A|B` is in parentheses.
- **Needs jq 1.7 or newer.** It relies on native `%` on large numbers and raw control characters in strings. The readable `jqtris.jq` still runs on jq 1.6.
