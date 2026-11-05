-- sqlitetris.sql - a falling-block puzzle game written in SQL, for the sqlite3 shell.
--
-- The rules and the output format are in ../SPEC.md. This file is a script for
-- the sqlite3 command-line shell: a few dot-commands that set the output format,
-- then plain SQL that creates the tables, views and triggers of the game. After
-- it has been read, the launcher keeps feeding the same shell one line per input
-- number (the seed first, then the events):
--
--   INSERT INTO ev VALUES(N);SELECT*FROM frame;
--
-- The INSERT fires a trigger that plays the event. The SELECT prints the frame
-- that the event produced, if any: the whole frame is one row of one column.
-- When the game is over (or after a quit) the SELECT then hits a deliberate
-- runtime error, and `.bail on` makes the shell exit.

-- ---- output format -----------------------------------------------------------
-- list mode with no header, and both separators empty, so a row of one column
-- is printed as exactly its bytes, without even a newline after it. `.mode`
-- resets the separators, so it comes first.
.mode list
.headers off
.separator "" ""
.nullvalue ""
.bail on

-- ---- static tables -----------------------------------------------------------

-- The seven pieces: colour and the four rotation masks (bit y*4+x of a 4x4 box).
CREATE TABLE piece(p INTEGER PRIMARY KEY, colour, m0, m1, m2, m3);
INSERT INTO piece VALUES
  (0,  51,  240, 17476, 3840, 8738),  -- I
  (1, 226,  102,   102,  102,  102),  -- O
  (2, 135,  114,   610,  624,  562),  -- T
  (3,  46,   54,  1122,  864,  561),  -- S
  (4, 196,   99,   612, 1584,  306),  -- Z
  (5,  33,  113,   550, 1136,  802),  -- J
  (6, 208,  116,  1570,  368,  547);  -- L

-- num(n) holds 0 .. 19: board rows, columns, mask bits.
CREATE TABLE num(n INTEGER PRIMARY KEY);
WITH RECURSIVE c(n) AS (SELECT 0 UNION ALL SELECT n + 1 FROM c WHERE n < 19)
INSERT INTO num SELECT n FROM c;

-- cell(p, r, cx, cy): the occupied cells of piece p in rotation r, unpacked once
-- from the masks, so every later query is a join instead of bit fiddling.
CREATE TABLE cell(p, r, cx, cy);
INSERT INTO cell
  SELECT p, r, bit % 4, bit / 4
  FROM (SELECT p, 0 AS r, m0 AS m FROM piece UNION ALL
        SELECT p, 1, m1 FROM piece UNION ALL
        SELECT p, 2, m2 FROM piece UNION ALL
        SELECT p, 3, m3 FROM piece),
       (SELECT n AS bit FROM num)
  WHERE bit < 16 AND m >> bit & 1;
CREATE INDEX cell_pr ON cell(p, r);

-- try(k, o, dx, dr): the positions a sideways move or a rotation may take, in the
-- order they are tried. Event 1 moves left, 2 moves right, 3 rotates with the
-- wall kicks 0, -1, +1, -2, +2.
CREATE TABLE try(k, o, dx, dr);
INSERT INTO try VALUES (1, 0, -1, 0), (2, 0, 1, 0),
  (3, 0, 0, 1), (3, 1, -1, 1), (3, 2, 1, 1), (3, 3, -2, 1), (3, 4, 2, 1);

-- ---- state -------------------------------------------------------------------

