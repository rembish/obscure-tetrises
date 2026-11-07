# Requirements and installation

- bash 4+ for the launchers (the native modes of vimtris and emacstris run without it)
- GNU versions of the tools. Everything is tested on Linux only; stock macOS has a non-GNU `dc` and a `make` too old for maketris
- the tool itself: `sed`, `jq`, …
- a UTF-8 terminal with 256 colours
- `curl` or `wget` for the run-from-the-web mode
- Python 3 only for the tests

## Installing the tools

`./play.sh --list` shows which ones you already have. Package names:

| Game | Command | Debian / Ubuntu (`apt install`) | Fedora (`dnf install`) | macOS (Homebrew) |
|---|---|---|---|---|
| awktris | `awk` | preinstalled (`mawk`) | preinstalled (`gawk`) | preinstalled |
| bctris | `bc` | `bc` | `bc` | `brew install bc` ¹ |
| cmaketris | `cmake` | `cmake` | `cmake` | `brew install cmake` |
| cpptris | `g++` | `g++` | `gcc-c++` | `brew install gcc` ² |
| dctris | `dc` | `dc` | `bc` (it includes `dc`) | `brew install bc` ¹ |
| emacstris | `emacs` | `emacs-nox` | `emacs-nox` | `brew install emacs` |
| gdbtris | `gdb` | `gdb` | `gdb` | `brew install gdb` (Intel only) |
| ghcitris | `ghci` | `ghc` | `ghc` | `brew install ghc` ⁹ |
| gnuplottris | `gnuplot` | `gnuplot-nox` ³ | `gnuplot` | `brew install gnuplot` |
| jqtris | `jq` | `jq` ³ | `jq` | preinstalled on macOS 15+, or `brew install jq` |
| m4tris | `m4` | `m4` | `m4` | `brew install m4` ¹ |
| maketris | `make` | `make` | `make` | `brew install make` ¹ |
| postscripttris | `gs` | `ghostscript` | `ghostscript` | `brew install ghostscript` |
| preprocessortris | `cpp` | `cpp` | `cpp` | `brew install gcc` ⁷ |
| rewritetris | `apache2` or `httpd` | `apache2-bin` ⁸ | `httpd` | `brew install httpd` |
| sedtris | `sed` | preinstalled | preinstalled | `brew install gnu-sed` ¹ |
| sendmailtris | `sendmail` | `sendmail-bin` ⁴ | `sendmail` ⁴ | not available ⁵ |
| sqlitetris | `sqlite3` | `sqlite3` ³ | `sqlite` | `brew install sqlite` ¹ |
| textris | `tex` | `texlive-base` | `texlive-tex` | `brew install --cask basictex` ⁶ |
| trofftris | `troff` | `groff-base` (usually preinstalled) | `groff-base` | `brew install groff` |
| vimtris | `vim` | `vim` (`vim-tiny` has no Vim script) | `vim-enhanced` | preinstalled |
| xslttris | `xsltproc` | `xsltproc` | `libxslt` | preinstalled |

1. Homebrew installs these next to the macOS versions instead of over them, so put
   them first on your `PATH`:
   ```sh
   export PATH="$(brew --prefix bc)/bin:$PATH"                # bc, dc
   export PATH="$(brew --prefix m4)/bin:$PATH"
   export PATH="$(brew --prefix sqlite)/bin:$PATH"
   export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"   # gmake as make
   export PATH="$(brew --prefix gnu-sed)/libexec/gnubin:$PATH" # gsed as sed
   ```
2. On macOS `g++` is Clang, which can't build cpptris. Homebrew's GCC is `g++-15` (or
   whatever its version is); link it as `g++` in a directory that comes first on your `PATH`.
3. Version minimums: gnuplot 6 (Debian 13, Ubuntu 24.04), sqlite3 3.44 (Debian 13,
   Ubuntu 24.04), and jq 1.7 for the golfed jqtris (Debian 13, Ubuntu 24.04). Older
   releases ship older versions.
4. The game only runs `sendmail -bt` as your user and needs no mail server, but the
   package replaces whatever mail server you have (Postfix, Exim) and may start a daemon.
   Stop or disable it afterwards if you don't want it. If sendmailtris takes a minute to
   start, your host name has no domain and sendmail sleeps 60 s before giving up on it;
   a line like `127.0.1.1 myhost.localdomain myhost` in `/etc/hosts` fixes that.
5. macOS's `/usr/sbin/sendmail` is Postfix's compatibility wrapper, which has no `-bt`
   address test mode, and Homebrew has no sendmail.
6. BasicTeX puts `tex` in `/Library/TeX/texbin`; open a new terminal afterwards. The
   full TeX Live (`brew install texlive` or the `mactex-no-gui` cask) works too.
7. preprocessortris needs GCC's `cpp`; Apple's `cpp` is Clang. Homebrew's GCC installs it
   as `cpp-15` (or whatever its version is); link it as `cpp` in a directory that comes
   first on your `PATH`. Unverified on macOS.
8. `apache2-bin` is the server binary and its modules. The `apache2` package works too,
   but it also starts a system web server on port 80; `sudo systemctl disable --now apache2`
   stops it. rewritetris starts its own server, as your user, on a random port of
   127.0.0.1. Unverified on Fedora and macOS.
9. GHC is a large install (hundreds of megabytes); ghcitris needs 9.2 or newer. GHCup
   (https://www.haskell.org/ghcup/) works too. Unverified on Fedora and macOS.
