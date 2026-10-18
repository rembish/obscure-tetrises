# jqtris

A falling-block puzzle game written in [jq](https://jqlang.org), the JSON processor.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/sedtris/master/jq/jqtris.sh | bash
# or, from a clone:
./jq/jqtris.sh
```

Needs jq and bash 4+. Tested with jq 1.7.

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
