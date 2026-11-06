// cpptris.cpp - a falling-block puzzle game played by the C++ compiler.
//
// Every rule of the game (see ../SPEC.md) is a template. The game state is a
// type, each event is a metafunction from one state type to the next, and the
// text of each frame is made of character packs. g++ works out a whole batch
// of events while it compiles this file; the program it produces only writes
// the finished bytes out.
//
// The launcher (cpptris.sh) supplies two headers in the include path:
//   state.hpp   using S0 = Init<seed>;  or  using S0 = State<...>;   (the state so far)
//   events.hpp  using Game = Batch<S0, first, e1, e2, ...>;          (the new events)
// The program writes the frames to stdout, the next state.hpp to fd 3, and exits
// with status 1 once the game is over.
//
// No constexpr functions, no `if constexpr`, no lambdas: just class templates,
// specialisations, packs, and static constexpr members to carry values.

#include <utility>   // std::integer_sequence, nothing else

extern "C" long write(int, const void *, unsigned long);

// ---- basics -------------------------------------------------------------------

template<class... T> struct List {};

// If<c, A, B>::type is A or B. Only the chosen type is ever instantiated, so
// the branches can be "lazy" metafunctions whose ::type is read afterwards.
template<bool C, class A, class B> struct If { using type = A; };
template<class A, class B> struct If<false, A, B> { using type = B; };

template<int N> using Ix = std::make_integer_sequence<int, N>;
template<int... i> using Seq = std::integer_sequence<int, i...>;

// A table is a pack, read back through an array member.
template<unsigned long... v> struct Table { static constexpr unsigned long at[] = {v...}; };

// ---- text ---------------------------------------------------------------------

// A piece of text is a char pack. (The arrays that end up in the program are
// made from these packs by Leaf, under "drawing".)
template<char... c> struct Str {
  using type = Str;
  enum : unsigned long { n = sizeof...(c) };
};

// String literals become packs through g++'s string literal operator template.
// It is only declared and only ever named inside decltype: "\e[m"_s is the
// type Str<'\e','[','m'>.
template<class T, T... c> Str<c...> operator""_s();
#define S(text) decltype(text##_s)

// Cat<A, B, ...>::type glues Str types together. Taking four at a time keeps
// the number of intermediate packs down.
template<class... T> struct Cat;
template<> struct Cat<> { using type = Str<>; };
template<char... a> struct Cat<Str<a...>> { using type = Str<a...>; };
template<char... a, char... b, class... T>
struct Cat<Str<a...>, Str<b...>, T...> : Cat<Str<a..., b...>, T...> {};
template<char... a, char... b, char... c, char... d, class... T>
struct Cat<Str<a...>, Str<b...>, Str<c...>, Str<d...>, T...>
    : Cat<Str<a..., b..., c..., d...>, T...> {};

// Decimal digits of N.
template<unsigned long N, bool Small = (N < 10)> struct Dec { using type = Str<char('0' + N)>; };
template<unsigned long N> struct Dec<N, false>
    : Cat<typename Dec<N / 10>::type, Str<char('0' + N % 10)>> {};

// Drop the first character (a leading comma, when serialising).
template<class T> struct Tail;
template<char c, char... r> struct Tail<Str<c, r...>> { using type = Str<r...>; };

// ---- the pieces ---------------------------------------------------------------

// Mask of piece p, rotation r is at[p*4 + r]; bit y*4 + x is box cell (x, y).
using Masks = Table<240, 17476, 3840, 8738,    // I
                    102, 102, 102, 102,        // O
                    114, 610, 624, 562,        // T
                    54, 1122, 864, 561,        // S
                    99, 612, 1584, 306,        // Z
                    113, 550, 1136, 802,       // J
                    116, 1570, 368, 547>;      // L
using Colours = Table<51, 226, 135, 46, 196, 33, 208>;
using Points = Table<0, 40, 100, 300, 1200>;

