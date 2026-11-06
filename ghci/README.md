# ghcitris

A falling-block puzzle game written in **Haskell type families**. The game is computed by
GHC's type checker. The state is a type, `Step` is a type family that takes it to the next
one, and the frame is a type-level string. The file defines no functions, only types,
and ghci reduces them.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/ghci/ghcitris.sh | bash
# or, from a clone:
./ghci/ghcitris.sh
```

Needs GHC 9.2 or newer (tested with 9.10.3 and 9.4.7) and bash 4+. The launcher runs a
single `ghci` and talks to it for the whole game.

Install: Debian/Ubuntu `apt install ghc` · Fedora `dnf install ghc` · macOS
`brew install ghc` (or [GHCup](https://www.haskell.org/ghcup/)). It is a large install:
hundreds of megabytes. Unverified on Fedora and macOS.

## How it works

Closed type families are functions on types. GHC tries their equations in order, and
`:kind!` in ghci reduces a type to its normal form. `GHC.TypeLits` provides type-level
numbers with `+ - * ^ Div Mod` and comparisons, which are exact at any size, and
type-level strings (`Symbol`), with `AppendSymbol` and `ConsSymbol`.

- **One event.** The launcher keeps the state as a type synonym `S` and sends ghci two
  commands per event. `:kind! Step S 3` prints the next state in normal form, such
  as `= 'Game 1126542223 0 2 7 0 0 0 0 0 0 Shown`. The launcher names it again
  (`type S = 'Game …`) and asks for the frame:
  `putStr (symbolVal (Proxy @(Frame S)))`. `symbolVal` turns a known `Symbol` into a
  `String`, and it is the only term-level code involved. The first state is `Start 42`,
  for the seed. Quit never reaches ghci: the launcher just stops.
- **The state** is eleven numbers and a mode:
  `'Game seed piece next x y rotation ticks score lines board mode`.
  - The mode says what the launcher does next: `Quiet`, a tick that moved nothing,
    prints no frame; `Shown` prints the frame; `Ended` prints the game-over frame and
    stops.
  - x is stored as x + 4. The box can be at x = −2, and a kick can try two columns left
    of that, but a `Nat` can't be negative.
- **The board is one number**, with 200 octal digits: digit `y * 10 + x` is the cell in
  column x of row y, 0 for empty and piece + 1 for locked. Reading a cell is a `Div` and
  a `Mod` by a power of 8. Locking adds the piece's value times each cell's power of 8.
  Clearing goes up the rows from the bottom, and each row that isn't full is copied to
  the next free row of a new number. Without the clearing, the whole board would be
  arithmetic.
- **Random numbers** are one line: `Mod (s * 16807) 2147483647`. Type-level numbers have
  no overflow, so Park–Miller is exact.
- **The frame** is built from `Symbol`s. A cell is one equation of a family
  (`Cell 3 = "\ESC[38;5;135m██\ESC[m"`). Numbers are printed digit by digit with
  `NatToChar`. Each board row is joined with its side panel, and the 23 lines are joined
  at the end.

### Traps

- **No laziness to rely on.** `If c a b` may work out both branches, so a recursion under
  `If` can run forever. Every recursion here goes through a helper family that matches
  on a `Bool` or a `Maybe` and recurses only in the equation that matched:
  `DownIf ('Just g') g = g'`, `DownIf 'Nothing g = Lock g`.
- **Size costs more than steps.** The first version kept the board as a list of 20 lists
  of 10 cells. Every command that mentions such a state makes the type checker take in a
  type of about 450 parts, which costs a few milliseconds before any work is done, and a
  frame took about 30 ms. As one number the state is tiny, and both bot games run in
  about a third of the time.
- **Names are shared between types and constructors.** GHC 9.10 prints promoted
  constructors in the normal form without the tick (`Shown`; 9.4 prints `'Shown`). When a
  type family had the same name, `type S = … Shown` meant the family, and failed.
- **`*` is `Type`.** Without `NoStarIsType`, `s * 16807` is a kind error.
- **ghci charges for long strings.** Even `putStr "…"` with a 1.6 KB literal takes about
  2 ms, so a frame costs a few milliseconds however it is built. A frame takes about
  10 ms in all, and a tick that prints nothing about 1 ms.

The closest relative is [Chesskell](https://wrap.warwick.ac.uk/155567/) (Toby Bailey and
Michael Gale, Haskell Symposium 2021), a two-player chess game at the type level, in which
an illegal move is a type error. Its authors also found type families slow, in
unpredictable ways.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To play a few events by hand:

```sh
ghci -XDataKinds -XTypeApplications ghcitris.hs
ghci> :kind! Start 42
ghci> type S = 'Game 1126542223 0 2 7 0 0 0 0 0 0 Shown
ghci> :m + GHC.TypeLits Data.Proxy
ghci> putStr (symbolVal (Proxy @(Frame (Step S 5))))
```

## Golfed version

[`ghcitris.min.hs`](ghcitris.min.hs) is the golfed twin of the engine: 5,554 bytes instead of 15,816 (65% smaller), with exactly the same output, and just as fast. `_tests/check.sh --min ghci` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to type families:

- **Equations on one line:** `type family Z n where{Z 0='True;Z n='False}`. All kind signatures are left to inference.
- **Only what the launcher sees keeps its name:** the kind `Game`, `Start`, `Step`, `Frame` and the mode `Ended`. The constructor is `K`, and the other modes are `Q` and `W`. No type family may share a name with a constructor, since GHC 9.10 prints constructors without the tick and the launcher reads them back.
- **Tables are numbers:** the 28 masks are one 448-bit constant, and `Ms p r` takes 16 bits out of it. The points for 0–4 rows are the base-10000 digits of `12000300010000400000`.
- **Gravity is one comparison:** `max(1, 11 - level) <= t` is `10 <= t + lines / 10` for every level.
- **No imports but `GHC.TypeLits`:** `&&` and `==` became three Bools in one equation (`E 'True 'True 'True … = …`) and a family that matches 0.
- **Shared families:** soft and hard drop are one family with a flag, and left and right are one move with an offset.
- **The cells stay equations:** working the colour out from a table would be shorter, but it would cost every one of the 200 cells a `ShowNat`.

