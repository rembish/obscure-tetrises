/* preprocessortris.h - a falling-block puzzle game written in the C preprocessor.

   Run by GCC's preprocessor in traditional mode, once per event:

     cpp -P -traditional-cpp -include state.h -DEV=3 preprocessortris.h

   The preprocessor can't loop, and it can't change a macro to a value it has
   just computed. So every run plays one step and prints the next state, and
   the launcher feeds that back in as the next run's state.h: the preprocessor
   is Turing complete only when its output is fed back to it.

   Input. state.h holds function-like macros: SEED() CUR() NXT() PX() PY()
   ROT() TICK() SCORE() LINES() LEVEL() PHASE() and the board rows
   ROW0() .. ROW19(). Before the first run it holds only START(), the seed.
   EV is the event number (SPEC.md: 0 tick, 1 left, 2 right, 3 rotate, 4 soft
   drop, 5 hard drop; quit never gets here).

   Output. Lines starting with % are the next state, "@NAME value", several
   to a line; the launcher writes each as "#define NAME() value". All other
   non-empty lines are the frame. (Every directive leaves an empty line in the
   output, which the launcher drops; frame lines are never empty.) When the game
   is over the run prints the game-over frame and no state.

   A lock takes three runs. PHASE() says which one comes next, and the
   launcher runs the engine again, without a new event, until PHASE() is 0:
     0  play the event; if the piece locks, write it into the board -> 1
     1  remove full rows, add score and lines                       -> 2
     2  take the next piece and spawn it; game over if it doesn't fit -> 0

   Values. A board row is the number 1d0d1...d9: a leading 1, then one
   decimal digit per cell, column 0 first (0 empty, piece + 1 filled). PX() is
   the column plus 3, so it is never negative. A value that changes a little,
   like PY() + 1, is printed as that expression; it grows only until the next
   spawn, which writes plain numbers again. Rows, the seed, score, lines and
   level are printed as plain numbers by the digit printer below.

   Traditional mode keeps spaces exactly as written, which the frame needs.
   It also can't build a macro name from computed parts, so some things are
   spelled out: the digit printer has one block per digit position, and the
   row table at the end has one entry per board row. This file includes itself
   to run those parts: with V defined it is the digit printer, with RY defined
   it is the code for one board row. */

#if !defined(V) && !defined(RY) && !defined(TABLE) && !defined(MK)
/* The parts below run often: twenty rows per frame, and the digit printer for
   each of them. They are reached by including a file, and GCC's traditional mode
   expands the macros on every #if line it skips on the way, including all of
   the main part's fit tests. So the launcher copies the parts block into a file
   of its own and passes it as PARTS; without that the engine includes itself,
   which gives the same output, only slower. */
#ifndef PARTS
#define PARTS __FILE__
#endif
/* ---- main ----------------------------------------------------------------- */

/* Output pieces. E() is the escape character itself (a raw byte here, since
   the preprocessor has no escape sequences outside strings). */
#define E() 
#define RS() E()[m
#define BC() E()[38;5;60m
#define DM() E()[38;5;244m
#define BOLD() E()[1m
#define TC() E()[1;38;5;75m
#define EOL() E()[K
/* W(text) is just text. It ends a word that is followed by a macro call
   (nextRS() would be one name), and it keeps spaces that a macro body
   would lose at its start or end. */
#define W(x) x

/* Fonts for the digit printer: plain digits, or cell glyphs. */
#define DIGITFONT 1
#define CELLFONT 2

/* Tables. MASK(p, r): rotation r of piece p as bits y*4+x. */
#define MASK(p, r) ((p) == 0 ? ((r) == 0 ? 240 : (r) == 1 ? 17476 : (r) == 2 ? 3840 : 8738) \
                  : (p) == 1 ? 102 \
                  : (p) == 2 ? ((r) == 0 ? 114 : (r) == 1 ? 610 : (r) == 2 ? 624 : 562) \
                  : (p) == 3 ? ((r) == 0 ? 54 : (r) == 1 ? 1122 : (r) == 2 ? 864 : 561) \
                  : (p) == 4 ? ((r) == 0 ? 99 : (r) == 1 ? 612 : (r) == 2 ? 1584 : 306) \
                  : (p) == 5 ? ((r) == 0 ? 113 : (r) == 1 ? 550 : (r) == 2 ? 1136 : 802) \
                  : ((r) == 0 ? 116 : (r) == 1 ? 1570 : (r) == 2 ? 368 : 547))
