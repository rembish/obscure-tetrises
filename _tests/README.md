# Tests

Every engine plays exactly the same game, described in [`SPEC.md`](../SPEC.md): the same event protocol, random
number generator, rules and output, down to the byte. [`reference.py`](reference.py) is
the executable version of the spec. [`check.sh`](check.sh) replays bot games and
fuzzed key streams through every engine and compares each frame byte for byte with
the reference. The runs go in parallel, one per CPU, and engines whose tool isn't
installed are skipped:

```sh
_tests/check.sh          # all engines
_tests/check.sh jq       # just one
_tests/check.sh -j 1     # one run at a time, for comparable timings
_tests/check.sh --min    # the golfed .min engines
```

- [`gen_events.py`](gen_events.py) writes the event streams: a greedy bot that clears
  lines, and random key and tick streams that include unknown codes.
- Each engine runs through its own launcher with `--pipe`. A variant, an engine file with
  a middle part like `vim/vimtris.normal.keys`, runs through its game's launcher and is
  labelled `vim.normal`; `check.sh vim` runs both of vim's engines, `check.sh vim.normal`
  just the variant. The list of games comes from
  `play.sh`'s `GAMES` table, so a new game only has to be added there.
- The `ms` column is wall time. With runs in parallel it is noisy, so use `-j 1` when
  comparing speeds.

[`launchers.sh`](launchers.sh) covers the ways into a game that `check.sh` doesn't:
the hand-over from `sh` to bash, the download path of `curl | bash` (with `TRIS_URL`
pointing at the clone through `file://`), and a real session on a pseudo-terminal
under `script`. For vimtris and emacstris it also plays the native modes, where the tool
reads the keys itself: a few keys typed within the first second, compared frame by frame
with the reference, with every line ending in `\r\n` (the terminal is raw). It also checks that no run leaves temporary files behind.

```sh
_tests/launchers.sh           # all games, about a minute
_tests/launchers.sh jq        # just one
```

Both scripts take `--strict`, which turns a missing tool from a skip into a failure;
CI uses it. CI ([`../.github/workflows/check.yml`](../.github/workflows/check.yml))
installs every tool on Ubuntu 24.04 with
[`../.github/install-tools.sh`](../.github/install-tools.sh) and runs shellcheck, both
engine suites, `launchers.sh`, and awktris on mawk, gawk and busybox awk.
