# Sedtris

Tetris written in **sed**. The board, the falling pieces, rotation,
collisions, line clears and even score arithmetic are all regular-expression
substitutions in [`sedtris.sed`](sedtris.sed). A small bash launcher feeds it your
keystrokes and a once-a-second tick for gravity.

```
  S E D T R I S
 ╔════════════════════╗
 ║ · · · · · · · · · ·║   ╭── next ──────╮
 ║ · · ·██ · · · · · ·║   │              │
 ║ · · ·████ · · · · ·║   │       ██     │
 ║ · · ·██ · · · · · ·║   │       ██     │
 ║ · · · · · · · · · ·║   │       ██     │
 ║ · · · · · · · · · ·║   │       ██     │
 ║ · · · · · · · · · ·║   │              │
 ║ · · · · · · · · · ·║   ╰──────────────╯
 ║ · · · · · · · · · ·║
 ║ · · · · · · · · · ·║   score
 ║ · · · · · · · · · ·║   0
 ║ · · · · · · · · · ·║
 ║ · · · · · · · · · ·║   controls
 ║ · · · · · · · · · ·║   ← a  move left
 ║ · · · · · · · · · ·║   → d  move right
 ║ · · · · · · · · · ·║   ↑ w  rotate
 ║ · · · · · · · · · ·║   ↓ s  soft drop
 ║ · · · · · · · · · ·║   ␣ z  hard drop
 ║ · · · · · · · · · ·║
 ╚════════════════════╝
```

In the terminal every piece type has its own colour.

## Play

Straight from the web, no install:

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/sedtris/master/sedtris.sh | bash
```

`| sh` works too, as long as bash is installed (the launcher hands itself over to bash).
`wget -qO- … | bash` works as well.

> Piping a script from the internet into a shell runs it with your permissions.
> [Read `sedtris.sh`](sedtris.sh) first if you want to see what it does: it
> downloads `sedtris.sed` to a temporary directory, runs it, and deletes it on exit.

Or clone the repository and run it locally:

```sh
git clone https://github.com/rembish/sedtris.git
cd sedtris
./sedtris.sh
```

## Controls

| Key             | Action                  |
|-----------------|-------------------------|
| `a` / ←         | move left               |
| `d` / →         | move right              |
| `w` / ↑         | rotate                  |
| `s` / ↓ / Enter | move one step down      |
| `z` / Space     | drop                    |
| Ctrl-C          | quit                    |

Scoring follows the classic table: 40 / 100 / 300 / 1200 points for 1 / 2 / 3 / 4
lines cleared at once.

## Requirements

- `bash` for the launcher
- `sed`: tested with GNU sed 4.9. On macOS/BSD the launcher uses `gsed` if it is
  installed (`brew install gnu-sed`); the system BSD sed is untested.
- A terminal with UTF-8 and 256 colours. That covers practically every modern one.
- `curl` or `wget`, only for the run-from-the-web mode

If your terminal does not handle colours, uncomment the line marked
`switch colours off` near the end of `sedtris.sed`. The blocks remain visible.

## How it works

- **Input.** `sedtris.sh` reads one key at a time from `/dev/tty` and writes it to
  sed as a line. Once a second it also writes an empty line (a gravity tick), or
  sometimes a `1`, which is used as a source of randomness for the next piece.
- **State.** sed keeps the entire game in its *hold space*. That is the playfield,
  where each cell is a type digit plus a rotation letter, along with the piece
  shapes, the next piece and the score, as `#FIELD` records separated by `~`.
- **Logic.** Each input line triggers one branch (`:left`, `:right`, `:rotate`,
  `:nothing`, `:fall`). The branch rewrites the state with substitutions. Line
  clears are a single regex. The score is added up digit by digit with a carry loop.
- **Rendering.** The `:display` section copies the state and maps each cell to a
  one-byte placeholder. It lays out the board and side panel, and only then
  expands placeholders into ANSI colours and box-drawing characters. Each frame
  redraws from the top-left corner (`ESC[H`) instead of clearing, so it doesn't flicker.

## Credits

- Original game: Julia Jomantaite (2008)
- The launcher is based on
  [`playsed.sh`](http://sed.sf.net/grabbag/scripts/playsed.sh.txt) by Aurelio Marinho Jargas
- Upstream repository: [uuner/sedtris](https://github.com/uuner/sedtris)
