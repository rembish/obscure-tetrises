{-# LANGUAGE DataKinds, TypeFamilies, UndecidableInstances, TypeOperators, NoStarIsType #-}
-- ghcitris.hs - a falling-block puzzle game written in Haskell type families.
--
--   ./ghcitris.sh       (runs ghci with this file and plays it)
--
-- The game is computed by GHC's type checker. The state is a type, of kind
-- Game; an event is a type-level number; Step takes a Game and an event to
-- the next Game, and Frame turns a Game into a Symbol: the frame, as a
-- type-level string. Nothing here has a value at run time: the file defines
-- no functions, only types. ghci does the rest:
--
--   :kind! Start 42            the first state, reduced to its normal form
--   :kind! Step S 3            the next one, after event 3 (rotate)
--   type S = 'Game ...         the launcher names the new state S again
--   putStr (symbolVal (Proxy @(Frame S)))     prints the frame
--
-- symbolVal is the only bridge from types to output: GHC turns a known
-- Symbol into a String. The events are those of ../SPEC.md: 0 tick, 1 left,
-- 2 right, 3 rotate, 4 soft drop, 5 hard drop (9, quit, never gets here).
--
-- Type families are functions on types, defined by equations that GHC tries
-- in order (closed families). Numbers are Nat literals with + - * ^ Div Mod
-- and comparisons, from GHC.TypeLits, exact at any size: the Park-Miller
-- generator is one line, and the whole board is one number. What the type
-- checker doesn't have is laziness you can count on: both branches of an If
-- may be worked out. So every recursion here goes through a helper family
-- that matches on a Bool or a Maybe, and recurses only in the equation that
-- matched.
module Ghcitris where

import GHC.TypeLits
import Data.Type.Bool (type (&&))
import Data.Type.Equality (type (==))

-- ---- the state ------------------------------------------------------------------

-- What the launcher does after this state: print nothing (a tick that moved
-- nothing), print the frame, or print the game-over frame and stop.
data Mode = Quiet | Shown | Ended

-- seed, piece, next piece, x + 4, y, rotation, ticks, score, lines, board,
-- mode. The box's x goes down to -2, but a Nat can't be negative, so the
-- state has x + 4: then even a kick two to the left of x = -2 is a Nat.
--
-- The board is one number with 200 octal digits, one per cell: digit
-- y * 10 + x is the cell in column x of row y (row 0 at the top), 0 when
-- empty and piece + 1 when locked. So a cell is Div and Mod by a power of
-- 8, and a state prints as eleven numbers. (A list of 20 lists of 10 cells
-- works too, but every use of the state then costs the type checker a few
-- milliseconds just to take in a type of some 450 parts.)
data Game = Game Nat Nat Nat Nat Nat Nat Nat Nat Nat Nat Mode

-- ---- the board ------------------------------------------------------------------

type Digit (b :: Nat) (k :: Nat) = Mod (Div b (8 ^ k)) 8

-- Row y as a number of ten octal digits, column 0 in the lowest one.
type Row (b :: Nat) (y :: Nat) = Mod (Div b (8 ^ (10 * y))) (8 ^ 10)

-- Is any of the n lowest digits 0?
type family HasHole (row :: Nat) (n :: Nat) :: Bool where
  HasHole row 0 = 'False
  HasHole row n = HasHoleIf (Mod row 8 == 0) (Div row 8) (n - 1)

type family HasHoleIf (hole :: Bool) (row :: Nat) (n :: Nat) :: Bool where
  HasHoleIf 'True row n = 'True
  HasHoleIf 'False row n = HasHole row n

-- ---- pieces ---------------------------------------------------------------------

-- The rotations of I O T S Z J L as 16-bit masks, bit y * 4 + x of the 4x4 box.
type family Mask (p :: Nat) (r :: Nat) :: Nat where
  Mask 0 0 = 240
  Mask 0 1 = 17476
  Mask 0 2 = 3840
  Mask 0 3 = 8738
  Mask 1 r = 102
  Mask 2 0 = 114
  Mask 2 1 = 610
  Mask 2 2 = 624
  Mask 2 3 = 562
  Mask 3 0 = 54
  Mask 3 1 = 1122
  Mask 3 2 = 864
  Mask 3 3 = 561
  Mask 4 0 = 99
  Mask 4 1 = 612
  Mask 4 2 = 1584
  Mask 4 3 = 306
  Mask 5 0 = 113
  Mask 5 1 = 550
  Mask 5 2 = 1136
  Mask 5 3 = 802
  Mask 6 0 = 116
  Mask 6 1 = 1570
  Mask 6 2 = 368
  Mask 6 3 = 547

-- The four cells of a mask, as (x, y) pairs in the box.
type Cells (p :: Nat) (r :: Nat) = CellsFrom (Mask p r) 0

type family CellsFrom (m :: Nat) (i :: Nat) :: [(Nat, Nat)] where
  CellsFrom 0 i = '[]
  CellsFrom m i = CellsBit (Mod m 2) m i

type family CellsBit (bit :: Nat) (m :: Nat) (i :: Nat) :: [(Nat, Nat)] where
  CellsBit 1 m i = '(Mod i 4, Div i 4) ': CellsFrom (Div m 2) (i + 1)
  CellsBit 0 m i = CellsFrom (Div m 2) (i + 1)

-- ---- fitting --------------------------------------------------------------------

-- Do the cells fit with the box at (x + 4, y)? A cell is free if it is on the
-- board and empty. The bounds go first, so that a cell off the board is never
-- looked up (x + dx - 4 would not even be a Nat).
type family Fits (b :: Nat) (cs :: [(Nat, Nat)]) (x :: Nat) (y :: Nat) :: Bool where
  Fits b '[] x y = 'True
  Fits b ('(dx, dy) ': cs) x y = FitsNext (Free b (x + dx) (y + dy)) b cs x y

type family FitsNext (free :: Bool) (b :: Nat) (cs :: [(Nat, Nat)]) (x :: Nat) (y :: Nat) :: Bool where
  FitsNext 'False b cs x y = 'False
  FitsNext 'True b cs x y = Fits b cs x y

type family Free (b :: Nat) (cx :: Nat) (cy :: Nat) :: Bool where
  Free b cx cy = FreeIf (4 <=? cx && cx <=? 13 && cy <=? 19) b cx cy

type family FreeIf (inside :: Bool) (b :: Nat) (cx :: Nat) (cy :: Nat) :: Bool where
  FreeIf 'False b cx cy = 'False
  FreeIf 'True b cx cy = Digit b (cy * 10 + cx - 4) == 0

-- The game with the piece at x, y, r, if it fits there.
type family Try (g :: Game) (x :: Nat) (y :: Nat) (r :: Nat) :: Maybe Game where
  Try ('Game s p n x0 y0 r0 t sc ln b m) x y r =
    TryIf (Fits b (Cells p r) x y) ('Game s p n x y r t sc ln b 'Shown)

type family TryIf (fits :: Bool) (g :: Game) :: Maybe Game where
  TryIf 'True g = 'Just g
  TryIf 'False g = 'Nothing

type family OrElse (m :: Maybe Game) (g :: Game) :: Game where
  OrElse ('Just g) d = g
  OrElse 'Nothing d = d

type family Show' (g :: Game) :: Game where
  Show' ('Game s p n x y r t sc ln b m) = 'Game s p n x y r t sc ln b 'Shown

-- ---- events ---------------------------------------------------------------------

type family Step (g :: Game) (e :: Nat) :: Game where
  Step ('Game s p n x y r t sc ln b m) 0 = Tick ('Game s p n x y r (t + 1) sc ln b 'Quiet)
  Step ('Game s p n x y r t sc ln b m) 1 = OrElse (Try ('Game s p n x y r t sc ln b m) (x - 1) y r) (Show' ('Game s p n x y r t sc ln b m))
  Step ('Game s p n x y r t sc ln b m) 2 = OrElse (Try ('Game s p n x y r t sc ln b m) (x + 1) y r) (Show' ('Game s p n x y r t sc ln b m))
  Step ('Game s p n x y r t sc ln b m) 3 = Kicks ('Game s p n x y r t sc ln b m) (Mod (r + 1) 4) '[2, 1, 3, 0, 4]
  Step g 4 = Down g
  Step g 5 = Hard g
  Step ('Game s p n x y r t sc ln b m) e = 'Game s p n x y r t sc ln b 'Quiet

-- Gravity: the piece falls every max(1, 11 - level) ticks, level = lines / 10 + 1.
type Level (ln :: Nat) = Div ln 10 + 1

type family Tick (g :: Game) :: Game where
  Tick ('Game s p n x y r t sc ln b m) = TickIf (Gravity (Level ln) <=? t) ('Game s p n x y r t sc ln b m)

type family Gravity (lv :: Nat) :: Nat where
  Gravity lv = GravityIf (lv <=? 10) lv

type family GravityIf (slow :: Bool) (lv :: Nat) :: Nat where
  GravityIf 'True lv = 11 - lv
  GravityIf 'False lv = 1

type family TickIf (falls :: Bool) (g :: Game) :: Game where
  TickIf 'False g = g
  TickIf 'True ('Game s p n x y r t sc ln b m) = Down ('Game s p n x y r 0 sc ln b m)

-- Rotate: try the new rotation at x + k - 2 for k in 2 1 3 0 4, which are
-- the kicks 0, -1, +1, -2, +2.
type family Kicks (g :: Game) (r :: Nat) (ks :: [Nat]) :: Game where
  Kicks g r '[] = Show' g
  Kicks ('Game s p n x y r0 t sc ln b m) r (k ': ks) =
    KicksNext (Try ('Game s p n x y r0 t sc ln b m) (x + k - 2) y r) ('Game s p n x y r0 t sc ln b m) r ks

type family KicksNext (tried :: Maybe Game) (g :: Game) (r :: Nat) (ks :: [Nat]) :: Game where
  KicksNext ('Just g') g r ks = g'
  KicksNext 'Nothing g r ks = Kicks g r ks

-- Step down: one row lower if it fits there, or lock.
type family Down (g :: Game) :: Game where
  Down ('Game s p n x y r t sc ln b m) = DownIf (Try ('Game s p n x y r t sc ln b m) x (y + 1) r) ('Game s p n x y r t sc ln b m)

type family DownIf (tried :: Maybe Game) (g :: Game) :: Game where
  DownIf ('Just g') g = g'
  DownIf 'Nothing g = Lock g

type family Hard (g :: Game) :: Game where
  Hard ('Game s p n x y r t sc ln b m) = HardIf (Try ('Game s p n x y r t sc ln b m) x (y + 1) r) ('Game s p n x y r t sc ln b m)

type family HardIf (tried :: Maybe Game) (g :: Game) :: Game where
  HardIf ('Just g') g = Hard g'
  HardIf 'Nothing g = Lock g

-- ---- locking --------------------------------------------------------------------

-- Write the value v into the cells of the piece: they are empty, so that
-- is adding v times the cell's power of 8.
type family Stamp (b :: Nat) (cs :: [(Nat, Nat)]) (x :: Nat) (y :: Nat) (v :: Nat) :: Nat where
  Stamp b '[] x y v = b
  Stamp b ('(dx, dy) ': cs) x y v = Stamp (b + v * 8 ^ ((y + dy) * 10 + x + dx - 4)) cs x y v

-- Remove the full rows. The rows go from the bottom up; each one that isn't
-- full goes into row "to" of the new board, and "to" moves up. What is left
-- at the top is 0, empty rows. "cleared" starts at 20 and loses one for each
-- row that stays.
type family Clear (b :: Nat) (from :: Nat) (to :: Nat) (kept :: Nat) (cleared :: Nat) :: (Nat, Nat) where
  Clear b from to kept cleared = ClearRow (HasHole (Row b from) 10) b from to kept cleared

type family ClearRow (stays :: Bool) (b :: Nat) (from :: Nat) (to :: Nat) (kept :: Nat) (cleared :: Nat) :: (Nat, Nat) where
  ClearRow 'True b 0 to kept cleared = '(kept + Row b 0 * 8 ^ (10 * to), cleared - 1)
  ClearRow 'False b 0 to kept cleared = '(kept, cleared)
  ClearRow 'True b from to kept cleared = Clear b (from - 1) (to - 1) (kept + Row b from * 8 ^ (10 * to)) (cleared - 1)
  ClearRow 'False b from to kept cleared = Clear b (from - 1) to kept cleared

type family Lock (g :: Game) :: Game where
  Lock ('Game s p n x y r t sc ln b m) = Cleared s n sc ln (Clear (Stamp b (Cells p r) x y (p + 1)) 19 19 0 20)

type family Cleared (s :: Nat) (n :: Nat) (sc :: Nat) (ln :: Nat) (bc :: (Nat, Nat)) :: Game where
  Cleared s n sc ln '(b, c) = Spawn s n (sc + Points c * Level ln) (ln + c) b

type family Points (rows :: Nat) :: Nat where
  Points 0 = 0
  Points 1 = 40
  Points 2 = 100
  Points 3 = 300
  Points 4 = 1200

-- ---- the next piece -------------------------------------------------------------

-- Park-Miller: s * 16807 mod (2^31 - 1), and the piece is s mod 7.
type Rand (s :: Nat) = Mod (s * 16807) 2147483647

-- The next piece becomes the falling one, at x = 3, y = 0, r = 0, and a new
-- next piece is drawn. If the piece doesn't fit, the game is over.
type family Spawn (s :: Nat) (p :: Nat) (sc :: Nat) (ln :: Nat) (b :: Nat) :: Game where
  Spawn s p sc ln b = Spawned (Fits b (Cells p 0) 7 0) ('Game (Rand s) p (Mod (Rand s) 7) 7 0 0 0 sc ln b 'Shown)

type family Spawned (fits :: Bool) (g :: Game) :: Game where
  Spawned 'True g = g
  Spawned 'False ('Game s p n x y r t sc ln b m) = 'Game s p n x y r t sc ln b 'Ended

-- The first state: draw the falling piece, then the next one (Spawn draws it).
type Start (seed :: Nat) = Spawn (Rand seed) (Mod (Rand seed) 7) 0 0 0

-- ---- the frame ------------------------------------------------------------------

type Off = "\ESC[m"
type Eol = "\ESC[K\n"
type B (s :: Symbol) = Cat '["\ESC[38;5;60m", s, Off]
type Dim (s :: Symbol) = Cat '["\ESC[38;5;244m", s, Off]
type Bold (s :: Symbol) = Cat '["\ESC[1m", s, Off]

-- Concatenate Symbols.
type family Cat (ss :: [Symbol]) :: Symbol where
  Cat '[] = ""
  Cat (s ': ss) = AppendSymbol s (Cat ss)

type family ShowNat (n :: Nat) :: Symbol where
  ShowNat n = ShowNatIf (n <=? 9) n

type family ShowNatIf (digit :: Bool) (n :: Nat) :: Symbol where
  ShowNatIf 'True n = ConsSymbol (NatToChar (48 + n)) ""
  ShowNatIf 'False n = AppendSymbol (ShowNat (Div n 10)) (ShowNatIf 'True (Mod n 10))

-- A board cell: 0 is empty, else piece + 1.
type family Cell (v :: Nat) :: Symbol where
  Cell 0 = "\ESC[38;5;237m ·\ESC[m"
  Cell 1 = "\ESC[38;5;51m██\ESC[m"
  Cell 2 = "\ESC[38;5;226m██\ESC[m"
  Cell 3 = "\ESC[38;5;135m██\ESC[m"
  Cell 4 = "\ESC[38;5;46m██\ESC[m"
  Cell 5 = "\ESC[38;5;196m██\ESC[m"
  Cell 6 = "\ESC[38;5;33m██\ESC[m"
  Cell 7 = "\ESC[38;5;208m██\ESC[m"

-- The n lowest digits of a row, lowest first.
type family RowCells (row :: Nat) (n :: Nat) :: Symbol where
  RowCells row 0 = ""
  RowCells row n = AppendSymbol (Cell (Mod row 8)) (RowCells (Div row 8) (n - 1))

-- One row of the next piece's box, from the n lowest bits of m: an empty
-- cell is two spaces, a full one is drawn as v.
type family Preview (m :: Nat) (v :: Nat) (n :: Nat) :: Symbol where
  Preview m v 0 = ""
  Preview m v n = AppendSymbol (PreviewCell (Mod m 2) v) (Preview (Div m 2) v (n - 1))

type family PreviewCell (bit :: Nat) (v :: Nat) :: Symbol where
  PreviewCell 1 v = Cell v
  PreviewCell 0 v = "  "

type BoxRow (s :: Symbol) = Cat '["   ", B "│", s, B "│"]
type PreviewRow (n :: Nat) (row :: Nat) = BoxRow (Cat '["   ", Preview (Div (Mask n 0) (16 ^ row)) (n + 1) 4, "   "])
type Key (k :: Symbol) (what :: Symbol) = Cat '["   ", Bold k, "  ", Dim what]

-- The side panel, by board row.
type family Panel (i :: Nat) (n :: Nat) (sc :: Nat) (ln :: Nat) :: Symbol where
  Panel 0 n sc ln = Cat '["   ", B "╭──", " ", Dim "next", " ", B "──────╮"]
  Panel 1 n sc ln = BoxRow "              "
  Panel 2 n sc ln = PreviewRow n 0
  Panel 3 n sc ln = PreviewRow n 1
  Panel 4 n sc ln = PreviewRow n 2
  Panel 5 n sc ln = PreviewRow n 3
  Panel 6 n sc ln = BoxRow "              "
  Panel 7 n sc ln = Cat '["   ", B "╰──────────────╯"]
  Panel 9 n sc ln = Cat '["   ", Dim "score"]
  Panel 10 n sc ln = Cat '["   ", Bold (ShowNat sc)]
  Panel 11 n sc ln = Cat '["   ", Dim "level", " ", Bold (ShowNat (Level ln)), "  ", Dim "lines", " ", Bold (ShowNat ln)]
  Panel 13 n sc ln = Cat '["   ", Dim "controls"]
  Panel 14 n sc ln = Key "← a" "move left"
  Panel 15 n sc ln = Key "→ d" "move right"
  Panel 16 n sc ln = Key "↑ w" "rotate"
  Panel 17 n sc ln = Key "↓ s" "soft drop"
  Panel 18 n sc ln = Key "␣ z" "hard drop"
  Panel 19 n sc ln = Key "  q" "quit"
  Panel i n sc ln = ""

-- The frame: the title, the top border, and then the board rows with their
-- panels and the bottom border, as a list of lines joined at the end.
type family Frame (g :: Game) :: Symbol where
  Frame ('Game s p n x y r t sc ln b 'Quiet) = ""
  Frame ('Game s p n x y r t sc ln b 'Shown) = Picture (Stamp b (Cells p r) x y (p + 1)) 'False n sc ln
  Frame ('Game s p n x y r t sc ln b 'Ended) = Picture b 'True n sc ln

type Picture (b :: Nat) (over :: Bool) (n :: Nat) (sc :: Nat) (ln :: Nat) = Cat
  ( "\ESC[H  \ESC[1;38;5;75mG H C I T R I S\ESC[m\ESC[K\n"
  ': " \ESC[38;5;60m╔════════════════════╗\ESC[m\ESC[K\n"
  ': Rows b RowNumbers over n sc ln )

-- On game over row 9 is the banner.
type RowNumbers = '[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]

type family Rows (b :: Nat) (is :: [Nat]) (over :: Bool) (n :: Nat) (sc :: Nat) (ln :: Nat) :: [Symbol] where
  Rows b '[] over n sc ln = '[" \ESC[38;5;60m╚════════════════════╝\ESC[m\ESC[K\n"]
  Rows b (i ': is) over n sc ln =
    Cat '[" \ESC[38;5;60m║\ESC[m", Board b i over, "\ESC[38;5;60m║\ESC[m", Panel i n sc ln, Eol]
      ': Rows b is over n sc ln

type family Board (b :: Nat) (i :: Nat) (over :: Bool) :: Symbol where
  Board b 9 'True = "\ESC[1;7m     GAME  OVER     \ESC[m"
  Board b i over = RowCells (Row b i) 10