// The 4 bits of box row D of piece P in rotation R (0 outside the box).
template<int P, int R, int D> struct PieceRow {
  enum : unsigned { value = D >= 0 && D < 4 ? Masks::at[P * 4 + R] >> 4 * D & 15 : 0 };
};

// ---- the board ----------------------------------------------------------------
//
// A board row is one number with 3 bits per cell: cell c is (row >> 3c) & 7,
// 0 for empty or piece + 1. Board<r0, ..., r19> lists the rows from the top.
//
// Columns are stored with an offset of 4 (X = x + 4) so they are never
// negative. For the fit test each row also has an occupancy mask in the same
// 3-bit layout: bit 3(x + 4) is column x, every column outside 0..9 is set,
// and so are four whole rows below the board. A piece fits exactly when its
// cells miss the mask, so the walls and floor need no separate checks.

// Spread::at[b] spreads the 4 bits of b out to 3-bit cells: bit k goes to bit 3k.
template<class I> struct SpreadTable;
template<int... b> struct SpreadTable<Seq<b...>> {
  static constexpr unsigned long at[] = {(b & 1 | (b & 2) << 2 | (b & 4) << 4 | (b & 8) << 6)...};
};
using Spread = SpreadTable<Ix<16>>;

constexpr unsigned Full = 0x9249249;                         // bit 3c for the cells c = 0..9
constexpr unsigned long Columns = 0x1249249249249249;       // bit 3k for every column k
constexpr unsigned long Walls = Columns & ~(0ul + Full << 12);
template<unsigned V> struct Occ { enum : unsigned { value = (V | V >> 1 | V >> 2) & Full }; };

template<unsigned... V> struct Board {
  static constexpr unsigned row[] = {V...};
  static constexpr unsigned long occ[] = {(0ul + ((V | V >> 1 | V >> 2) & Full)) << 12 | Walls...,
                                          Columns, Columns, Columns, Columns};
};

// Paint the 4 bits Bits of a piece row in colour Col into row value V, with
// the box at column X - 4. (Shifting up by 3X and down by 12 avoids a
// negative shift when the box hangs over the left wall.)
template<unsigned V, unsigned Bits, unsigned Col, int X> struct Paint {
  enum : unsigned { value = V | unsigned(Spread::at[Bits] * Col << 3 * X >> 12) };
};

// Does piece P in rotation R fit with its box at (X - 4, Y)?
template<class B, int P, int R, int X, int Y> struct Fits {
  enum : bool { value = !((B::occ[Y] & Spread::at[PieceRow<P, R, 0>::value] << 3 * X) |
                          (B::occ[Y + 1] & Spread::at[PieceRow<P, R, 1>::value] << 3 * X) |
                          (B::occ[Y + 2] & Spread::at[PieceRow<P, R, 2>::value] << 3 * X) |
                          (B::occ[Y + 3] & Spread::at[PieceRow<P, R, 3>::value] << 3 * X)) };
};

// Write the piece into the board.
template<class B, int P, int R, int X, int Y, class I = Ix<20>> struct Stamp;
template<unsigned... V, int P, int R, int X, int Y, int... i>
struct Stamp<Board<V...>, P, R, X, Y, Seq<i...>> {
  using type = Board<Paint<V, PieceRow<P, R, i - Y>::value, P + 1, X>::value...>;
};

// Remove full rows: keep the others in order, then pad with empty rows on top.
template<class Kept, unsigned... V> struct Clear;
template<class I, unsigned... K> struct Pad;
template<int... i, unsigned... K> struct Pad<Seq<i...>, K...> { using type = Board<(i, 0u)..., K...>; };
template<unsigned... K> struct Clear<Board<K...>> {
  enum : int { rows = 20 - sizeof...(K) };
  using type = typename Pad<Ix<rows>, K...>::type;
};
template<unsigned... K, unsigned H, unsigned... V>
struct Clear<Board<K...>, H, V...>
    : Clear<typename If<Occ<H>::value == Full, Board<K...>, Board<K..., H>>::type, V...> {};