#define BIT(m, i) ((m) >> (i) & 1)
#define P10(e) ((e) == 0 ? 1 : (e) == 1 ? 10 : (e) == 2 ? 100 : (e) == 3 ? 1000 \
              : (e) == 4 ? 10000 : (e) == 5 ? 100000 : (e) == 6 ? 1000000 \
              : (e) == 7 ? 10000000 : (e) == 8 ? 100000000 : 1000000000)
#define POINTS(n) ((n) == 1 ? 40 : (n) == 2 ? 100 : (n) == 3 ? 300 : (n) == 4 ? 1200 : 0)
#define RAND(s) ((s) * 16807 % 2147483647)
#define EMPTYROW 10000000000

/* The board. ROWOF(k) is row k; CELL(y, x) is a cell, 9 off the board. */
#define ROWOF(k) ((k) == 0 ? ROW0() : (k) == 1 ? ROW1() : (k) == 2 ? ROW2() : (k) == 3 ? ROW3() \
                : (k) == 4 ? ROW4() : (k) == 5 ? ROW5() : (k) == 6 ? ROW6() : (k) == 7 ? ROW7() \
                : (k) == 8 ? ROW8() : (k) == 9 ? ROW9() : (k) == 10 ? ROW10() : (k) == 11 ? ROW11() \
                : (k) == 12 ? ROW12() : (k) == 13 ? ROW13() : (k) == 14 ? ROW14() : (k) == 15 ? ROW15() \
                : (k) == 16 ? ROW16() : (k) == 17 ? ROW17() : (k) == 18 ? ROW18() : ROW19())
#define DIGIT(row, x) ((row) / P10(9 - (x)) % 10)
#define CELL(y, x) ((y) < 0 || (y) > 19 || (x) < 0 || (x) > 9 ? 9 : DIGIT(ROWOF(y), x))

/* FITS(m, x, y): mask m with its box at column x, row y lies on empty cells. */
#define FITCELL(m, i, x, y) (!BIT(m, i) || CELL((y) + (i) / 4, (x) + (i) % 4) == 0)
#define FITS(m, x, y) (FITCELL(m, 0, x, y) && FITCELL(m, 1, x, y) && FITCELL(m, 2, x, y) \
  && FITCELL(m, 3, x, y) && FITCELL(m, 4, x, y) && FITCELL(m, 5, x, y) && FITCELL(m, 6, x, y) \
  && FITCELL(m, 7, x, y) && FITCELL(m, 8, x, y) && FITCELL(m, 9, x, y) && FITCELL(m, 10, x, y) \
  && FITCELL(m, 11, x, y) && FITCELL(m, 12, x, y) && FITCELL(m, 13, x, y) \
  && FITCELL(m, 14, x, y) && FITCELL(m, 15, x, y))

/* ON(m, x, y, ry, cx): the piece m at (x, y) covers cell (ry, cx). */
#define ON(m, x, y, ry, cx) ((ry) >= (y) && (ry) < (y) + 4 && (cx) >= (x) && (cx) < (x) + 4 \
                             && BIT(m, ((ry) - (y)) * 4 + (cx) - (x)))
/* A row with the piece m of colour value v at (x, y) written into it. */
#define WITHPIECE(row, ry, m, x, y, v) ((row) + (v) * (ON(m, x, y, ry, 0) * 1000000000 \
  + ON(m, x, y, ry, 1) * 100000000 + ON(m, x, y, ry, 2) * 10000000 + ON(m, x, y, ry, 3) * 1000000 \
  + ON(m, x, y, ry, 4) * 100000 + ON(m, x, y, ry, 5) * 10000 + ON(m, x, y, ry, 6) * 1000 \
  + ON(m, x, y, ry, 7) * 100 + ON(m, x, y, ry, 8) * 10 + ON(m, x, y, ry, 9)))

