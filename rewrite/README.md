# rewritetris

A falling-block puzzle game written in **Apache mod_rewrite**: `RewriteRule` and
`RewriteCond`, regexes and nothing else. The launcher starts a private Apache httpd with
the rules as its configuration and plays the game over HTTP, one request per event.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/rewrite/rewritetris.sh | bash
# or, from a clone:
./rewrite/rewritetris.sh
```

Needs Apache httpd 2.4 with mod_rewrite (tested with 2.4.66 and 2.4.58) and bash 4+. The launcher
finds `apache2` or `httpd` and the module directory; set `APACHE_MODULES` if it doesn't. It
runs the server as your user on a random port of 127.0.0.1, and stops it when the game ends.

Install: Debian/Ubuntu `apt install apache2-bin` (the binary and the modules; the full
`apache2` package also starts a system web server) · Fedora `dnf install httpd` · macOS
`brew install httpd`. Unverified on Fedora and macOS.

## How it works

mod_rewrite is a string-rewriting system. It was made to turn one URL into another, but
the rules can loop, and they can read and set variables, so they can compute anything.
["An excursion in mod_rewrite"](http://olsner.se/2008/01/21/an-excursion-in-mod_rewrite/)
(2008) is the classic account of that. rewritetris plays the whole game in the rules.

- **Input and output.** An event is one request, `GET /<n>`. The answer to a move is a
  `404 Not Found` whose body is the frame: `ErrorDocument 404 "%{reqenv:F}"` prints the
  variable the rules have built. A tick that moved nothing gets `204 No Content`, and the
  game-over frame comes as `410 Gone`, which is how the launcher knows to stop.
- **State.** The server keeps nothing between requests. The whole game is a cookie, set on
  every answer with the `[CO=…]` flag and sent back by the launcher with the next request.
  The first request has no cookie, and its number is the seed:
  `Ta~J~xx~yyy~---xxxx~-xx~1011…~######..........######…`. That is the falling piece and
  its rotation, the next piece, the level and the ticks in unary, the score and lines in
  "column unary" (a run of `x` per decimal digit), the 31-bit seed, and the board.
- **Variables** are environment variables: `[E=NAME:value]` sets one, `%{ENV:NAME}`
  reads it. A `RewriteCond` matches a regex against any string built from variables,
  and its groups come back as `%1`…`%9` in the rule after it. That is the only way to
  compute: take strings apart and put the pieces together again.
- **Control flow.** `[N]` starts the rule set again from the top, and is the only loop.
  The variable `J` names the step that runs next, and each block of rules starts with a
  rule that skips the block (`[S=n]`) unless `J` names it. Setting `J` and falling through
  to a later block is free; going back up costs a round of `[N]`. A "subroutine" is a
  block that jumps to the label in another variable, `[E=J:%{ENV:RET},N]`. That is how
  every move draws the piece with the same 25 shape rules.
- **Lookup tables** are strings appended to the one being matched. To halve a decimal
  digit with a remainder, `"%{ENV:H}# 0000 0101 0210 …"` is matched against
  `^(\d*)/(\d)(\d)(\d*)#.* \2\3(\d)(\d)`: the back-reference `\2\3` finds the entry for
  "remainder, digit", and the two groups after it are the quotient digit and the new
  remainder. Rotation letters, the adder, mod 7, the preview boxes, digits and the
  colours of the cells all work this way.
- **Shapes are regexes**, as in [sedtris](../sed/). The board is 16-character rows of six
  walls and ten cells, so one row down is 16 characters on, and T in rotation 0 is
  `@(.)\.(.{14})\.\.\.` after the `@` that marks the corner of its box. If the regex
  matches, the piece fits, and the rule writes it in. Walls, and the end of the string
  below the floor, make it fail. The falling piece is drawn in lower case, so locking it is
  one call of the built-in map `int:toupper`.
- **Random numbers.** The seed goes to binary by halving it 31 times. Then
  `s * 16807 mod (2^31 - 1)` is five rounds of `7s = 8s + not s`, where `8s` is a
  rotation of the bits. The adder takes one bit per round and runs over the doubled
  string, so the carry out of the bottom half comes back in at the top. The piece is
  `s mod 7`, by Horner's rule over the bits.
- **The frame.** The number columns become digits and the board rows become lines with
  their side panels, a rule each. Then the cells are painted one per round from a table.
  ESC and the newline can't be written in a config file, so the first round makes them
  with the built-in map `int:unescape` (`${unescape:\%1B}`). The box-drawing characters
  are plain UTF-8 in the file.

### Traps

- **`%1B` is a back-reference.** `%1` is the first group of the last condition,
  so URL escapes have to be written `\%1B`.
- **Every `[N]` round runs every rule above the loop again.** A frame is about 250
  rounds, so the loops that run most (painting, the adder, mod 7, the seed) sit at the top
  of the file. Painting also moves the finished text into a second variable as it goes:
  a regex that skips over the painted text every round made painting quadratic, and a
  frame took 16 ms. Now it takes a few.
- **Flags are split on commas,** and a flag argument with spaces has to be quoted
  whole: `"[E=F:%1 text %2]"`. Nothing in the game needs a comma.
- **Nine groups.** `%1`…`%9` are all a condition gives, which is why painting goes cell
  by cell and the shapes keep their gaps short.
- **Nagle's algorithm.** bash's builtins write a request one line at a time. On a
  connection that stays open, the server delays its ACK of the first line and the client
  holds back the rest until it arrives, 40 ms per event. A new connection per request,
  which bash opens itself with `/dev/tcp`, ACKs at once.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To try the engine by hand, start the server as the launcher does (it writes its
`httpd.conf` into a temporary directory) and use curl's cookie jar:

```sh
curl -s -c jar http://localhost:PORT/42                     # a new game, seed 42
curl -s -b jar -c jar http://localhost:PORT/5               # hard drop
```

The cookie's domain is `localhost`, so use that name rather than `127.0.0.1`.

## Golfed version

[`rewritetris.min.conf`](rewritetris.min.conf) is the golfed twin of the engine: 8,815 bytes instead of 23,715 (63% smaller), with exactly the same output. `_tests/check.sh --min rewrite` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to mod_rewrite:

- **The URL is the program counter.** A rule's substitution can be any path, and the rules after it see the new one. So the step to run next is the URL itself (`/P`, `/K`, `/e3`), and each rule's own pattern is its guard: `RewriteRule ^/P - […]`. There are no `[S=n]` skips and no `J`, and a "return" is `RewriteRule ^/P %{ENV:U} [N]`. The event codes become `/e0`…`/e5`, so that a later round can't take a label for the number of the first request.
- **Raw bytes:** the ESC bytes are written into the file as they are. Only the newline still comes from `int:unescape`.
- **Cheaper empty cells:** an empty cell is `-`, not `.`, so the shape regexes need no backslashes. The prefix up to the first cell is one group: `(.*@.)-(.{14})---`.
- **Moves are kicks:** left and right are the kick codes `u` and `v`. A rotation walks `uvvuuuvvvv` from where it stands, the same walk as in [sedtris](../sed/README.md#golfed-version), so the five kick rules become two.
- **One carry loop:** score and lines are carried as one string `S~L`, and the frame runs the same rules on `S~L~-V`. A return label picks what happens afterwards.
- **The panel is a list:** the 20 side-panel texts are one `|`-separated string, with the preview and the numbers already in it. One looping rule takes a board row and a panel entry per round, instead of 20 rules.
- **Shorter tables:** the preview rows are written with two spaces per empty cell, and all colours share one prefix, so painting needs no case for the preview's empty cells.