template<class B> struct ClearRows;
template<unsigned... V> struct ClearRows<Board<V...>> : Clear<Board<>, V...> {};

// ---- the state ----------------------------------------------------------------

template<unsigned long Seed, unsigned long Score, unsigned long Lines, int Cur, int Nxt,
         int X, int Y, int R, int T, class B, bool Over = false>
struct State {
  using type = State;   // a state is its own metafunction, handy inside If
  enum : unsigned long { seed = Seed, score = Score, lines = Lines };
  enum : int { cur = Cur, nxt = Nxt, x = X, y = Y, r = R, t = T };
  enum : bool { over = Over };
  using board = B;
  enum : int { level = int(Lines / 10 + 1) };
  enum : int { gravity = 11 - level > 1 ? 11 - level : 1 };
  template<int x2, int y2, int r2> using Fits = ::Fits<B, Cur, r2, x2, y2>;
};

// The same state with the piece moved, or with a new tick counter.
template<class S, int X, int Y, int R>
using Moved = State<S::seed, S::score, S::lines, S::cur, S::nxt, X, Y, R, S::t, typename S::board>;
template<class S, int T>
using Ticked = State<S::seed, S::score, S::lines, S::cur, S::nxt, S::x, S::y, S::r, T, typename S::board>;

// Park-Miller step.
template<unsigned long Seed> struct Rand { enum : unsigned long { value = Seed * 16807 % 2147483647 }; };

// The first state: draw the current piece, then the next one, then spawn.
template<unsigned long Seed> struct Start {
  enum : unsigned long { s1 = Rand<Seed>::value, s2 = Rand<s1>::value };
  using empty = typename Pad<Ix<20>>::type;
  using type = State<s2, 0, 0, s1 % 7, s2 % 7, 7, 0, 0, 0, empty, !Fits<empty, s1 % 7, 0, 7, 0>::value>;
};
template<unsigned long Seed> using Init = typename Start<Seed>::type;

// Lock the piece: stamp it, clear rows, score, and spawn the next piece.
template<class S> struct Lock {
  using cleared = ClearRows<typename Stamp<typename S::board, S::cur, S::r, S::x, S::y>::type>;
  using board = typename cleared::type;
  enum : int { n = cleared::rows };
  enum : unsigned long { seed = Rand<S::seed>::value };
  using type = State<seed, S::score + Points::at[n] * S::level, S::lines + n, S::nxt, seed % 7,
                     7, 0, 0, 0, board, !Fits<board, S::nxt, 0, 7, 0>::value>;
};

// Step down: one row lower if it fits, otherwise lock.
template<class S> struct StepDown
    : If<S::template Fits<S::x, S::y + 1, S::r>::value, Moved<S, S::x, S::y + 1, S::r>, Lock<S>>::type {};

// Hard drop: fall while it fits, then lock.
template<class S, bool Down = S::template Fits<S::x, S::y + 1, S::r>::value>
struct Drop : Drop<Moved<S, S::x, S::y + 1, S::r>> {};
template<class S> struct Drop<S, false> : Lock<S> {};

// Move sideways by D if it fits.
template<class S, int D> struct Shift
    : If<S::template Fits<S::x + D, S::y, S::r>::value, Moved<S, S::x + D, S::y, S::r>, S> {};

// Rotate clockwise, trying the kicks 0, -1, +1, -2, +2.
template<class S, int R = (S::r + 1) % 4> struct Rotate {
  template<int d> using F = typename S::template Fits<S::x + d, S::y, R>;
  enum : int { d = F<0>::value ? 0 : F<-1>::value ? -1 : F<1>::value ? 1
                         : F<-2>::value ? -2 : F<2>::value ? 2 : 9 };
  using type = typename If<d == 9, S, Moved<S, S::x + d, S::y, R>>::type;
};

