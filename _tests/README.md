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
- Each engine runs through its own launcher with `--pipe`. The list of games comes from
  `play.sh`'s `GAMES` table, so a new game only has to be added there.
- A few engines can't avoid one extra newline at the very end; the `NL` list in
  `check.sh` names them, and that byte is dropped before comparing.
- The `ms` column is wall time. With runs in parallel it is noisy, so use `-j 1` when
  comparing speeds.
