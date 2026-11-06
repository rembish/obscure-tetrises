# cpptris

A falling-block puzzle game played by the **C++ compiler**. Every rule is a
template, and g++ computes the game while it compiles. The program it builds only
writes out bytes that were already worked out.

```sh
curl -fsSL https://raw.githubusercontent.com/rembish/obscure-tetrises/master/cpp/cpptris.sh | bash
# or, from a clone:
./cpp/cpptris.sh
```

Needs g++ (tested with 13.3) and bash 4+. Clang won't do: the engine uses GNU extensions, namely the string literal operator template and `\e` in strings, and the golfed file adds zero-length arrays, `?:` and `__integer_pack`. Each
batch of events is one compile, so the screen updates in jumps of a few hundred
milliseconds. Every event is still processed, and the frames are the same as
everywhere else.

Install: Debian/Ubuntu `apt install g++` · Fedora `dnf install gcc-c++` · macOS `brew install gcc`, then link its `g++-NN` as `g++` ahead of Apple's (which is Clang) on your `PATH`.

## How it works

The engine is pure template metaprogramming. There are no `constexpr` functions, no
`if constexpr` and no lambdas, only class templates, partial specialisations, parameter
packs, and `static constexpr` members or enumerators that carry values.

- **State is a type.** `State<seed, score, lines, piece, next, x, y, rotation, tick, Board<rows...>>`
  holds the whole game. A board row is one number with 3 bits per cell. Each event is a
  metafunction from one state type to the next: `Event<S, 3>::type` is the state after a
  rotation, and `Event<S, 3>::draw` says whether it prints a frame.
- **Branching** is `If<cond, A, B>::type`, and only the chosen branch is ever
  instantiated, so the branches can be lazy metafunctions. Tables (masks, colours,
  points) are packs read back through an array member. Line clearing is a recursive
  filter over the row pack. The fit test is four masked ANDs against an occupancy
  array whose walls and floor are set bits, so it needs no bounds checks.
- **Input: the compiler can't read a live stream.** So the launcher keeps two headers in
  a temp dir, much as maketris restarts itself:
  `state.hpp` (`using S0 = Init<seed>;` at first, then the state the last run saved) and
  `events.hpp` (`using Game = Batch<S0, first, 0, 4, 1, ...>;`, the new events as a pack).
  It compiles, runs the binary, and repeats. A background reader appends stdin to a queue
  file while g++ works, and the next compile takes everything that has arrived, up to
  500 events. In `--pipe` mode the queue fills as fast as stdin delivers. A quit (`9`)
  ends the batch, and unknown codes are dropped by the template's catch-all
  specialisation.
- **Output.** The binary writes the batch's frames to stdout, writes the next `state.hpp`
  (`using S0 = State<...>;`, built as a char pack too) to fd 3, and exits with status 1 when
  the game is over. `main` is just two `write()` calls of `static constexpr` objects and
  a `return`.
- **Text is char packs.** String literals become `Str<'a','b',...>` through g++'s string
  literal operator template (`template<class T, T... c> Str<c...> operator""_s();`, a GNU
  extension). It is only declared and only ever named inside `decltype`. Numbers become
  digit packs by recursion. A frame is not one long pack, though. It is a `Text` of shared
  fragments: an object whose bases are `Leaf<0, T0>, Leaf<1, T1>, ...`, each holding a
  `char` array initialised from its pack. A frame is a Text of its 22 lines, and a batch is
  a Text of its frames, so the whole batch is one block of bytes that `main` writes in one
  call.

### Traps

Getting the speed right took longer than getting the game right. Some of the traps:

- **Symbol names.** The first version wrote each frame's `T::s` array directly. Every
  such array is a symbol whose mangled name spells out the whole pack, giving megabytes of
  names, and the assembler and linker choked on them. Copying the bytes into one
  `static constexpr` object inside `main` leaves only a handful of symbols.
- **Copying packs.** Gluing packs (`Str<a..., b...>`) copies every character into a new
  type, and g++ is slow at that. Building each frame as one 2.5 KB pack cost 20 s for 500
  events. Frames are now Texts of small memoised pieces. A line only depends on its row
  value and its panel text, so unchanged lines are the same instantiation from frame to
  frame.
- **`static constexpr` scalars are variables.** Thousands of instantiated
  `static constexpr int` members put a second into g++'s call-graph pass. Enumerators
  carry no storage and cost nothing there.
- **Nesting.** A recursive `Run<S, e, rest...>` instantiates the next state *inside* the
  current one, 500 levels deep, and g++ gets a little slower at each level (a lock costs
  about twice as much 800 levels down). So the batch is a fold over the events pack,
  `(start << ... << Ev<e>{})`, with an `operator<<` that is only declared and used in
  `decltype`. Overload resolution computes the states one after another at the top
  level. The drawn states are collected newest-first in a chain (`Node<S, rest>`, O(1)
  per step) and flattened once at the end, eight nodes per step.
- **Nested aggregates.** Any output object that nests deeply (a Text of a frame and the
  rest of the batch, or a type that *inherits* from a 300-deep chain) makes g++'s
  constant-initialiser code quadratic. Everything written out is kept flat.
- **Lazy means lazy.** Member typedefs are instantiated together with their class, and
  `&&` doesn't short-circuit instantiation. Anything that must not be computed for every
  state goes behind `If<...>::type::type`. `>>` inside a template argument list closes
  two lists, so shifts need parentheses there.