/* The current piece. */
#define X() (PX() - 3)
#define M() MASK(CUR(), ROT())
#define GRAVITY() (11 - LEVEL() > 1 ? 11 - LEVEL() : 1)

/* KEEP(k) prints row k unchanged; ROWS(F) does F for every row. */
#define KEEP(k) @ROW/**/k ROW/**/k()
#define ROWS(F) F(0)F(1)F(2)F(3)F(4)F(5)F(6)F(7)F(8)F(9)F(10)F(11)F(12)F(13)F(14)F(15)F(16)F(17)F(18)F(19)

/* What the run prints, unless a phase below says otherwise. */
#define NSEED() SEED()
#define NCUR() CUR()
#define NNXT() NXT()
#define NPX() PX()
#define NPY() PY()
#define NROT() ROT()
#define NTICK() TICK()
#define NPHASE() 0
#define ROWSCHANGE 0
#define DRAW 0
#define ENDED 0   /* game over; not OVER, which the frame prints as a word */

#ifdef START
/* ---- first run: an empty board; the spawn phase draws the first two pieces */
#define V() RAND(START())
#define F0() 0
#define F1() 1
#define F2() 2
#define F3() 3
#define F4() 4
#define F5() 5
#define F6() 6
#define F7() 7
#define F8() 8
#define F9() 9
#include PARTS
@SEED D10()D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()@NXT (RAND(START()) % 7)@CUR 0@PX 6@PY 0@ROT 0@TICK 0
@SCORE 0@LINES 0@LEVEL 1@PHASE 2
#define EMPTY(k) @ROW/**/k 10000000000
ROWS(EMPTY)

#else
#if PHASE() == 0
/* ---- phase 0: play the event ------------------------------------------- */
#if EV == 0 && TICK() + 1 < GRAVITY()
#undef NTICK
#define NTICK() (TICK() + 1)
#elif EV == 0 || EV == 4
#if FITS(M(), X(), PY() + 1)
#undef NPY
#define NPY() (PY() + 1)
#undef DRAW
#define DRAW 1
#else
#undef NPHASE
#define NPHASE() 1
#undef ROWSCHANGE
#define ROWSCHANGE 1
#endif
#if EV == 0
#undef NTICK
#define NTICK() 0
#endif
#elif EV == 1 || EV == 2
#if FITS(M(), X() + 2 * EV - 3, PY())
#undef NPX
#define NPX() (PX() + 2 * EV - 3)
#endif
#undef DRAW
#define DRAW 1
#elif EV == 3
#define RM() MASK(CUR(), (ROT() + 1) % 4)
#if FITS(RM(), X(), PY())
#define KICK 0
#elif FITS(RM(), X() - 1, PY())
#define KICK -1
#elif FITS(RM(), X() + 1, PY())
#define KICK 1
#elif FITS(RM(), X() - 2, PY())
#define KICK -2
#elif FITS(RM(), X() + 2, PY())
#define KICK 2
#endif
#ifdef KICK
#undef NPX
#define NPX() (PX() + KICK)
#undef NROT
#define NROT() ((ROT() + 1) % 4)
#endif
#undef DRAW
#define DRAW 1
#elif EV == 5
/* hard drop: the lowest row the piece still fits on, then lock */
#undef NPY
#if !FITS(M(), X(), PY() + 1)
#define NPY() PY()
#elif !FITS(M(), X(), PY() + 2)
#define NPY() (PY() + 1)
#elif !FITS(M(), X(), PY() + 3)
#define NPY() (PY() + 2)
#elif !FITS(M(), X(), PY() + 4)
#define NPY() (PY() + 3)
#elif !FITS(M(), X(), PY() + 5)
#define NPY() (PY() + 4)
#elif !FITS(M(), X(), PY() + 6)
#define NPY() (PY() + 5)
#elif !FITS(M(), X(), PY() + 7)
#define NPY() (PY() + 6)
#elif !FITS(M(), X(), PY() + 8)
#define NPY() (PY() + 7)
#elif !FITS(M(), X(), PY() + 9)
#define NPY() (PY() + 8)
#elif !FITS(M(), X(), PY() + 10)
#define NPY() (PY() + 9)
#elif !FITS(M(), X(), PY() + 11)
#define NPY() (PY() + 10)
#elif !FITS(M(), X(), PY() + 12)
#define NPY() (PY() + 11)
#elif !FITS(M(), X(), PY() + 13)
#define NPY() (PY() + 12)
#elif !FITS(M(), X(), PY() + 14)
#define NPY() (PY() + 13)
#elif !FITS(M(), X(), PY() + 15)
#define NPY() (PY() + 14)
#elif !FITS(M(), X(), PY() + 16)
#define NPY() (PY() + 15)
#elif !FITS(M(), X(), PY() + 17)
#define NPY() (PY() + 16)
#elif !FITS(M(), X(), PY() + 18)
#define NPY() (PY() + 17)
#elif !FITS(M(), X(), PY() + 19)
#define NPY() (PY() + 18)
#else
#define NPY() (PY() + 19)
#endif
#undef NPHASE
#define NPHASE() 1
#undef ROWSCHANGE
#define ROWSCHANGE 1
#endif
/* the new rows when the piece locks: written in where it lies */
#define MK() M()
#include PARTS
#define LOCKMASK FROZEN
#define NEWROW(k) WITHPIECE(ROWOF(k), k, LOCKMASK, X(), NPY(), CUR() + 1)
#define CHANGED(k) ((k) >= NPY() && (k) <= NPY() + 3)

