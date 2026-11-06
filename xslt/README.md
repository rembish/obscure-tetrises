# xslttris

A falling-block puzzle game written in **XSLT 1.0**, the XML transformation language,
and run by `xsltproc`. The stylesheet transforms the game state into the next
state, and prints the frames on the way.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/xslt/xslttris.sh | bash
# or, from a clone:
./xslt/xslttris.sh
```

Needs `xsltproc` (libxslt with libexslt, tested with libxslt 1.1.45) and bash 4+. Besides
plain XSLT 1.0, the engine uses four EXSLT extensions that libexslt ships:
`exsl:node-set`, `exsl:document`, `str:decode-uri` and `str:padding`.

Install: Debian/Ubuntu `apt install xsltproc` · Fedora `dnf install libxslt` · macOS has it preinstalled.

## How it works

XSLT has no assignment and no loops that carry state, and it reads a whole document
before transforming it. Everything below follows from those three facts.

- **Input: one transform per batch.** An XSLT processor can't read a stream, so the
  launcher runs `xsltproc` once per batch of events, like cpptris runs g++:
  ```sh
  xsltproc --stringparam ev "0 0 1 3 " --stringparam out /tmp/…/next.xml xslttris.xsl state.xml
  ```
  The input document is the game state. Before the first batch it is just `<s seed="42"/>`;
  after that it is whatever the previous batch saved. The stylesheet plays every event in
  `$ev`, writes the new state to `$out` with `exsl:document`, and writes nothing when the
  game is over, which tells the launcher to stop. A background reader appends stdin to a
  queue while `xsltproc` runs, and the next batch takes everything that has arrived (up
  to 500 events). `xsltproc` starts in a few milliseconds, so in play a batch is
  usually one or two events, and the game feels live.
- **State is an element.** `<s b="…" c="2" n="4" x="3" y="0" r="0" t="0" sc="0" ln="0" s="…" o="0"/>`:
  the board is a 200-digit string (`0` empty, or piece + 1), and the rest are numbers.
  Each rule is a named template that returns a new `<s>`. It copies the old attributes
  with `<xsl:copy-of select="$st/@*"/>` and then overrides some with `<xsl:attribute>`;
  a later attribute with the same name replaces the earlier one. `exsl:node-set` turns
  the returned result tree fragment back into a node that the next rule can read.
- **Loops are recursion.** The event loop is a template that plays the first event and
  calls itself with the rest. The fit test, stamping a piece, finding full rows, the
  hard drop, wall kicks and every row and cell of the frame are recursive templates too.
  One event is one level of recursion, and libxslt's default limits (3,000 nested
  templates, 15,000 variables) are too low for a 500-event batch, so the launcher passes
  `--maxdepth` and `--maxvars`.
- **Bits without bitwise operators.** XPath 1.0 numbers are doubles with `+ - * div mod`
  and `floor()`. The fit test walks a piece's mask with `$m mod 2` and `floor($m div 2)`:
  bit `i` is box cell `(i mod 4, i div 4)`. The Park–Miller product stays below 2^53, so
  doubles compute it exactly.
- **Tables are XML.** The piece masks, colours, points, wall kicks and control labels
  are elements in the stylesheet's own namespace, read back with `document('')`.
- **Output.** `<xsl:output method="text"/>` writes text nodes as raw UTF-8. That is
  enough for the box-drawing characters, but XML 1.0 can't hold the escape character at all,
  not even as `&#27;`. So the engine makes it at run time: `str:decode-uri('%1B')`
  decodes the URI escape into character 27, and every colour code is built from that
  variable. No decoder is involved.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own, one batch at a time:

```sh
echo '<s seed="42"/>' > /tmp/state.xml
xsltproc --stringparam ev "5 5" --stringparam out /tmp/next.xml xslttris.xsl /tmp/state.xml
```

## Golfed version

[`xslttris.min.xsl`](xslttris.min.xsl) is the golfed twin of the engine: 5,466 bytes instead of 24,802 (78% smaller), with exactly the same output. `tests/check.sh --min xslt` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to XSLT:

- **XSLT as the default namespace:** `xmlns="http://www.w3.org/1999/XSL/Transform"` makes every `<xsl:param>` a `<param>`. The one literal result element, the state, moved to another namespace (`<s:s>`), and the input state is matched as `*`, so it is found in either namespace.
- **Real functions:** libexslt implements EXSLT `func:function`, so the rules are XPath functions (`f:M`, `f:G`, `f:L`, …) that call each other inside expressions. There are no `call-template`/`with-param` blocks except the event loop.
- **One fit test, one stamp:** each piece rotation is four two-digit cell offsets in one 224-character table, `13*y+x`. The fit test is a three-term recursion: `not($o)or substring($b,$q+substring($o,1,2),1)=0 and f:M($b,$q,substring($o,3))`.
- **A board with walls:** the board is 13 wide: 10 cells, a right wall `%`, a filler `*` and a row letter `A`–`U`. Two filler characters go above it and spare rows below. Any position whose cells aren't all `0` fails, so there are no bounds checks: a piece that sticks out to the left reads the previous row's walls. The position is one number, `q`, so left, right and down are `-1`, `+1` and `+13`.
- **Frame by one replace:**
  - **Drawing:** `str:replace` with node-sets replaces many strings at once. It turns every digit of the board into its cell glyph and every row letter into that row's right wall, side panel, line end and the next row's left wall. Those 31 replacements are one `str:tokenize` of a `|`-separated string.
  - **The row letters:** `A` is the header and `U` the footer.
  - **Preview:** the next piece is stamped into a 4-row template whose filler is the text between the preview rows.
- **Macros:** after the board replace, two more `str:replace` passes expand one-character macros (`^` → `ESC[m`, `{` → border colour, `` ` `` → `ESC[K` + newline, `(` → the start of a preview row, …). The second pass expands the macros used inside other macros. Every ESC is written `~`, and one final `translate(…,'~*',$ESC)` turns `~` into ESC and deletes the `*` filler.
- **Moves are lists:** left, right, rotation with wall kicks, soft drop, gravity and hard drop are lists of `(Δq, Δr)` steps for one function, `f:T`. It takes the first step that fits, repeats it for hard drop, and locks when the list runs out. Left and right end with a `(0, 0)` step, which always fits, so they never lock.
- **State kept ready to use:** the state stores the current piece's offsets and the level. The offsets are empty after game over, so the dead piece isn't drawn and no separate flag is needed.
- **Start-up by two locks:** the first state is a board with no piece. Locking it twice draws the current and the next piece and spawns. The missing piece has no offsets, so nothing gets stamped.
- **What XSLT refused:**
  - **The escape character:** XML 1.0 forbids it in any form, so ESC exists only at run time.
  - **Result tree fragments:** libxslt won't let XPath step into one, so every new state needs `exsl:node-set`.
  - **Empty attributes:** an empty attribute is still a non-empty node-set, so `test="$o"` is true for `o=""`. The stamp tests `$o!=''`.
  - **`<` in attributes:** it must be written `&lt;`, so comparisons are turned around (`6>$e`, `11>position()`).
  - **`version="1"`:** libxslt wants `version="1.0"` exactly, or it prints a warning.
- **Faster:** about 40% faster than `xslttris.xsl`.