Timings on this machine (`tests/check.sh cpp`, 13,900 events, 3,557 frames): 25 to 35 s
for the whole suite, depending on load, or roughly 2 to 3 s per 500-event compile. Almost
all of that is template instantiation. An empty compile, including the link, takes 0.15 s.
The golfed version is a little slower, at 30 to 45 s.

The rules are shared with the other engines in this repo; see [`../SPEC.md`](../SPEC.md).
To run the engine on its own, write the two headers yourself:

```sh
t=$(mktemp -d)
echo 'using S0 = Init<42>;' > $t/state.hpp
echo 'using Game = Batch<S0, 1, 0, 1, 5>;' > $t/events.hpp   # first batch: tick, left, drop
g++ -std=c++17 -w -I $t -x c++ cpptris.cpp -o $t/game && $t/game 3>$t/next.hpp
cat $t/next.hpp                                               # the state for the next batch
```

or use the launcher's pipe mode: `(echo 42; echo 0; echo 1; echo 5) | ./cpptris.sh --pipe`.
`CPPTRIS_CHUNK` sets the batch size (default 500).

## Golfed version

[`cpptris.min.cpp`](cpptris.min.cpp) is the golfed twin of the engine: 3,980 bytes instead of 21,530 (82% smaller), with exactly the same output. `tests/check.sh --min cpp` replays it against the reference. [`../GOLFING.md`](../GOLFING.md) describes the techniques shared by all the engines. These are specific to C++ templates:

- **Keyword macros:** `T` is `template<long`, `TC` is `template<class`, and `V`, `G`, `K`, `U`, `Y`, `L` stand for `struct`, `enum`, `static constexpr`, `using`, `typename`, `long`. Every `int` and `bool` parameter became `long`, so almost every template header is `T x,L y>`.
- **Text without gluing:**
  - **Char arrays inside `Z`:** the char pack type `Z<c...>` holds its own array. Text is only ever composed (`W<a, b, ...>`), never concatenated, so the `Cat` template went.
  - **`sizeof` for the length:** a zero-length array (GNU) makes `Z<>` take 0 bytes, so `sizeof` of any Text is its exact length and the length enumerators went too. A leading `Z<>` keeps an empty batch at 0 bytes.
  - **String literals:** `S(x)` is `decltype(x""_)`. The empty literal with the suffix is concatenated onto `x`, so `x` can be a chain of literals and macros such as `B("│")` (`"\e[38;5;60m" x"\e[m"`). Each panel row is one literal.
- **Panel and cells:**
  - **The side panel is one pack:** `Pt<next,score,lines>` is a `W<row0, ..., row19>`. `Ix` deduces it into a pack `P...` and expands it next to the board rows, so the per-row specialisations went.
  - **Picking cells:** a declared-only `T i,C P>P g(N<i,P>);` picks the i-th leaf of a Text by deduction from a base class. The nine cell texts (dot, seven colours, two spaces) are one Text, and `g<(v>>3*j&7?:e)>` (GNU `?:`) picks each cell. The next-piece box is the same row renderer with 4 cells and blank 8.
- **State layout:**
  - **Board first:** the state is `Q<O<cleared,rows...>,x,y,r,tick,seed,score,lines,piece,next,over>`, which prints with one leading-comma list per pack.
  - **Clear count in the board:** the board's first parameter counts the rows the last clear removed. The clear filter writes it as it goes, and the lock reads it.
  - **Lock inside the state:** the clear recursion is a member template of the state, so it sees seed, score and lines without passing them along.
  - **Over flag:** `over` is a defaulted parameter that only a failed spawn sets. An over state turns every event into the unknown event 9.
  - **One index scaffold:** `Ix<>` holds the stamp, the frame and the save, all expanding the same row and index packs.
- **Board as a table:** the board type, not the state, holds the occupancy array. A `static constexpr` array in the state cost 0.5 ms per state, while boards only change on a lock. The fit test is a namespace template keyed on the board, so it is shared between states.
- **Shorter arithmetic:**
  - **One paint macro:** `A(i)` paints the piece into row i, for both the lock and the frame. It spreads the piece once (bit i → bit 3i) and multiplies by the colour.
  - **Gravity:** `k+l/10>8` replaces the level and gravity arithmetic.
  - **Walls:** `(j|j>>1|j>>2|~0x9249249l)*4096|4095` builds each wall and occupancy row in one go. It multiplies by 4096, because left-shifting a negative number isn't a constant expression.
- **Moves:** one `Tr<rotation, dx...>` tries offsets in order, giving left `Tr<r,-1>`, right `Tr<r,1>` and rotate `Tr<r+1&3,0,-1,1,-2,2>`. Hard drop recurses through the next state's own `Dr`.
- **What C++ refused:**
  - **Pasting:** `x##_` can't paste onto a macro call's `)`, so `S` uses `""_` instead.
  - **Suffixes:** `"..."x` in a macro body lexes as a user-defined literal, so it needs a space.
  - **pp-numbers:** `4095...` is one pp-number, so it needs a space too.
  - **`__integer_pack`:** it must be the entire pattern of its pack expansion, so it can't produce zeros directly, and the 21 zeros of the empty board stay literal.
  - **Shadowing:** member templates can't reuse the enclosing state's parameter names.
  - **Ambiguous specialisations:** `Cs<-1, P>` is ambiguous against `Cs<v, I<j...>>`, so the banner keeps the full pattern.

Earlier games in the same tool are listed under [Prior art](../README.md#prior-art) in the main README.
