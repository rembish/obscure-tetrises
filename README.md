# Falling blocks in unlikely places

The same falling-block puzzle game, implemented in Unix tools that were never
meant to run games. Each one reads key presses from a small bash launcher and
draws the whole game itself: the board, gravity, rotation, line clears, scoring
and the colour terminal frame.

| Game | Written in | Play |
|---|---|---|
| [**bctris**](bc/) | `bc`, the arbitrary-precision calculator language | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/bc/bctris.sh \| bash` |
| [**cmaketris**](cmake/) | CMake script (`cmake -P`) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cmake/cmaketris.sh \| bash` |
| [**dctris**](dc/) | `dc`, the reverse-Polish desk calculator | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/dc/dctris.sh \| bash` |
| [**gnuplottris**](gnuplot/) | gnuplot 6's command language | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/gnuplot/gnuplottris.sh \| bash` |
| [**jqtris**](jq/) | `jq`, the JSON processor | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/jq/jqtris.sh \| bash` |
| [**m4tris**](m4/) | `m4`, the macro processor | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/m4/m4tris.sh \| bash` |
| [**maketris**](make/) | GNU `make` | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/make/maketris.sh \| bash` |
| [**sedtris**](sed/) | `sed`, the stream editor (the original, 2008) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sed/sedtris.sh \| bash` |
| [**sendmailtris**](sendmail/) | `sendmail.cf` rewriting rules (with a glyph-table decoder; see its README) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sendmail/sendmailtris.sh \| bash` |
| [**textris**](tex/) | plain TeX (Knuth's `tex`, no packages) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/tex/textris.sh \| bash` |
| [**trofftris**](troff/) | `troff`, the typesetter behind `man` | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/troff/trofftris.sh \| bash` |

Every launcher also works with `| sh` (it hands itself over to bash), and from a clone:

```sh
git clone https://github.com/rembish/obscure-tetrises.git
cd obscure-tetrises
./bc/bctris.sh        # or ./dc/dctris.sh, ./jq/jqtris.sh, ...
```

> Piping a script from the internet into a shell runs it with your permissions.
> Each launcher is short; read it first if you like. It downloads only its own engine
> file to a temporary directory and deletes it on exit.

## Controls

`a`/← left · `d`/→ right · `w`/↑ rotate · `s`/↓ soft drop · `z`/Space hard drop · `q` quit

## One game, many engines

sedtris came first and has its own rules. Every engine added after it plays exactly the
same game, described in [`SPEC.md`](SPEC.md): the same event protocol, random
number generator, rules and output, down to the byte. [`tests/reference.py`](tests/reference.py) is
the executable version of the spec. [`tests/check.sh`](tests/check.sh) replays bot games and
fuzzed key streams through every engine and compares each frame byte for byte with
the reference:

```sh
tests/check.sh          # all engines
tests/check.sh jq       # just one
```

## Golfed versions

Every engine also comes minified as `<name>.min.<ext>`, next to the readable
source. It is golfed as far as each language allows while producing exactly the same bytes.
`tests/check.sh --min` runs every `.min` file through the same comparison. The
golfed sedtris is compared against the original `sedtris.sed` on random key streams. Any
launcher plays a golfed engine with `ENGINE_FILE`:

```sh
ENGINE_FILE=jq/jqtris.min.jq ./jq/jqtris.sh
tests/check.sh --min           # verify all of them
```

| Engine | Source (bytes) | Golfed (bytes) | Saved |
|---|---:|---:|---:|
| bc | 5,561 | 3,132 | 44% |
| CMake | 8,562 | 5,130 | 40% |
| dc | 5,365 | 2,728 | 49% |
| gnuplot | 6,887 | 3,282 | 52% |
| jq | 5,321 | 2,444 | 54% |
| m4 | 8,838 | 5,204 | 41% |
| make | 12,757 | 8,118 | 36% |
| sed | 8,357 | 7,222 | 14% |
| sendmail | 13,395 | 7,904 | 41% |
| TeX | 9,600 | 6,181 | 36% |
| troff | 7,382 | 4,516 | 39% |

Much of what remains is the frame itself: escape codes, box-drawing characters and
panel text that must come out byte for byte. A few languages set hard limits on what can go:
- **sendmail:** only `<` and `>` are always token separators, so most spaces between words stay.
- **make:** spaces are part of values.
- **TeX:** the space after a control word must stay where the frame relies on it being skipped.
- **CMake:** one command per line.

`jqtris.min.jq` uses jq's native `%` on large numbers, so unlike the readable
version it needs jq 1.7 or newer.

## Requirements

- bash 4+ for the launchers (sedtris works with older bash too)
- GNU versions of the tools. Everything is tested on Linux only; stock macOS has a non-GNU `dc` and a `make` too old for maketris
- the tool itself: `sed`, `jq`, …
- a UTF-8 terminal with 256 colours
- `curl` or `wget` for the run-from-the-web mode
- Python 3 only for the tests

## Credits

- sedtris: Julia Jomantaite (2008), [uuner/sedtris](https://github.com/uuner/sedtris).
  The original launcher is based on [`playsed.sh`](http://sed.sf.net/grabbag/scripts/playsed.sh.txt) by Aurelio Marinho Jargas.
- The other engines and the shared spec were added in 2026.