#elif PHASE() == 1
/* ---- phase 1: remove full rows ------------------------------------------
   Only the four rows the piece lies on can be full. A row that stays moves
   down by the number of full rows below it, so new row j is old row j - m
   for the m in 0..4 that fits, or empty if none does. */
#define FULLROW(r) (DIGIT(r, 0) && DIGIT(r, 1) && DIGIT(r, 2) && DIGIT(r, 3) && DIGIT(r, 4) \
                    && DIGIT(r, 5) && DIGIT(r, 6) && DIGIT(r, 7) && DIGIT(r, 8) && DIGIT(r, 9))
#if PY() + 0 <= 19 && FULLROW(ROWOF(PY() + 0))
#define FULL0 1
#else
#define FULL0 0
#endif
#if PY() + 1 <= 19 && FULLROW(ROWOF(PY() + 1))
#define FULL1 1
#else
#define FULL1 0
#endif
#if PY() + 2 <= 19 && FULLROW(ROWOF(PY() + 2))
#define FULL2 1
#else
#define FULL2 0
#endif
#if PY() + 3 <= 19 && FULLROW(ROWOF(PY() + 3))
#define FULL3 1
#else
#define FULL3 0
#endif
#define FULL(k) ((k) == PY() ? FULL0 : (k) == PY() + 1 ? FULL1 : (k) == PY() + 2 ? FULL2 \
                 : (k) == PY() + 3 ? FULL3 : 0)
#define BELOW(s) (((s) < PY()) * FULL(PY()) + ((s) < PY() + 1) * FULL(PY() + 1) \
                  + ((s) < PY() + 2) * FULL(PY() + 2) + ((s) < PY() + 3) * FULL(PY() + 3))
#define FROM(j, m) ((j) - (m) >= 0 && !FULL((j) - (m)) && BELOW((j) - (m)) == (m))
#define NEWROW(j) (FROM(j, 0) ? ROWOF(j) : FROM(j, 1) ? ROWOF((j) - 1) : FROM(j, 2) ? ROWOF((j) - 2) \
                   : FROM(j, 3) ? ROWOF((j) - 3) : FROM(j, 4) ? ROWOF((j) - 4) : EMPTYROW)
#define CLEARED (FULL0 + FULL1 + FULL2 + FULL3)
#define CHANGED(k) ((k) <= PY() + 3)
#undef NPHASE
#define NPHASE() 2
#if CLEARED
#undef ROWSCHANGE
#define ROWSCHANGE 1
#endif

#else
/* ---- phase 2: spawn the next piece --------------------------------------- */
#undef NCUR
#define NCUR() NXT()
#undef NNXT
#define NNXT() (RAND(SEED()) % 7)
#undef NPX
#define NPX() 6
#undef NPY
#define NPY() 0
#undef NROT
#define NROT() 0
#undef NTICK
#define NTICK() 0
#undef DRAW
#define DRAW 1
#if !FITS(MASK(NXT(), 0), 3, 0)
#undef ENDED
#define ENDED 1
#endif
#endif