// ---- events -------------------------------------------------------------------
//
// Event<S, e>::type is the next state; draw says whether a frame is printed.
// Unknown codes leave the state alone and draw nothing.
template<class S, long E> struct Event { using type = S; enum : bool { draw = false }; };
template<class S> struct Event<S, 0> {   // tick
  enum : bool { draw = S::t + 1 >= S::gravity };
  using type = typename If<draw, StepDown<Ticked<S, 0>>, Ticked<S, S::t + 1>>::type::type;
};
template<class S> struct Event<S, 1> { enum : bool { draw = true }; using type = typename Shift<S, -1>::type; };
template<class S> struct Event<S, 2> { enum : bool { draw = true }; using type = typename Shift<S, 1>::type; };
template<class S> struct Event<S, 3> { enum : bool { draw = true }; using type = typename Rotate<S>::type; };
template<class S> struct Event<S, 4> { enum : bool { draw = true }; using type = typename StepDown<S>::type; };
template<class S> struct Event<S, 5> { enum : bool { draw = true }; using type = typename Drop<S>::type; };

// ---- drawing ------------------------------------------------------------------
//
// Text<T...> is an object made of char arrays laid out back to back:
// Join<Ix<n>, T...> derives from Leaf<0, T0>, Leaf<1, T1>, ..., and a leaf
// holds either a char array initialised from a Str's pack or another Join.
// Frames are built as Texts of small shared Strs, never as one long pack:
// gluing packs means copying every character into a new type, and g++ is slow
// at that, while a Text of 15 fragments is one small instantiation.
template<int I, class T> struct Leaf { T s; };
template<int I, char... c> struct Leaf<I, Str<c...>> { char s[sizeof...(c)] = {c...}; };
template<int I> struct Leaf<I, Str<>> {};
template<class I, class... T> struct Join;
template<int... i, class... T> struct Join<Seq<i...>, T...> : Leaf<i, T>... {
  using type = Join;
  enum : unsigned long { n = (0ul + ... + T::n) };
};
template<class... T> using Text = Join<Ix<sizeof...(T)>, T...>;

using Reset = S("\e[m");
template<class T> using Border = typename Cat<S("\e[38;5;60m"), T, Reset>::type;
template<class T> using Dim = typename Cat<S("\e[38;5;244m"), T, Reset>::type;
using Eol = S("\e[K\n");

// One board cell: dot when empty, colour k - 1 when filled.
template<unsigned K> struct Cell
    : Cat<S("\e[38;5;"), typename Dec<Colours::at[K - 1]>::type, S("m██"), Reset> {};
template<> struct Cell<0> : S("\e[38;5;237m ·\e[m") {};

// The ten cells of a row value, or the game-over banner for ~0.
template<unsigned V, class I = Ix<10>> struct Cells;
template<unsigned V, int... c> struct Cells<V, Seq<c...>> : Text<typename Cell<(V >> 3 * c & 7)>::type...> {};
template<int... c> struct Cells<~0u, Seq<c...>> : S("\e[1;7m     GAME  OVER     \e[m") {};

// The side panel, by board row. Only rows 2-5, 10 and 11 change.
using Indent = S("   ");
using Bold = S("\e[1m");
template<int Y> struct Fixed { using type = Str<>; };
template<> struct Fixed<0> : Cat<Indent, Border<S("╭──")>, S(" "), Dim<S("next")>, S(" "), Border<S("──────╮")>> {};
template<> struct Fixed<1> : Cat<Indent, Border<S("│")>, S("              "), Border<S("│")>> {};
template<> struct Fixed<6> : Fixed<1> {};
template<> struct Fixed<7> : Cat<Indent, Border<S("╰──────────────╯")>> {};
template<> struct Fixed<9> : Cat<Indent, Dim<S("score")>> {};
template<> struct Fixed<13> : Cat<Indent, Dim<S("controls")>> {};
template<class K, class A> using Key = Cat<Indent, Bold, K, Reset, S("  "), Dim<A>>;
template<> struct Fixed<14> : Key<S("← a"), S("move left")> {};
template<> struct Fixed<15> : Key<S("→ d"), S("move right")> {};
template<> struct Fixed<16> : Key<S("↑ w"), S("rotate")> {};
template<> struct Fixed<17> : Key<S("↓ s"), S("soft drop")> {};
template<> struct Fixed<18> : Key<S("␣ z"), S("hard drop")> {};
template<> struct Fixed<19> : Key<S("  q"), S("quit")> {};

