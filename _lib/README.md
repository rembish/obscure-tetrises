# The shared launcher

Each `<dir>/<game>.sh` holds only what is specific to its game: the name, engine file and
tool, and a `run_engine` function that turns a stream of event numbers on stdin into
frames on stdout, adapting the input wherever the tool needs it (troff gets `.GO N`
requests, m4 gets `E(N)` macro calls, and so on). Everything else is shared in
[`launcher.sh`](launcher.sh):

- **Keys and ticks:** reading the keyboard and turning keys into event numbers, with a
  tick every 100 ms.
- **Checks:** the bash version and whether the tool is installed.
- **The engine:** using the one next to the launcher, or downloading it.
- **The terminal:** setting it up and restoring it on exit.
- **`--pipe`:** reading events from stdin, which is how `_tests/check.sh` runs every engine.

The only code repeated in every launcher is the hand-over from `sh` to bash at the top,
which has to run before any bash syntax, and a few lines that load `_lib/launcher.sh`.

## Downloads

Under `curl | bash` a launcher has no files next to it, so it downloads two: this
`launcher.sh`, which it runs with `eval`, and its own engine, which goes to a temporary
directory that is deleted on exit. `play.sh` downloads only the launcher you pick (and
its `.min` engine, if asked) the same way. `TRIS_URL` changes where all of them download
from; by default it is this repository's `master` branch on GitHub.

## Writing a launcher

A launcher sets `GAME`, `DIR`, `ENGINE` and `NEEDS`, defines `run_engine`, and
optionally `check_tool`. While `run_engine` runs, `$work` is a scratch directory and
`$pipe` is 1 under `--pipe`. The comment at the top of [`launcher.sh`](launcher.sh)
lists the details, and [`../jq/jqtris.sh`](../jq/jqtris.sh) is the shortest example.
