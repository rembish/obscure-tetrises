# gdbtris.gdb - a falling-block puzzle game written in gdb's command language.
#
#   gdb -q -nx -x gdbtris.gdb      (gdbtris.sh does this, and feeds it the events)
#
# gdb is run with no program to debug: what's left is its command language,
# the one for scripting breakpoints. It has convenience variables ($name),
# C expressions on them (64-bit integers, arrays), while and if, printf, and
# user-defined commands (define ... end). This file defines the game; then
# gdb reads commands on stdin, and the launcher turns each input line into
# one: "seed 42" first, then "event 3" for every event (../SPEC.md: 0 tick,
# 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop; 9 quit stops the
# launcher). At game over the engine quits gdb itself.
#
# A user-defined command takes its arguments as words, pasted into its body
# as text ($arg0 ...), and returns nothing. So commands here work on global
# convenience variables: the caller sets $tx, $ty and $tr, runs "fits", and
# reads $ok.

# No prompt, no "are you sure", no paging: gdb prints only what printf says.
set prompt
set confirm off
set pagination off
set height 0
set width 0

# ---- tables -----------------------------------------------------------------------
# Rotation masks, four per piece (I O T S Z J L): bit y*4+x of the 4x4 box.
set $masks = {240, 17476, 3840, 8738, 102, 102, 102, 102, 114, 610, 624, 562, 54, 1122, 864, 561, 99, 612, 1584, 306, 113, 550, 1136, 802, 116, 1570, 368, 547}
set $colours = {51, 226, 135, 46, 196, 33, 208}
set $points = {0, 40, 100, 300, 1200}

# The board: 200 cells, index y*10 + x, 0 empty or piece + 1. gdb has no way to
# make an array of a given size, so it is written out, one row per line.
set $empty = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
set $board = $empty

# ---- the rules ------------------------------------------------------------------------

# Park-Miller: the seed is a long, so s * 16807 can't overflow.
define rand
  set $seed = $seed * 16807 % 2147483647
  set $drawn = $seed % 7
end

# Does the falling piece fit at ($tx, $ty) in rotation $tr? Sets $ok.
define fits
  set $ok = 1
  set $mask = $masks[$cur * 4 + $tr]
  set $i = 0
  while $i < 16 && $ok
    if ($mask >> $i) & 1
      set $cx = $tx + $i % 4
      set $cy = $ty + $i / 4
      if $cx < 0 || $cx > 9 || $cy > 19 || $board[$cy * 10 + $cx]
        set $ok = 0
      end
    end
    set $i = $i + 1
  end
end

# The next piece falls from x = 3, y = 0; if it doesn't fit, the game is over.
define spawn
  set $cur = $next
  rand
  set $next = $drawn
  set $x = 3
  set $y = 0
  set $r = 0
  set $t = 0
  set $tx = $x
  set $ty = $y
  set $tr = $r
  fits
  if !$ok
    set $over = 1
  end
end

# Write the piece into the board, remove full rows, score, and spawn the next.
define lock
  set $mask = $masks[$cur * 4 + $r]
  set $i = 0
  while $i < 16
    if ($mask >> $i) & 1
      set $board[($y + $i / 4) * 10 + $x + $i % 4] = $cur + 1
    end
    set $i = $i + 1
  end
  # Rows from the bottom up; each one that isn't full is copied down to row
  # $to, which then moves up. The rows left at the top are emptied.
  set $to = 19
  set $from = 19
  while $from >= 0
    set $full = 1
    set $i = 0
    while $i < 10
      if !$board[$from * 10 + $i]
        set $full = 0
      end
      set $i = $i + 1
    end
    if !$full
      set $i = 0
      while $i < 10
        set $board[$to * 10 + $i] = $board[$from * 10 + $i]
        set $i = $i + 1
      end
      set $to = $to - 1
    end
    set $from = $from - 1
  end
  set $cleared = $to + 1
  set $i = 0
  while $i < $cleared * 10
    set $board[$i] = 0
    set $i = $i + 1
  end
  set $score = $score + $points[$cleared] * ($lines / 10 + 1)
  set $lines = $lines + $cleared
  spawn
end

# One row down if it fits; otherwise lock.
define stepdown
  set $tx = $x
  set $ty = $y + 1
  set $tr = $r
  fits
  if $ok
    set $y = $y + 1
  else
    lock
  end
end

# ---- the frame ------------------------------------------------------------------------
# ESC can't be written in a printf format (gdb knows no \033 or \e there), so
# every escape sequence is %c with 27.

define cell
  if $arg0
    printf "%c[38;5;%dm██%c[m", 27, $colours[$arg0 - 1], 27
  else
    printf "%c[38;5;237m ·%c[m", 27, 27
  end
end

