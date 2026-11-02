# Falling blocks in unlikely places

The same falling-block puzzle game, implemented in Unix tools that were never
meant to run games. Each one reads key presses from a small bash launcher and
draws the whole game itself: the board, gravity, rotation, line clears, scoring
and the colour terminal frame.

## Quick start

One launcher for all of them. It shows a menu, marks which tools are installed and
toggles between the readable and the golfed engines:

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/play.sh | bash
# or, from a clone:
./play.sh              # menu
./play.sh jq           # straight into jqtris
./play.sh --min tex    # the golfed textris
./play.sh --list       # what's there and what's installed
```

Pass arguments through `curl | bash` with `bash -s -- --min m4`.

## The games

Each game also has its own launcher:

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
./play.sh             # or ./bc/bctris.sh, ./jq/jqtris.sh, ...
```

> Piping a script from the internet into a shell runs it with your permissions.
> Each launcher is short; read it first if you like. It downloads only its own engine
> file to a temporary directory and deletes it on exit. `play.sh` downloads only the
> launcher you pick (and its `.min` engine, if asked) the same way.

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

Every engine also comes golfed as `<name>.min.<ext>`, next to the readable
source. It is about 50–80% smaller and produces exactly the same bytes.
`tests/check.sh --min` runs every `.min` file through the same comparison. The
golfed sedtris is compared against the original `sedtris.sed`. Play one with
`./play.sh --min <game>`, or with any launcher's `ENGINE_FILE`:

```sh
ENGINE_FILE=jq/jqtris.min.jq ./jq/jqtris.sh
tests/check.sh --min           # verify all of them
```

| Engine | Source (bytes) | Golfed (bytes) | Saved |
|---|---:|---:|---:|
| bc | 5,561 | 2,262 | 59% |
| CMake | 8,562 | 3,660 | 57% |
| dc | 5,365 | 2,138 | 60% |
| gnuplot | 6,887 | 2,122 | 69% |
| jq | 5,321 | 1,845 | 65% |
| m4 | 8,838 | 2,083 | 76% |
| make | 12,757 | 4,196 | 67% |
| sed | 8,357 | 4,250 | 49% |
| sendmail | 13,395 | 2,291 | 82% |
| TeX | 9,600 | 2,597 | 72% |
| troff | 7,382 | 2,887 | 60% |

[`GOLFING.md`](GOLFING.md) explains how: the shared tricks (generated tables, one
cell iterator, merged moves, free bounds checks) and what each language allowed or refused.
`jqtris.min.jq` needs jq 1.7 or newer.

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