// One row of the next-piece box: four cells, two characters each.
using BoxLeft = Cat<Indent, Border<S("│")>, Indent>::type;
using BoxRight = Cat<Indent, Border<S("│")>>::type;
template<int N, unsigned Bits, class I = Ix<4>> struct NextRow;
template<int N, unsigned Bits, int... k> struct NextRow<N, Bits, Seq<k...>>
    : Text<BoxLeft, typename If<(Bits >> k & 1), Cell<N + 1>, S("  ")>::type::type..., BoxRight> {};

template<int Y, int N, unsigned long Score, unsigned long Lines> struct Panel : Fixed<Y> {};
template<int N, unsigned long Sc, unsigned long Li> struct Panel<2, N, Sc, Li> : NextRow<N, PieceRow<N, 0, 0>::value> {};
template<int N, unsigned long Sc, unsigned long Li> struct Panel<3, N, Sc, Li> : NextRow<N, PieceRow<N, 0, 1>::value> {};
template<int N, unsigned long Sc, unsigned long Li> struct Panel<4, N, Sc, Li> : NextRow<N, PieceRow<N, 0, 2>::value> {};
template<int N, unsigned long Sc, unsigned long Li> struct Panel<5, N, Sc, Li> : NextRow<N, PieceRow<N, 0, 3>::value> {};
using IndentBold = Cat<Indent, Bold>::type;
using LevelLabel = Cat<Indent, Dim<S("level")>, S(" "), Bold>::type;
using LinesLabel = Cat<Reset, S("  "), Dim<S("lines")>, S(" "), Bold>::type;
template<int N, unsigned long Sc, unsigned long Li> struct Panel<10, N, Sc, Li>
    : Text<IndentBold, typename Dec<Sc>::type, Reset> {};
template<int N, unsigned long Sc, unsigned long Li> struct Panel<11, N, Sc, Li>
    : Text<LevelLabel, typename Dec<Li / 10 + 1>::type, LinesLabel, typename Dec<Li>::type, Reset> {};

// A whole board line. It only depends on the row's cells and its panel text,
// so g++ reuses the same instantiation for every frame where they are unchanged.
using Wall = Cat<S(" "), Border<S("║")>>::type;
template<unsigned V, class P> struct Line
    : Text<Wall, typename Cells<V>::type, Border<S("║")>, P, Eol> {};

using Top = Cat<S("\e[H  \e[1;38;5;75mC P P T R I S\e[m\e[K\n "), Border<S("╔════════════════════╗")>, Eol>::type;
using Bottom = Cat<S(" "), Border<S("╚════════════════════╝")>, Eol, S("\e[J")>::type;

// Board row y as shown: the row with the falling piece painted over it, or
// the banner (~0) on row 9 once the game is over. This is worked out inline
// rather than by a helper template: a template here would be instantiated
// 20 times for every frame.
template<class S, class I = Ix<20>> struct Frame;
template<class S, int... y> struct Frame<S, Seq<y...>> {
  using B = typename S::board;
  using type = Text<Top,
      typename Line<S::over ? (y == 9 ? ~0u : B::row[y])
                            : B::row[y] | unsigned(Spread::at[PieceRow<S::cur, S::r, y - S::y>::value] * (S::cur + 1)
                                                   << 3 * S::x >> 12),
                    typename Panel<y, S::nxt, S::score, S::lines>::type>::type...,
      Bottom>;
};