# The side panel for board row $row.
define panel
  if $row == 0
    printf "   %c[38;5;60m╭──%c[m %c[38;5;244mnext%c[m %c[38;5;60m──────╮%c[m", 27, 27, 27, 27, 27, 27
  end
  if $row == 1 || $row == 6
    printf "   %c[38;5;60m│%c[m              %c[38;5;60m│%c[m", 27, 27, 27, 27
  end
  if $row >= 2 && $row <= 5
    printf "   %c[38;5;60m│%c[m   ", 27, 27
    set $j = 0
    while $j < 4
      if ($masks[$next * 4] >> (($row - 2) * 4 + $j)) & 1
        cell $next+1
      else
        printf "  "
      end
      set $j = $j + 1
    end
    printf "   %c[38;5;60m│%c[m", 27, 27
  end
  if $row == 7
    printf "   %c[38;5;60m╰──────────────╯%c[m", 27, 27
  end
  if $row == 9
    printf "   %c[38;5;244mscore%c[m", 27, 27
  end
  if $row == 10
    printf "   %c[1m%d%c[m", 27, $score, 27
  end
  if $row == 11
    printf "   %c[38;5;244mlevel%c[m %c[1m%d%c[m  %c[38;5;244mlines%c[m %c[1m%d%c[m", 27, 27, 27, $lines / 10 + 1, 27, 27, 27, 27, $lines, 27
  end
  if $row == 13
    printf "   %c[38;5;244mcontrols%c[m", 27, 27
  end
  if $row == 14
    printf "   %c[1m← a%c[m  %c[38;5;244mmove left%c[m", 27, 27, 27, 27
  end
  if $row == 15
    printf "   %c[1m→ d%c[m  %c[38;5;244mmove right%c[m", 27, 27, 27, 27
  end
  if $row == 16
    printf "   %c[1m↑ w%c[m  %c[38;5;244mrotate%c[m", 27, 27, 27, 27
  end
  if $row == 17
    printf "   %c[1m↓ s%c[m  %c[38;5;244msoft drop%c[m", 27, 27, 27, 27
  end
  if $row == 18
    printf "   %c[1m␣ z%c[m  %c[38;5;244mhard drop%c[m", 27, 27, 27, 27
  end
  if $row == 19
    printf "   %c[1m  q%c[m  %c[38;5;244mquit%c[m", 27, 27, 27, 27
  end
end

# The whole frame: the falling piece is drawn into a copy of the board, unless
# the game is over, when board row 9 is the banner instead.
define frame
  set $grid = $board
  if !$over
    set $mask = $masks[$cur * 4 + $r]
    set $i = 0
    while $i < 16
      if ($mask >> $i) & 1
        set $grid[($y + $i / 4) * 10 + $x + $i % 4] = $cur + 1
      end
      set $i = $i + 1
    end
  end
  printf "%c[H  %c[1;38;5;75mG D B T R I S%c[m%c[K\n", 27, 27, 27, 27
  printf " %c[38;5;60m╔════════════════════╗%c[m%c[K\n", 27, 27, 27
  set $row = 0
  while $row < 20
    printf " %c[38;5;60m║%c[m", 27, 27
    if $over && $row == 9
      printf "%c[1;7m     GAME  OVER     %c[m", 27, 27
    else
      set $col = 0
      while $col < 10
        cell $grid[$row*10+$col]
        set $col = $col + 1
      end
    end
    printf "%c[38;5;60m║%c[m", 27, 27
    panel
    printf "%c[K\n", 27
    set $row = $row + 1
  end
  printf " %c[38;5;60m╚════════════════════╝%c[m%c[K\n", 27, 27, 27
end

# ---- input ----------------------------------------------------------------------------

# The first input line: a new game.
define seed
  set $seed = (long) $arg0
  set $board = $empty
  set $score = 0
  set $lines = 0
  set $over = 0
  rand
  set $next = $drawn
  spawn
  frame
  if $over
    quit
  end
end

# Every input line after the first: one event.
define event
  set $show = 1
  if $arg0 == 0
    set $t = $t + 1
    if $t >= ($lines / 10 + 1 < 10 ? 11 - ($lines / 10 + 1) : 1)
      set $t = 0
      stepdown
    else
      set $show = 0
    end
  end
  if $arg0 == 1 || $arg0 == 2
    set $tx = $x + ($arg0 == 1 ? -1 : 1)
    set $ty = $y
    set $tr = $r
    fits
    if $ok
      set $x = $tx
    end
  end
  if $arg0 == 3
    # The new rotation at the kicks 0, -1, +1, -2, +2: the first that fits.
    set $kicks = {0, -1, 1, -2, 2}
    set $tr = ($r + 1) % 4
    set $ty = $y
    set $k = 0
    set $ok = 0
    while $k < 5 && !$ok
      set $tx = $x + $kicks[$k]
      fits
      set $k = $k + 1
    end
    if $ok
      set $x = $tx
      set $r = $tr
    end
  end
  if $arg0 == 4
    stepdown
  end
  if $arg0 == 5
    set $tx = $x
    set $ty = $y + 1
    set $tr = $r
    fits
    while $ok
      set $y = $y + 1
      set $ty = $y + 1
      fits
    end
    lock
  end
  if $arg0 > 5
    set $show = 0
  end
  if $show
    frame
  end
  if $over
    quit
  end
end
