# Falling blocks in unlikely places

[![check](https://github.com/rembish/obscure-tetrises/actions/workflows/check.yml/badge.svg)](https://github.com/rembish/obscure-tetrises/actions/workflows/check.yml)

The same falling-block puzzle game, implemented in Unix tools that were never
meant to run games. A small bash launcher reads the keys and passes them on as
numbers; the tool plays the whole game itself: the board, gravity, rotation, line
clears, scoring and the colour terminal frame. Vim and Emacs can also do without the
launcher and read the keys themselves (the native mode, below).

## Play

One launcher for all of them. It shows a menu, marks which tools are installed and
switches between three versions: the readable engines, the golfed ones, and the native
mode:

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/play.sh | bash
```

Or from a clone:

```sh
git clone https://github.com/rembish/obscure-tetrises.git && cd obscure-tetrises
./play.sh              # menu
./play.sh jq           # straight into jqtris
./play.sh --min tex    # the golfed textris
./play.sh --native vim # vimtris played by Vim itself (vim and emacs only)
./play.sh --list       # what's there and what's installed
```

Every game also has its own launcher, `<dir>/<game>.sh`, which works the same way:
`curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/jq/jqtris.sh | bash`,
or `./jq/jqtris.sh` from a clone. Launchers also work with `| sh`, and arguments pass
through `curl | bash` with `bash -s -- --min m4`.

> Piping a script from the internet into a shell runs it with your permissions. The
> launchers are short; read them first if you like. Under `curl | bash` they download
> only what they run, and the engine goes to a temporary directory deleted on exit.

### Native mode

Vim and Emacs can read the keys and keep the time themselves, so these two games also
run without bash, as one command: the tool and a source file. Same rules, same frames.

```sh
vim -Nu NONE -i NONE -n -S vim/vimtris.native.vim
emacs -Q -nw -l emacs/emacstris.native.el
```

`./play.sh --native vim` (or `n` in the menu) starts them the same way. The other tools
can't on their own: most only read whole lines, so every key would need Enter, and the
ticks need a read that gives up after 100 ms. gawk has that read, but it would still
have to run `stty` to stop the terminal waiting for Enter. See
[vimtris](vim/README.md#native-mode) and [emacstris](emacs/README.md#native-mode).

**Controls:** `a`/← left · `d`/→ right · `w`/↑ rotate · `s`/↓ soft drop · `z`/Space hard drop · `q` quit

**Needs:** bash 4+ (not for the native mode), a UTF-8 terminal with 256 colours, and the
game's own tool. Tested on Linux. [`INSTALL.md`](INSTALL.md) has the package to install
for each game on Debian/Ubuntu, Fedora and macOS.

## The games

| Game | Written in |
|---|---|
| [**awktris**](awk/) | POSIX `awk` (mawk, gawk, busybox) |
| [**bctris**](bc/) | `bc`, the arbitrary-precision calculator language |
| [**cmaketris**](cmake/) | CMake script (`cmake -P`) |
| [**cpptris**](cpp/) | C++ templates, computed by `g++` at compile time |
| [**dctris**](dc/) | `dc`, the reverse-Polish desk calculator |
| [**emacstris**](emacs/) | Emacs Lisp, in `emacs --batch`, or on its own in `emacs -nw` |
| [**gdbtris**](gdb/) | gdb's command language, with no program to debug |
| [**ghcitris**](ghci/) | Haskell type families: GHC's type checker plays, ghci prints |
| [**gnuplottris**](gnuplot/) | gnuplot 6's command language |
| [**jqtris**](jq/) | `jq`, the JSON processor |
| [**m4tris**](m4/) | `m4`, the macro processor |
| [**maketris**](make/) | GNU `make` |
| [**postscripttris**](postscript/) | PostScript, run by Ghostscript |
| [**preprocessortris**](preprocessor/) | the C preprocessor (GCC `cpp -traditional-cpp`), fed its own output |
| [**rewritetris**](rewrite/) | Apache `mod_rewrite` rules, one HTTP request per event |
| [**sedtris**](sed/) | GNU `sed`, the stream editor |
| [**sendmailtris**](sendmail/) | `sendmail.cf` rewriting rules (with a glyph-table decoder; see its README) |
| [**sqlitetris**](sqlite/) | SQL: SQLite triggers, views and recursive CTEs |
| [**textris**](tex/) | plain TeX (Knuth's `tex`, no packages) |
| [**trofftris**](troff/) | `troff`, the typesetter behind `man` |
| [**vimtris**](vim/) | Vim script, in headless `vim -es`, or on its own in full-screen Vim; and [once more](vim/README.md#normal-mode-variant) in normal-mode keystrokes only |
| [**xslttris**](xslt/) | XSLT 1.0, run by `xsltproc` |

Each game's README explains how its engine works and what the tool made hard.

## One game, many engines

Every engine plays exactly the same game, described in [`SPEC.md`](SPEC.md), down to the
byte, and [`_tests/check.sh`](_tests/) checks each of them frame by frame against a
reference implementation. Every engine also comes golfed as `<name>.min.<ext>`, 50–83%
smaller with the same output; [`GOLFING.md`](GOLFING.md) has the sizes and the tricks.

## More

- [`SPEC.md`](SPEC.md): the game rules, the input protocol and the exact output.
- [`GOLFING.md`](GOLFING.md): the golfed `.min` engines: sizes, shared tricks, caveats.
- [`INSTALL.md`](INSTALL.md): requirements and packages per game and OS.
- [`PRIOR-ART.md`](PRIOR-ART.md): earlier Tetrises in the same tools, and how they differ.
- [`_lib/`](_lib/): the launcher code all the games share.
- [`_tests/`](_tests/): the reference implementation and the test runner.

Directories starting with `_` are shared support code; every other directory is one game.

## License

[BSD 2-Clause](LICENSE). This collection started as a fork of Julia Jomantaite's
[sedtris](https://github.com/uuner/sedtris) (2008); see [`PRIOR-ART.md`](PRIOR-ART.md).
