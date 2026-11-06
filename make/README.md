# maketris

A falling-block puzzle game written in [GNU make](https://www.gnu.org/software/make/).

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/make/maketris.sh | bash
# or, from a clone:
./make/maketris.sh
```

Needs GNU make with `$(file <…)` (added in 4.2) and bash 4+. Tested with GNU make 4.3. macOS ships make 3.81, which is too old.

Install: Debian/Ubuntu `apt install make` · Fedora `dnf install make` · macOS `brew install make`, then put `$(brew --prefix make)/libexec/gnubin` first on your `PATH` so that `make` is GNU make.

## How it works

make has no loops, no arithmetic, no input and no mutable state, apart from what
you can build out of string functions and its own rebuild logic.

- **The game loop is make restarting itself.** The whole game state is an
  included makefile. Its rule rewrites the file and then runs `true`, so make
  sees that one of its makefiles was rebuilt and re-executes itself with the
  new state. This is the "remaking makefiles" feature, used as a loop. Each event is one restart.
  `true` is the only command make ever runs; its only job is to make the rule
  count as having done something. A recipe made only of `$(file)` calls counts as no recipe.
- **Input.** `$(file <name)` reads a file to its end, so the launcher gives every
  event its own named pipe. Pass *N* reads `events.N` (make counts its own
  restarts in `MAKE_RESTARTS`), and the launcher creates the next pipe before it
  writes the current one. When one pipe was shared, the next write could land
  in the previous read and get lost.
- **Numbers.** Small numbers are unary: `x x x` is 3. `$(words)` turns them back into
  digits, and `$(word 11,$(T) $(LV))` is the test "ticks + level ≥ 11". The piece
  column is stored with an offset of 5, because unary numbers can't be negative.
- **The score** is a real decimal string. It is split into digits with `$(subst)`
  and added digit by digit with carries; each digit sum is done in unary.
- **Random numbers.** The Park–Miller step runs on 31-element lists of bits.
  Multiplying by 16807 means adding seven shifted copies, and the modulus uses
  2³¹ ≡ 1 (mod 2³¹−1): the high bits are added back onto the low ones. `mod 7` uses
  2ⁱ mod 7 = 1, 2, 4, 1, 2, 4, …. The decimal seed becomes bits by long division by 2.
- **One deviation from the spec:** `$(info)` always ends its output with a newline.
  So each frame begins by printing the previous frame's trailing `ESC[J`, and the
  very last `ESC[J` is followed by one extra newline. The test harness allows
  exactly that byte.

Everything else is shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own, use the launcher's pipe mode:

```sh
(echo 42; yes 0 | head -50; echo 5; echo 9) | ./maketris.sh --pipe
```

## Golfed version

[`maketris.min.mk`](maketris.min.mk) is the golfed twin of the engine: 4,196 bytes instead of 12,757 (67% smaller), with exactly the same output. `tests/check.sh --min make` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to make:

- **Generated tables:**
  - **Rotations:** only rotation 0 of each piece is stored, with 1-based coordinates. Rotations 1–3 are computed at load as (x,y) → (n+1−y, x).
  - **Colours:** they come from a `$(foreach)` over one word list.
  - **Piece numbers:** these are 1-based, so the increment tables went.
- **Cheaper arithmetic:**
  - **Seed:** converted to binary digit by digit (`b = b*10 + d`) with the existing binary adder. The halving table went.
  - **7-way random pick:** the bits are joined with x-strings weighted 1, 2 and 4, then `subst xxxxxxx` removes the multiples of 7.
  - **Level:** a `subst` of 10-x groups on the lines counter.
  - **Score:** kept as reversed digits, so it's reversed only once, for display.
  - **Carry:** the adder's carry is `$(word 2,…)` of the list of 1s.
- **Dispatch by name:** an event calls `$(E$J)`, guarded by `$(value E$J)`. A tick returns `n` when nothing moved, which replaces the redraw flag.
- **One first-fit function:** a recursive function serves left, right and rotate, with the wall-kick offsets as `$(wordlist k,999,…)`.
- **Line clear:** rows are shifted bottom-up in place, using a constant empty row.
- **One `$(info)` per frame:** embedded newlines, and the space between `foreach` items supplies each row's leading space.
- **Restart rule:** one line, `$(if quit,$(info ESC[J),$(STATE)):all;$(file >...):`.
- **What make refused:**
  - **Self-reference:** a recursive variable can't reference itself, so hard drop still needs `$(call E5)`.
  - **Writing state at parse time:** this doesn't trigger a restart, and neither does a rule with an empty recipe. The state file must be written from a recipe that ends in `:`.