// ---- a batch of events ------------------------------------------------------------
//
// Played<Frames, S> is the game so far: the states to draw and the current
// state. The states to draw are a chain, newest first: Node<S, Node<..., End>>.
// Play<P, e> applies one event to it. Once the game is over, later events are
// ignored.
struct End {};
template<class S, class Rest> struct Node {};
template<class Frames, class S> struct Played { using frames = Frames; using last = S; };
template<class P, long E, bool Over = P::last::over> struct Play { using type = P; };
template<class F, class S, long E> struct Play<Played<F, S>, E, false> {
  using ev = Event<S, E>;
  using next = typename ev::type;
  using type = Played<typename If<ev::draw, Node<next, F>, F>::type, next>;
};

// Flatten<chain, List<>>::type is the chain as a List, oldest first. It peels
// eight nodes per step.
template<class F, class L> struct Flatten;
template<class... A> struct Flatten<End, List<A...>> { using type = List<A...>; };
template<class a, class R, class... A> struct Flatten<Node<a, R>, List<A...>> : Flatten<R, List<a, A...>> {};
template<class a, class b, class c, class d, class e, class f, class g, class h, class R, class... A>
struct Flatten<Node<a, Node<b, Node<c, Node<d, Node<e, Node<f, Node<g, Node<h, R>>>>>>>>, List<A...>>
    : Flatten<R, List<h, g, f, e, d, c, b, a, A...>> {};

// The batch is a fold over the events pack: (start << e1) << e2 << ... with an
// operator<< that is only declared, never defined, and only used inside
// decltype. Overload resolution works out each step's type, so g++
// instantiates the states one after another at the top level. A recursive
// template would nest 500 instantiations inside each other instead, and g++
// gets slower at every level of nesting.
template<long E> struct Ev {};
template<class P, long E> typename Play<P, E>::type operator<<(P, Ev<E>);

// The output of a batch is one object made of char arrays laid out back to
// back. A frame is a Text of its 22 lines, a batch a Text of its frames, and
// main() writes the whole object's bytes in one go. The first batch of a game
// also draws the starting state.
template<class L> struct Output;
template<class... S> struct Output<List<S...>> { using type = Text<typename Frame<S>::type...>; };
template<class S, bool First, long... E> struct Batch {
  using played = decltype((Played<typename If<First, Node<S, End>, End>::type, S>{} << ... << Ev<E>{}));
  using out = typename Output<typename Flatten<typename played::frames, List<>>::type>::type;
  using last = typename played::last;
  enum : int { ended = last::over };
};

// ---- the next state, as C++ source ----------------------------------------------

template<long N> using Num = Cat<S(","), typename Dec<N>::type>;
template<class S> struct Save;
template<unsigned long Seed, unsigned long Score, unsigned long Lines, int Cur, int Nxt,
         int X, int Y, int R, int T, unsigned... V, bool Over>
struct Save<State<Seed, Score, Lines, Cur, Nxt, X, Y, R, T, Board<V...>, Over>>
    : Cat<S("using S0 = State<"),
          typename Tail<typename Cat<typename Num<Seed>::type, typename Num<Score>::type, typename Num<Lines>::type,
                                     typename Num<Cur>::type, typename Num<Nxt>::type, typename Num<X>::type,
                                     typename Num<Y>::type, typename Num<R>::type, typename Num<T>::type>::type>::type,
          S(",Board<"), typename Tail<typename Cat<typename Num<V>::type...>::type>::type, S(">>;\n")> {};

// ---- this batch -------------------------------------------------------------------

#include "state.hpp"
#include "events.hpp"

int main() {
  static constexpr Game::out frames{};
  static constexpr Text<Save<Game::last>::type> next{};
  static_assert(sizeof frames == frames.n || !frames.n, "the leaves are back to back");
  write(1, &frames, frames.n);
  write(3, &next, next.n);
  return Game::ended;
}
