# Prior art

This collection started as a fork of Julia Jomantaite's
[sedtris](https://github.com/uuner/sedtris) (2008), the game that gave the repo its
idea. Every engine here, sedtris included, was written from scratch to
[`SPEC.md`](SPEC.md). Where the same tool had a Tetris before, that earlier project is
listed below. No code was taken from any of them.

| Game | Earlier work | How it differs from ours |
|---|---|---|
| [awktris](awk/) | [AWKTC](https://github.com/mikkun/AWKTC) by mikkun ([slides](https://speakerdeck.com/mikkun/tetris-clone-in-awk)) | Runs on gawk, nawk and goawk, with an adjustable board width. awktris sticks to POSIX awk, so it also runs on mawk and busybox. |
| [cpptris](cpp/) | [Super Template Tetris](https://github.com/mattbierner/Super-Template-Tetris) by Matt Bierner, 2015 ([blog post](https://blog.mattbierner.com/stupid-template-tricks-super-template-tetris/)) | Advances one move per compile, with the move passed as a `-D` flag. cpptris compiles a whole batch of key presses at a time, so it plays in real time. |
| [emacstris](emacs/) | `M-x tetris`, shipped with Emacs (`lisp/play/tetris.el`) | Draws in an Emacs buffer through Emacs's own UI. emacstris runs in `emacs --batch -Q` and prints terminal frames. |
| [postscripttris](postscript/) | [PSTris](https://github.com/nst/PSTris) by Nicolas Seriot | Draws real graphics on a Ghostscript page and reads keys from a file that another terminal writes; it has levels, a 7-piece bag and high scores. postscripttris prints ANSI text frames. |
| [sedtris](sed/) | [uuner/sedtris](https://github.com/uuner/sedtris) by Julia Jomantaite, 2008 | The game this collection was forked from. It has its own rules, and its launcher is based on [`playsed.sh`](https://web.archive.org/web/20220823204008/http://sed.sourceforge.net/grabbag/scripts/playsed.sh.txt) by Aurelio Marinho Jargas. Our sedtris replaced it with a rewrite that plays `SPEC.md`, does the Park–Miller arithmetic in sed itself and reads one event per cycle; it was written without looking at the original. |
| [sqlitetris](sqlite/) | [tetris-sql](https://github.com/nuno-faria/tetris-sql) by Nuno Faria ([HN thread](https://news.ycombinator.com/item?id=41444855)) | One PostgreSQL query: a recursive CTE is the game loop, a Python helper supplies the input, and frames come out through `RAISE NOTICE`. sqlitetris uses triggers and views, with one long-running `sqlite3` reading a statement per event. |
| [vimtris](vim/) | [TeTrIs.vim](https://github.com/pihentagy/TeTrIs.vim) by Gergely Kontra (vim.org script #172, around 2002) | Plays inside a Vim buffer with Vim's own UI. vimtris uses Vim only as an interpreter, in silent Ex mode with no screen. |