/* ---- the frame ------------------------------------------------------------- */
#if DRAW
#define MK() MASK(NCUR(), NROT())
#include PARTS
#define SHOWMASK FROZEN
/* the next-piece box: bit (row b, column i) of rotation 0 */
#define NEXTBIT(b, i) BIT(MASK(NNXT(), 0), (b) * 4 + (i))
#undef F0
#undef F1
#undef F2
#undef F3
#undef F4
#undef F5
#undef F6
#undef F7
#define F0() E()[38;5;237m ·RS()
#define F1() E()[38;5;51m██RS()
#define F2() E()[38;5;226m██RS()
#define F3() E()[38;5;135m██RS()
#define F4() E()[38;5;46m██RS()
#define F5() E()[38;5;196m██RS()
#define F6() E()[38;5;33m██RS()
#define F7() E()[38;5;208m██RS()
#if NNXT() == 0
#define NB() F1()
#elif NNXT() == 1
#define NB() F2()
#elif NNXT() == 2
#define NB() F3()
#elif NNXT() == 3
#define NB() F4()
#elif NNXT() == 4
#define NB() F5()
#elif NNXT() == 5
#define NB() F6()
#else
#define NB() F7()
#endif
E()[H  TC()W(P R E P R O C E S S O R T R I S)RS()EOL()
 BC()╔════════════════════╗RS()EOL()
#define MODE 1
#define TABLE
#include PARTS
#undef TABLE
 BC()╚════════════════════╝RS()EOL()
#endif

/* ---- the next state, unless the game is over -------------------------------- */
#if !ENDED
#undef F0
#undef F1
#undef F2
#undef F3
#undef F4
#undef F5
#undef F6
#undef F7
#undef F8
#undef F9
#define F0() 0
#define F1() 1
#define F2() 2
#define F3() 3
#define F4() 4
#define F5() 5
#define F6() 6
#define F7() 7
#define F8() 8
#define F9() 9
@CUR NCUR()@NXT NNXT()@PX NPX()@PY NPY()@ROT NROT()@TICK NTICK()@PHASE NPHASE()
#if PHASE() == 2
#define V() RAND(SEED())
#include PARTS
@SEED D10()D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#else
@SEED SEED()
#endif
#if PHASE() == 1 && CLEARED
#define V() (SCORE() + POINTS(CLEARED) * LEVEL())
#include PARTS
@SCORE D10()D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#define V() (LINES() + CLEARED)
#include PARTS
@LINES D10()D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#define V() ((LINES() + CLEARED) / 10 + 1)
#include PARTS
@LEVEL D10()D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#else
@SCORE SCORE()@LINES LINES()@LEVEL LEVEL()
#endif
#if ROWSCHANGE
#undef MODE
#define MODE 2
#define TABLE
#include PARTS
#undef TABLE
#else
ROWS(KEEP)
#endif
#endif
#endif
#else
/*{ ---- parts begin (the launcher copies from here to the closing marker) ---- */
#ifdef MK
/* ---- a mask as a plain number: FROZEN is the value of MK() ------------------
   As an expression, the MASK table would be expanded again at every use. */
#undef FROZEN
#if MK() == 54
#define FROZEN 54
#elif MK() == 99
#define FROZEN 99
#elif MK() == 102
#define FROZEN 102
#elif MK() == 113
#define FROZEN 113
#elif MK() == 114
#define FROZEN 114
#elif MK() == 116
#define FROZEN 116
#elif MK() == 240
#define FROZEN 240
#elif MK() == 306
#define FROZEN 306
#elif MK() == 368
#define FROZEN 368
#elif MK() == 547
#define FROZEN 547
#elif MK() == 550
#define FROZEN 550
#elif MK() == 561
#define FROZEN 561
#elif MK() == 562
#define FROZEN 562
#elif MK() == 610
#define FROZEN 610
#elif MK() == 612
#define FROZEN 612
#elif MK() == 624
#define FROZEN 624
#elif MK() == 802
#define FROZEN 802
#elif MK() == 864
#define FROZEN 864
#elif MK() == 1122
#define FROZEN 1122
#elif MK() == 1136
#define FROZEN 1136
#elif MK() == 1570
#define FROZEN 1570
#elif MK() == 1584
#define FROZEN 1584
#elif MK() == 3840
#define FROZEN 3840
#elif MK() == 8738
#define FROZEN 8738
#elif MK() == 17476
#define FROZEN 17476
#endif
#undef MK

#elif defined(V)
/* ---- digit printer --------------------------------------------------------
   Prints the decimal digits of V() as D10() .. D0(). Leading zeros are left
   out (D0 is always there). Each digit is F0() .. F9() of the current font:
   plain digits, or cell glyphs when a board row is drawn. */
#undef D10
#if V() < 10000000000
#define D10()
#elif V() / 10000000000 % 10 == 1
#define D10() F1()
#elif V() / 10000000000 % 10 == 2
#define D10() F2()
#else
#define D10() F9()
#endif
#undef D9
#if V() < 1000000000
#define D9()
#elif V() / 1000000000 % 10 == 0
#define D9() F0()
#elif V() / 1000000000 % 10 == 1
#define D9() F1()
#elif V() / 1000000000 % 10 == 2
#define D9() F2()
#elif V() / 1000000000 % 10 == 3
#define D9() F3()
#elif V() / 1000000000 % 10 == 4
#define D9() F4()
#elif V() / 1000000000 % 10 == 5
#define D9() F5()
#elif V() / 1000000000 % 10 == 6
#define D9() F6()
#elif V() / 1000000000 % 10 == 7
#define D9() F7()
#elif V() / 1000000000 % 10 == 8
#define D9() F8()
#else
#define D9() F9()
#endif
#undef D8
#if V() < 100000000
#define D8()
#elif V() / 100000000 % 10 == 0
#define D8() F0()
#elif V() / 100000000 % 10 == 1
#define D8() F1()
#elif V() / 100000000 % 10 == 2
#define D8() F2()
#elif V() / 100000000 % 10 == 3
#define D8() F3()
#elif V() / 100000000 % 10 == 4
#define D8() F4()
#elif V() / 100000000 % 10 == 5
#define D8() F5()
#elif V() / 100000000 % 10 == 6
#define D8() F6()
#elif V() / 100000000 % 10 == 7
#define D8() F7()
#elif V() / 100000000 % 10 == 8
#define D8() F8()
#else
#define D8() F9()
#endif
#undef D7
#if V() < 10000000
#define D7()
#elif V() / 10000000 % 10 == 0
#define D7() F0()
#elif V() / 10000000 % 10 == 1
#define D7() F1()
#elif V() / 10000000 % 10 == 2
#define D7() F2()
#elif V() / 10000000 % 10 == 3
#define D7() F3()
#elif V() / 10000000 % 10 == 4
#define D7() F4()
#elif V() / 10000000 % 10 == 5
#define D7() F5()
#elif V() / 10000000 % 10 == 6
#define D7() F6()
#elif V() / 10000000 % 10 == 7
#define D7() F7()
#elif V() / 10000000 % 10 == 8
#define D7() F8()
#else
#define D7() F9()
#endif
#undef D6
#if V() < 1000000
#define D6()
#elif V() / 1000000 % 10 == 0
#define D6() F0()
#elif V() / 1000000 % 10 == 1
#define D6() F1()
#elif V() / 1000000 % 10 == 2
#define D6() F2()
#elif V() / 1000000 % 10 == 3
#define D6() F3()
#elif V() / 1000000 % 10 == 4
#define D6() F4()
#elif V() / 1000000 % 10 == 5
#define D6() F5()
#elif V() / 1000000 % 10 == 6
#define D6() F6()
#elif V() / 1000000 % 10 == 7
#define D6() F7()
#elif V() / 1000000 % 10 == 8
#define D6() F8()
#else
#define D6() F9()
#endif
#undef D5
#if V() < 100000
#define D5()
#elif V() / 100000 % 10 == 0
#define D5() F0()
#elif V() / 100000 % 10 == 1
#define D5() F1()
#elif V() / 100000 % 10 == 2
#define D5() F2()
#elif V() / 100000 % 10 == 3
#define D5() F3()
#elif V() / 100000 % 10 == 4
#define D5() F4()
#elif V() / 100000 % 10 == 5
#define D5() F5()
#elif V() / 100000 % 10 == 6
#define D5() F6()
#elif V() / 100000 % 10 == 7
#define D5() F7()
#elif V() / 100000 % 10 == 8
#define D5() F8()
#else
#define D5() F9()
#endif
#undef D4
#if V() < 10000
#define D4()
#elif V() / 10000 % 10 == 0
#define D4() F0()
#elif V() / 10000 % 10 == 1
#define D4() F1()
#elif V() / 10000 % 10 == 2
#define D4() F2()
#elif V() / 10000 % 10 == 3
#define D4() F3()
#elif V() / 10000 % 10 == 4
#define D4() F4()
#elif V() / 10000 % 10 == 5
#define D4() F5()
#elif V() / 10000 % 10 == 6
#define D4() F6()
#elif V() / 10000 % 10 == 7
#define D4() F7()
#elif V() / 10000 % 10 == 8
#define D4() F8()
#else
#define D4() F9()
#endif
#undef D3
#if V() < 1000
#define D3()
#elif V() / 1000 % 10 == 0
#define D3() F0()
#elif V() / 1000 % 10 == 1
#define D3() F1()
#elif V() / 1000 % 10 == 2
#define D3() F2()
#elif V() / 1000 % 10 == 3
#define D3() F3()
#elif V() / 1000 % 10 == 4
#define D3() F4()
#elif V() / 1000 % 10 == 5
#define D3() F5()
#elif V() / 1000 % 10 == 6
#define D3() F6()
#elif V() / 1000 % 10 == 7
#define D3() F7()
#elif V() / 1000 % 10 == 8
#define D3() F8()
#else
#define D3() F9()
#endif
#undef D2
#if V() < 100
#define D2()
#elif V() / 100 % 10 == 0
#define D2() F0()
#elif V() / 100 % 10 == 1
#define D2() F1()
#elif V() / 100 % 10 == 2
#define D2() F2()
#elif V() / 100 % 10 == 3
#define D2() F3()
#elif V() / 100 % 10 == 4
#define D2() F4()
#elif V() / 100 % 10 == 5
#define D2() F5()
#elif V() / 100 % 10 == 6
#define D2() F6()
#elif V() / 100 % 10 == 7
#define D2() F7()
#elif V() / 100 % 10 == 8
#define D2() F8()
#else
#define D2() F9()
#endif
#undef D1
#if V() < 10
#define D1()
#elif V() / 10 % 10 == 0
#define D1() F0()
#elif V() / 10 % 10 == 1
#define D1() F1()
#elif V() / 10 % 10 == 2
#define D1() F2()
#elif V() / 10 % 10 == 3
#define D1() F3()
#elif V() / 10 % 10 == 4
#define D1() F4()
#elif V() / 10 % 10 == 5
#define D1() F5()
#elif V() / 10 % 10 == 6
#define D1() F6()
#elif V() / 10 % 10 == 7
#define D1() F7()
#elif V() / 10 % 10 == 8
#define D1() F8()
#else
#define D1() F9()
#endif
#undef D0
#if V() % 10 == 0
#define D0() F0()
#elif V() % 10 == 1
#define D0() F1()
#elif V() % 10 == 2
#define D0() F2()
#elif V() % 10 == 3
#define D0() F3()
#elif V() % 10 == 4
#define D0() F4()
#elif V() % 10 == 5
#define D0() F5()
#elif V() % 10 == 6
#define D0() F6()
#elif V() % 10 == 7
#define D0() F7()
#elif V() % 10 == 8
#define D0() F8()
#else
#define D0() F9()
#endif
#undef V

#elif defined(RY)
/* ---- one board row: RY is its number, RN the name of its state macro -------
   MODE 1 draws the row's frame line, MODE 2 prints its new value as state.
   RN() is the row's value: RN expands to ROW3, say, and the () after it calls it.
   Only the four rows under the falling piece need the piece drawn in. */
#if MODE == 1
#if !ENDED && RY >= NPY() && RY < NPY() + 4
#define V() WITHPIECE(RN(), RY, SHOWMASK, NPX() - 3, NPY(), NCUR() + 1)
#else
#define V() RN()
#endif
#include PARTS
#undef PANEL
#if RY == 0
#define PANEL() W()   BC()╭──RS() DM()W(next)RS() BC()──────╮RS()
#elif RY == 1 || RY == 6
#define PANEL() W()   BC()│RS()              BC()│RS()
#elif RY >= 2 && RY <= 5
#define PANEL() W()   BC()│RS()   P0()P1()P2()P3()   BC()│RS()
#undef P0
#undef P1
#undef P2
#undef P3
#if NEXTBIT(RY - 2, 0)
#define P0() NB()
#else
#define P0() W(  )
#endif
#if NEXTBIT(RY - 2, 1)
#define P1() NB()
#else
#define P1() W(  )
#endif
#if NEXTBIT(RY - 2, 2)
#define P2() NB()
#else
#define P2() W(  )
#endif
#if NEXTBIT(RY - 2, 3)
#define P3() NB()
#else
#define P3() W(  )
#endif
#elif RY == 7
#define PANEL() W()   BC()╰──────────────╯RS()
#elif RY == 9
#define PANEL() W()   DM()W(score)RS()
#elif RY == 10
#define PANEL() W()   BOLD()SCORE()RS()
#elif RY == 11
#define PANEL() W()   DM()W(level)RS() BOLD()LEVEL()RS()  DM()W(lines)RS() BOLD()LINES()RS()
#elif RY == 13
#define PANEL() W()   DM()W(controls)RS()
#elif RY == 14
#define PANEL() W()   BOLD()W(← a)RS()  DM()W(move left)RS()
#elif RY == 15
#define PANEL() W()   BOLD()W(→ d)RS()  DM()W(move right)RS()
#elif RY == 16
#define PANEL() W()   BOLD()W(↑ w)RS()  DM()W(rotate)RS()
#elif RY == 17
#define PANEL() W()   BOLD()W(↓ s)RS()  DM()W(soft drop)RS()
#elif RY == 18
#define PANEL() W()   BOLD()W(␣ z)RS()  DM()W(hard drop)RS()
#elif RY == 19
#define PANEL() W()   BOLD()W(  q)RS()  DM()W(quit)RS()
#else
#define PANEL()
#endif
#if ENDED && RY == 9
 BC()║RS()E()[1;7m     GAME  OVER     RS()BC()║RS()PANEL()EOL()
#else
 BC()║RS()D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()BC()║RS()PANEL()EOL()
#endif
#else
#if CHANGED(RY)
#define V() NEWROW(RY)
#include PARTS
@RN D10()D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#else
@RN RN()
#endif
#endif
#undef RY
#undef RN

#else
/* ---- the row table: runs the row code above once for each board row ------- */
#define RY 0
#define RN ROW0
#include PARTS
#define RY 1
#define RN ROW1
#include PARTS
#define RY 2
#define RN ROW2
#include PARTS
#define RY 3
#define RN ROW3
#include PARTS
#define RY 4
#define RN ROW4
#include PARTS
#define RY 5
#define RN ROW5
#include PARTS
#define RY 6
#define RN ROW6
#include PARTS
#define RY 7
#define RN ROW7
#include PARTS
#define RY 8
#define RN ROW8
#include PARTS
#define RY 9
#define RN ROW9
#include PARTS
#define RY 10
#define RN ROW10
#include PARTS
#define RY 11
#define RN ROW11
#include PARTS
#define RY 12
#define RN ROW12
#include PARTS
#define RY 13
#define RN ROW13
#include PARTS
#define RY 14
#define RN ROW14
#include PARTS
#define RY 15
#define RN ROW15
#include PARTS
#define RY 16
#define RN ROW16
#include PARTS
#define RY 17
#define RN ROW17
#include PARTS
#define RY 18
#define RN ROW18
#include PARTS
#define RY 19
#define RN ROW19
#include PARTS

#endif
/*} ---- parts end ----------------------------------------------------------- */
#endif