-- g: the one row of game state.
--   started  0 until the seed has been read
--   s        random number generator state (Park-Miller)
--   c, n     current and next piece
--   x, y, rot  position and rotation of the current piece
--   t        ticks since the last gravity step
--   score, lines
--   k        the action being played: the event code, -1 for the start, and a
--            tick that triggers gravity is turned into 4 (soft drop)
--   drop     how many rows the piece can still fall
--   draw     1 if this event prints a frame
--   over     game over; quit: event 9 was read
CREATE TABLE g(started, s, c, n, x, y, rot, t, score, lines, k, drop_, draw, over, quit);
INSERT INTO g VALUES (0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- b: the settled cells of the board, one row per filled cell (v = piece + 1).
-- Empty cells are simply absent. There is deliberately no UNIQUE key: line
-- clears renumber y with one UPDATE, which would collide midway.
CREATE TABLE b(x, y, v);
CREATE INDEX b_xy ON b(x, y);

-- full(y): scratch table for the rows being cleared.
CREATE TABLE full(y);

-- ev: the input. Every inserted number is played by the trigger below.
CREATE TABLE ev(e);
-- lk: inserting a row here locks the current piece (trigger "lock").
CREATE TABLE lk(z);

-- ---- the rules ---------------------------------------------------------------

-- Locking: stamp the piece, clear full rows, score, and spawn the next piece.
CREATE TRIGGER lock AFTER INSERT ON lk BEGIN
  -- 1. write piece + 1 into the piece's cells
  INSERT INTO b
    SELECT g.x + cx, g.y + cy, g.c + 1 FROM g JOIN cell ON cell.p = g.c AND cell.r = g.rot;
  -- 2. find the full rows, drop them, and move every row above down by the
  --    number of cleared rows below it
  INSERT INTO full SELECT y FROM b GROUP BY y HAVING count(*) = 10;
  -- 3. and 4. score with the level before this clear, then count the lines
  --    (both right-hand sides see the old values of the row)
  UPDATE g SET
    score = score + (SELECT CASE count(*) WHEN 1 THEN 40 WHEN 2 THEN 100
                     WHEN 3 THEN 300 WHEN 4 THEN 1200 ELSE 0 END FROM full)
                    * (lines / 10 + 1),
    lines = lines + (SELECT count(*) FROM full);
  DELETE FROM b WHERE y IN (SELECT y FROM full);
  UPDATE b SET y = y + (SELECT count(*) FROM full WHERE full.y > b.y);
  DELETE FROM full;
  -- 5. the next piece becomes current, draw a new next piece, spawn
  UPDATE g SET c = n, s = s * 16807 % 2147483647, n = s * 16807 % 2147483647 % 7,
               x = 3, y = 0, rot = 0, t = 0;
  UPDATE g SET over = EXISTS (
    SELECT 1 FROM cell JOIN b ON b.x = g.x + cell.cx AND b.y = g.y + cell.cy
    WHERE cell.p = g.c AND cell.r = 0);
  DELETE FROM lk;
END;

-- One event.
CREATE TRIGGER play AFTER INSERT ON ev BEGIN
  -- Which action? The very first number is the seed, not an event.
  UPDATE g SET k = CASE WHEN started THEN NEW.e ELSE -1 END;

  -- Start: seed the generator and draw the current and the next piece.
  -- (e * 16807 * 16807 stays below 2^63, so two steps fit in one expression.)
  UPDATE g SET started = 1,
               s = NEW.e * 16807 * 16807 % 2147483647,
               c = NEW.e * 16807 % 2147483647 % 7,
               n = NEW.e * 16807 * 16807 % 2147483647 % 7
    WHERE k = -1;

  -- Tick: count it; when the gravity interval max(1, 11 - level) is reached,
  -- reset the counter and play a soft drop.
  UPDATE g SET t = t + 1 WHERE k = 0;
  UPDATE g SET t = 0, k = 4 WHERE k = 0 AND t >= max(1, 10 - lines / 10);

  -- Quit.
  UPDATE g SET quit = 1 WHERE k = 9;

  -- Move left/right or rotate: take the first position in "try" that fits.
  -- It fits when none of its cells is off the board or on a settled cell.
  UPDATE g SET x = x + m.dx, rot = m.rot
    FROM (SELECT try.dx, (g.rot + try.dr) % 4 AS rot
          FROM g JOIN try ON try.k = g.k
          WHERE NOT EXISTS (
            SELECT 1 FROM cell
            WHERE cell.p = g.c AND cell.r = (g.rot + try.dr) % 4
              AND (g.x + try.dx + cx NOT BETWEEN 0 AND 9 OR g.y + cy > 19
                   OR EXISTS (SELECT 1 FROM b
                              WHERE b.x = g.x + try.dx + cx AND b.y = g.y + cy)))
          ORDER BY try.o LIMIT 1) AS m;

  -- Soft drop (4) and hard drop (5). Each cell of the piece can fall until
  -- just above the first settled cell (or the floor) below it in its column;
  -- the piece can fall the smallest of those distances.
  UPDATE g SET drop_ = (
      SELECT min(coalesce((SELECT min(b.y) FROM b WHERE b.x = g.x + cx AND b.y > g.y + cy), 20)
                 - g.y - cy) - 1
      FROM cell WHERE cell.p = g.c AND cell.r = g.rot)
    WHERE k IN (4, 5);
  -- A soft drop falls one row if it can; a hard drop falls all the way.
  UPDATE g SET y = y + CASE k WHEN 5 THEN drop_ ELSE min(drop_, 1) END WHERE k IN (4, 5);
  -- A hard drop always locks; a soft drop locks when it couldn't move.
  INSERT INTO lk SELECT 1 FROM g WHERE k = 5 OR k = 4 AND drop_ = 0;

  -- Every event prints a frame except quiet ticks, quit and unknown codes.
  UPDATE g SET draw = k IN (-1, 1, 2, 3, 4, 5);
END;

-- ---- drawing -----------------------------------------------------------------

-- k: the escape sequences the frame is made of.
CREATE VIEW k AS SELECT
  char(27) AS E,                      -- ESC
  char(27) || '[m' AS R,              -- reset
  char(27) || '[38;5;60m' AS B,       -- border colour
  char(27) || '[38;5;244m' AS D,      -- dim text
  char(27) || '[1m' AS W;             -- bold

-- grid(y, x, v): every square of the board with the falling piece on top
-- (0 = empty, else piece + 1). The piece is not drawn on the game-over frame.
CREATE VIEW grid AS
  SELECT yy.n AS y, xx.n AS x, coalesce(
      (SELECT g.c + 1 FROM g JOIN cell ON cell.p = g.c AND cell.r = g.rot
       WHERE NOT g.over AND g.x + cx = xx.n AND g.y + cy = yy.n),
      (SELECT v FROM b WHERE b.x = xx.n AND b.y = yy.n),
      0) AS v
  FROM num AS yy, num AS xx WHERE xx.n < 10;

-- block(v, s): how a square looks: empty, or two coloured full blocks.
CREATE VIEW block AS
  SELECT 0 AS v, E || '[38;5;237m ·' || R AS s FROM k
  UNION ALL
  SELECT p + 1, E || '[38;5;' || colour || 'm██' || R FROM k, piece;

-- row(y, s): the ten squares of one board row, or the game-over banner on row 9.
CREATE VIEW row AS
  SELECT grid.y, CASE WHEN g.over AND grid.y = 9
                      THEN E || '[1;7m     GAME  OVER     ' || R
                      ELSE group_concat(block.s, '' ORDER BY grid.x) END AS s
  FROM grid JOIN block ON block.v = grid.v, g, k
  GROUP BY grid.y;

-- keys(y, key, action): the controls listed in the side panel.
CREATE TABLE keys(y, key, action);
INSERT INTO keys VALUES (14, '← a', 'move left'), (15, '→ d', 'move right'),
  (16, '↑ w', 'rotate'), (17, '↓ s', 'soft drop'), (18, '␣ z', 'hard drop'),
  (19, '  q', 'quit');

-- panel(y, s): the side panel text next to board row y.
CREATE VIEW panel AS
  SELECT num.n AS y, '   ' || CASE
    WHEN num.n = 0 THEN B || '╭──' || R || ' ' || D || 'next' || R || ' ' || B || '──────╮' || R
    WHEN num.n IN (1, 6) THEN B || '│' || R || printf('%14s', '') || B || '│' || R
    WHEN num.n BETWEEN 2 AND 5 THEN B || '│' || R || '   ' ||
      (SELECT group_concat(CASE WHEN EXISTS (
                SELECT 1 FROM cell WHERE cell.p = g.n AND cell.r = 0
                AND cell.cx = xx.n AND cell.cy = num.n - 2)
              THEN (SELECT s FROM block WHERE block.v = g.n + 1) ELSE '  ' END,
              '' ORDER BY xx.n)
       FROM num AS xx WHERE xx.n < 4)
      || '   ' || B || '│' || R
    WHEN num.n = 7 THEN B || '╰' || printf('%.*c', 14, '─') || '╯' || R
    WHEN num.n = 9 THEN D || 'score' || R
    WHEN num.n = 10 THEN W || g.score || R
    WHEN num.n = 11 THEN D || 'level' || R || ' ' || W || (g.lines / 10 + 1) || R || '  '
                      || D || 'lines' || R || ' ' || W || g.lines || R
    WHEN num.n = 13 THEN D || 'controls' || R
    WHEN num.n >= 14 THEN (SELECT W || key || R || '  ' || D || action || R
                           FROM keys WHERE keys.y = num.n)
  END AS s
  FROM num, g, k;

-- screen(l, s): the 23 lines of the frame.
CREATE VIEW screen AS
  SELECT 0 AS l, '  ' || E || '[1;38;5;75mS Q L I T E T R I S' || R AS s FROM k
  UNION ALL
  SELECT 1, ' ' || B || '╔' || printf('%.*c', 20, '═') || '╗' || R FROM k
  UNION ALL
  SELECT row.y + 2, ' ' || B || '║' || R || row.s || B || '║' || R || coalesce(panel.s, '')
  FROM row JOIN panel ON panel.y = row.y, k
  UNION ALL
  SELECT 22, ' ' || B || '╚' || printf('%.*c', 20, '═') || '╝' || R FROM k;

-- frame: what the shell prints after an event. The frame, if this event draws
-- one, as a single row; then, if the game has ended, a row whose value is
-- abs(-2^63), an "integer overflow" error that makes the shell (.bail on) exit.
CREATE VIEW frame AS
  SELECT E || '[H' || group_concat(screen.s || E || '[K' || char(10), '' ORDER BY screen.l)
         || E || '[J'
  FROM screen, k, g WHERE g.draw
  UNION ALL
  SELECT abs(-9223372036854775807 - over - quit) FROM g WHERE over OR quit;
