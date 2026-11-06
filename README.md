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

Each game also has its own launcher. Some of these tools had a Tetris before this
collection; see [Prior art](#prior-art).

| Game | Written in | Play |
|---|---|---|
| [**awktris**](awk/) | POSIX `awk` (mawk, gawk, busybox) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/awk/awktris.sh \| bash` |
| [**bctris**](bc/) | `bc`, the arbitrary-precision calculator language | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/bc/bctris.sh \| bash` |
| [**cmaketris**](cmake/) | CMake script (`cmake -P`) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cmake/cmaketris.sh \| bash` |
| [**cpptris**](cpp/) | C++ templates, computed by `g++` at compile time | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cpp/cpptris.sh \| bash` |
| [**dctris**](dc/) | `dc`, the reverse-Polish desk calculator | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/dc/dctris.sh \| bash` |
| [**emacstris**](emacs/) | Emacs Lisp, in `emacs --batch` | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/emacs/emacstris.sh \| bash` |
| [**gnuplottris**](gnuplot/) | gnuplot 6's command language | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/gnuplot/gnuplottris.sh \| bash` |
| [**jqtris**](jq/) | `jq`, the JSON processor | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/jq/jqtris.sh \| bash` |
| [**m4tris**](m4/) | `m4`, the macro processor | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/m4/m4tris.sh \| bash` |
| [**maketris**](make/) | GNU `make` | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/make/maketris.sh \| bash` |
| [**postscripttris**](postscript/) | PostScript, run by Ghostscript | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/postscript/postscripttris.sh \| bash` |
| [**sedtris**](sed/) | `sed`, the stream editor (the original, 2008) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sed/sedtris.sh \| bash` |
| [**sendmailtris**](sendmail/) | `sendmail.cf` rewriting rules (with a glyph-table decoder; see its README) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sendmail/sendmailtris.sh \| bash` |
| [**sqlitetris**](sqlite/) | SQL: SQLite triggers, views and recursive CTEs | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/sqlite/sqlitetris.sh \| bash` |
| [**textris**](tex/) | plain TeX (Knuth's `tex`, no packages) | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/tex/textris.sh \| bash` |
| [**trofftris**](troff/) | `troff`, the typesetter behind `man` | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/troff/trofftris.sh \| bash` |
| [**vimtris**](vim/) | Vim script, in headless `vim -es` | `curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/vim/vimtris.sh \| bash` |

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
source. It is 49–82% smaller and produces exactly the same bytes.
`tests/check.sh --min` runs every `.min` file through the same comparison. The
golfed sedtris is compared against the original `sedtris.sed`. Play one with
`./play.sh --min <game>`, or with any launcher's `ENGINE_FILE`:

```sh
ENGINE_FILE=jq/jqtris.min.jq ./jq/jqtris.sh
tests/check.sh --min           # verify all of them
```

| Engine | Source (bytes) | Golfed (bytes) | Saved |
|---|---:|---:|---:|
| awk | 6,966 | 1,717 | 75% |
| bc | 5,561 | 2,262 | 59% |
| CMake | 8,562 | 3,660 | 57% |
| C++ templates | 21,530 | 3,980 | 82% |
| dc | 5,365 | 2,138 | 60% |
| Emacs Lisp | 11,797 | 2,112 | 82% |
| gnuplot | 6,887 | 2,122 | 69% |
| jq | 5,321 | 1,845 | 65% |
| m4 | 8,838 | 2,083 | 76% |
| make | 12,757 | 4,196 | 67% |
| PostScript | 7,753 | 1,501 | 80% |
| sed | 8,357 | 4,250 | 49% |
| sendmail | 13,395 | 2,291 | 82% |
| SQLite | 11,993 | 2,616 | 78% |
| TeX | 9,600 | 2,597 | 72% |
| troff | 7,382 | 2,887 | 60% |
| Vim script | 7,806 | 1,851 | 76% |

[`GOLFING.md`](GOLFING.md) explains how: the shared tricks (generated tables, one
cell iterator, merged moves, free bounds checks) and what each language allowed or refused.
`jqtris.min.jq` needs jq 1.7 or newer.

## Prior art

sedtris is the one game here that was not written for this collection: it is Julia
Jomantaite's original from 2008, kept as it was. Every other engine was written from
scratch to [`SPEC.md`](SPEC.md). Where the same tool had a Tetris before, that earlier
project is listed here. No code was taken from any of them.

| Game | Earlier work | How it differs from ours |
|---|---|---|
| [awktris](awk/) | [AWKTC](https://github.com/mikkun/AWKTC) by mikkun ([slides](https://speakerdeck.com/mikkun/tetris-clone-in-awk)) | Runs on gawk, nawk and goawk, with an adjustable board width. awktris sticks to POSIX awk, so it also runs on mawk and busybox. |
| [cpptris](cpp/) | [Super Template Tetris](https://github.com/mattbierner/Super-Template-Tetris) by Matt Bierner, 2015 ([blog post](https://blog.mattbierner.com/stupid-template-tricks-super-template-tetris/)) | Advances one move per compile, with the move passed as a `-D` flag. cpptris compiles a whole batch of key presses at a time, so it plays in real time. |
| [emacstris](emacs/) | `M-x tetris`, shipped with Emacs (`lisp/play/tetris.el`) | Draws in an Emacs buffer through Emacs's own UI. emacstris runs in `emacs --batch -Q` and prints terminal frames. |
| [postscripttris](postscript/) | [PSTris](https://github.com/nst/PSTris) by Nicolas Seriot | Draws real graphics on a Ghostscript page and reads keys from a file that another terminal writes; it has levels, a 7-piece bag and high scores. postscripttris prints ANSI text frames. |
| [sedtris](sed/) | [uuner/sedtris](https://github.com/uuner/sedtris) by Julia Jomantaite, 2008 | This is that game, not a rewrite. It keeps its own rules; the other engines follow `SPEC.md`. Its launcher is based on [`playsed.sh`](http://sed.sf.net/grabbag/scripts/playsed.sh.txt) by Aurelio Marinho Jargas. The golfed `sedtris.min.sed` was added in 2026. |
| [sqlitetris](sqlite/) | [tetris-sql](https://github.com/nuno-faria/tetris-sql) by Nuno Faria ([HN thread](https://news.ycombinator.com/item?id=41444855)) | One PostgreSQL query: a recursive CTE is the game loop, a Python helper supplies the input, and frames come out through `RAISE NOTICE`. sqlitetris uses triggers and views, with one long-running `sqlite3` reading a statement per event. |
| [vimtris](vim/) | [TeTrIs.vim](https://github.com/pihentagy/TeTrIs.vim) by Gergely Kontra (vim.org script #172, around 2002) | Plays inside a Vim buffer with Vim's own UI. vimtris uses Vim only as an interpreter, in silent Ex mode with no screen. |

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
- The other engines and the shared spec were added in 2026. Earlier games in the same
  tools are credited under [Prior art](#prior-art).
