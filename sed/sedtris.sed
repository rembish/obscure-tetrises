#!/bin/sed -nEuf
# sedtris.sed - a falling-block puzzle game written in GNU sed.
#
#   LC_ALL=C sed -n -E -u -f sedtris.sed      (sedtris.sh does this for you)
#
# Input: the seed on the first line, then one event per line (../SPEC.md):
# 0 tick, 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop, 9 quit.
# Output: a frame after every event, except ticks that moved nothing.
#
# Everything happens in sed: the Park-Miller generator (in binary, on strings
# of 0 and 1), gravity, rotation with wall kicks, line clears, score, level
# and the frame itself. There are no numbers in sed, so:
#
#   - small counters are unary, runs of "x";
#   - score and lines are "column unary": one run of x per decimal digit,
#     most significant first, separated by commas (",xxxx," is 040);
#   - the random seed is a 31-bit binary string.
#
# Between input lines the whole game lives in the hold space, as two lines:
#
#   Ta;J;Cxxxx;Gxxxxxxxxxx;S,,;L;Vx;R0000000000000000101001000010011
#   ################..........######..........######...  (the board)
#
#   Ta    current piece (I O T S Z J L) and rotation (a b c d = 0 1 2 3)
#   J     next piece
#   C     gravity countdown: ticks left before the piece steps down
#   G     gravity interval, max(1, 11 - level) in unary
#   S, L  score and lines, column unary
#   V     level, unary
#   R     the random seed, 31 bits
#
# The board is one string of 16-character rows: ten cells, then six walls
# "######". A wall row sits on top and four more make the floor, so a piece
# that pokes out of the well always hits a "#": bounds checks are free. A
# cell is "." when empty, an upper-case piece letter when locked, and a
# lower-case one for the falling piece, which is always drawn in the board.
# "@" marks the top-left corner of the falling piece's 4x4 box. Going down a
# row is 16 characters further on, so each piece shape is just a regex of
# gaps after the "@": T in rotation 0 is "@.\..{14}\.\.\.".
#
# The regexes are extended (-E). GNU extensions used: \n and \xHH in the
# replacement of s///, \n in regexes, "s//" reusing the last regex, and -u
# to read input line by line and flush every frame at once.

# ---- dispatch -----------------------------------------------------------------
1b init
/^9$/q
/^[0-5]$/!d
# Fetch the game: "event\nstate\nboard". Hold keeps the old state, so a
# move that does not fit is undone with "g".
G
s/^0\n//
t tick
s/^1\n//
t left
s/^2\n//
t right
s/^3\n//
t rotate
s/^4\n//
t down
s/^5\n//
t hard

# ---- start-up -------------------------------------------------------------------
# Line 1 is the seed in decimal. Halve it 31 times; each remainder is one bit,
# written as a/b so the digit tricks below don't touch it. Halving: mark odd
# digits with "o", halve every digit with y, and an "o" adds 5 to the digit
# after it. An "o" left at the end is the remainder.
:init
s/$/;/
:bin
s/[13579]/&o/g
y/0123456789/0011223344/
s/o0/5/g
s/o1/6/g
s/o2/7/g
s/o3/8/g
s/o4/9/g
s/;/;a/
s/o;a/;b/
/;[ab]{31}$/!b bin
s/.*;//
y/ab/01/
# The state, with "?" for the pieces not drawn yet, and an empty board.
s/^/?a;?;C;Gxxxxxxxxxx;S,,;L;Vx;R/
s/$/\n################YYYYYYYYYYYYYYYYYYYY################################################################/
s/Y/..........######/g
b draw

# ---- events ---------------------------------------------------------------------
# A tick counts down C. At zero C starts again from G and the piece steps
# down; otherwise nothing moved and no frame is printed.
:tick
s/;Cx/;C/
/;C;/!b noframe
s/;C;G(x*)/;C\1;G\1/
b down

# Every move works the same way: erase the falling piece (y turns its cells
# back into "."), move the "@", then try to stamp the piece there. The stamp
# only succeeds if all four cells are empty. A one-character return code in
# front of the state says where to go next (sed has no subroutines).
:left
y/iotszjl/......./
s/(.)@/@\1/
s/^/M/
b stamp

:right
y/iotszjl/......./
s/@(.)/\1@/
s/^/M/
b stamp

:rM
t rM_ok
g
b frame
:rM_ok
s/^.//
b frame

# Rotate: y steps the rotation letter, then the kicks 0, -1, +1, -2, +2 are
# tried in turn, with the return codes 1 to 5 counting the attempts.
:rotate
y/iotszjl/......./
y/abcd/bcda/
s/^/1/
b stamp
:rR
t rR_ok
/^1/{
  s/^1/2/
  s/(.)@/@\1/
  b stamp
}
/^2/{
  s/^2/3/
  s/@(..)/\1@/
  b stamp
}
/^3/{
  s/^3/4/
  s/(...)@/@\1/
  b stamp
}
/^4/{
  s/^4/5/
  s/@(....)/\1@/
  b stamp
}
g
b frame
:rR_ok
s/^.//
b frame

# Step down (soft drop, or a tick that ran out): one row down is 16
# characters along. If it doesn't fit, the piece locks where it was.
:down
y/iotszjl/......./
s/@(.{16})/\1@/
s/^/D/
b stamp
:rD
t rD_ok
g
b lock
:rD_ok
s/^.//
b frame

# Hard drop: step down until it doesn't fit, saving each good position in
# the hold space, then lock.
:hard
h
y/iotszjl/......./
s/@(.{16})/\1@/
s/^/H/
b stamp
:rH
t rH_ok
g
b lock
:rH_ok
s/^.//
b hard

# ---- the piece shapes -----------------------------------------------------------
# Stamp the current piece at "@": each line matches four empty cells at the
# offsets of one piece and rotation, and writes the lower-case letter into
# them. Whether it matched is left in the t flag for the caller, which is
# picked by the return code. The first "t" clears the flag.
:stamp
t stamp_go
:stamp_go
/^.Ia/ s/@(.{16})\.\.\.\./@\1iiii/
/^.Ib/ s/@(.{2})\.(.{15})\.(.{15})\.(.{15})\./@\1i\2i\3i\4i/
/^.Ic/ s/@(.{32})\.\.\.\./@\1iiii/
/^.Id/ s/@(.)\.(.{15})\.(.{15})\.(.{15})\./@\1i\2i\3i\4i/
/^.O/  s/@(.)\.\.(.{14})\.\./@\1oo\2oo/
/^.Ta/ s/@(.)\.(.{14})\.\.\./@\1t\2ttt/
/^.Tb/ s/@(.)\.(.{15})\.\.(.{14})\./@\1t\2tt\3t/
/^.Tc/ s/@(.{16})\.\.\.(.{14})\./@\1ttt\2t/
/^.Td/ s/@(.)\.(.{14})\.\.(.{15})\./@\1t\2tt\3t/
/^.Sa/ s/@(.)\.\.(.{13})\.\./@\1ss\2ss/
/^.Sb/ s/@(.)\.(.{15})\.\.(.{15})\./@\1s\2ss\3s/
/^.Sc/ s/@(.{17})\.\.(.{13})\.\./@\1ss\2ss/
/^.Sd/ s/@\.(.{15})\.\.(.{15})\./@s\1ss\2s/
/^.Za/ s/@\.\.(.{15})\.\./@zz\1zz/
/^.Zb/ s/@(.{2})\.(.{14})\.\.(.{14})\./@\1z\2zz\3z/
/^.Zc/ s/@(.{16})\.\.(.{15})\.\./@\1zz\2zz/
/^.Zd/ s/@(.)\.(.{14})\.\.(.{14})\./@\1z\2zz\3z/
/^.Ja/ s/@\.(.{15})\.\.\./@j\1jjj/
/^.Jb/ s/@(.)\.\.(.{14})\.(.{15})\./@\1jj\2j\3j/
/^.Jc/ s/@(.{16})\.\.\.(.{15})\./@\1jjj\2j/
/^.Jd/ s/@(.)\.(.{15})\.(.{14})\.\./@\1j\2j\3jj/
/^.La/ s/@(.{2})\.(.{13})\.\.\./@\1l\2lll/
/^.Lb/ s/@(.)\.(.{15})\.(.{15})\.\./@\1l\2l\3ll/
/^.Lc/ s/@(.{16})\.\.\.(.{13})\./@\1lll\2l/
/^.Ld/ s/@\.\.(.{15})\.(.{15})\./@ll\1l\2l/
/^M/b rM
/^[1-5]/b rR
/^D/b rD
/^H/b rH
/^S/b rS

# ---- locking --------------------------------------------------------------------
# Lock: the falling piece becomes upper case. A full row is ten piece letters
# in a row (walls separate the rows); delete it and add an empty row under the
# top wall, putting a "+" in front for each row cleared.
:lock
y/iotszjl/IOTSZJL/
s/@//
:clear
/[IOTSZJL]{10}######/{
  s///
  s/\n#{16}/&..........######/
  s/^/+/
  b clear
}
/^\+/!b draw
s/^\+{4}/4/
s/^\+{3}/3/
s/^\+\+/2/
s/^\+/1/
# Score: add 40, 100, 300 or 1200 once per level, using a copy of V as the
# loop counter: "n<copy of V>:state". 40 is four x in the tens column, the
# others go into the hundreds; carries are sorted out afterwards.
s/^(.)(.*;V(x*))/\1\3:\2/
:score
/^1x/s/(;S[^;]*)(,[^,;]*;)/\1xxxx\2/
/^2x/s/(;S[^;]*)(,[^,;]*,[^,;]*;)/\1x\2/
/^3x/s/(;S[^;]*)(,[^,;]*,[^,;]*;)/\1xxx\2/
/^4x/s/(;S[^;]*)(,[^,;]*,[^,;]*;)/\1xxxxxxxxxxxx\2/
s/^(.)x/\1/
/^.x/b score
# Lines: add n to the units column.
/^1/s/(;L[^;]*)(;V)/\1x\2/
/^2/s/(;L[^;]*)(;V)/\1xx\2/
/^3/s/(;L[^;]*)(;V)/\1xxx\2/
/^4/s/(;L[^;]*)(;V)/\1xxxx\2/
s/^.://
# Ten or more in the units of lines means we passed a multiple of ten: one
# level up, and gravity one tick faster (but never under one tick).
/x{10};V/{
  s/;V/;Vx/
  s/;Gxx/;Gx/
}
# Carry: a column with ten x gives one x to the column on its left.
:carry
s/,(x*)x{10}/x,\1/
t carry
s/([SL])(x*)x{10}/\1x,\2/
t carry

# ---- the next piece -------------------------------------------------------------
# s = s * 16807 mod (2^31 - 1). 16807 is 7^5, and modulo 2^31 - 1 times 8 is a
# rotation of the 31 bits and -s is "not s". So 7s = 8s - s is "rotate by 3,
# then add the complement", with the carry out of the top added back at the
# bottom. Five rounds of that make 16807.
:draw
h
s/.*;R([01]*).*/\1/
s/^/xxxxx;/
:times7
s/;(...)([01]*)$/;\2\1,\1\2,0/
# "A,B,cR": add the last bit of A, the complement of the last bit of B and
# the carry c; the new carry replaces c and the sum bit goes in front of R.
:add
s/0,([01]*)0,0/,\1,01/
s/0,([01]*)0,1/,\1,10/
s/0,([01]*)1,0/,\1,00/
s/0,([01]*)1,1/,\1,01/
s/1,([01]*)0,0/,\1,10/
s/1,([01]*)0,1/,\1,11/
s/1,([01]*)1,0/,\1,01/
s/1,([01]*)1,1/,\1,10/
t add
s/;,,0/;/
/;,,1/{
  s/;,,1/;/
  :inc
  s/1(_*)$/_\1/
  t inc
  s/0(_*)$/1\1/
  s/_/0/g
}
s/^x//
/^x/b times7
s/^;//
H
# The piece is s mod 7. 8 is 1 mod 7, so that is the sum of the octal digits
# mod 7: pad to 33 bits, turn each group of three into that many x, and drop
# sevens.
s/^/00/
s/[01][01][01]/&;/g
s/000;//g
s/001;/x/g
s/010;/xx/g
s/011;/xxx/g
s/100;/xxxx/g
s/101;/xxxxx/g
s/110;/xxxxxx/g
s/111;/xxxxxxx/g
s/x{7}//g
s/^$/I/
s/^x$/O/
s/^xx$/T/
s/^xxx$/S/
s/^x{4}$/Z/
s/^x{5}$/J/
s/^x{6}$/L/
# "letter\nstate\nboard\nbits": the next piece becomes the current one, the
# new letter the next one, and the new bits the seed.
G
s/^(.)\n.(.);(.);(.*;R)[01]*(\n[^\n]*)\n([01]*)$/\3\2;\1;\4\6\5/
# At start-up the first draw only filled in the next piece: draw again.
/^\?/b draw

# ---- spawn ----------------------------------------------------------------------
# Put "@" at x = 3 of row 0, rotation a, the countdown full. If the piece
# doesn't fit there, the game is over.
:spawn
s/(\n#{16}...)/\1@/
s/^(.)./\1a/
s/;C[^;]*;G([^;]*)/;C\1;G\1/
s/^/S/
b stamp
:rS
t rS_ok
s/^.//
s/@//
# Game over: row 9 (160 characters into the board) is replaced by %s, which
# become the GAME OVER banner at the end.
s/\n(.{160}).{10}/\n\1%%%%%%%%%%/
b frame
:rS_ok
s/^.//

# ---- the frame ------------------------------------------------------------------
# Save the state, then turn the pattern space into the frame:
#   1. "board~next score level lines" with the numbers in column unary,
#   2. the board rows ending in "|", the falling piece upper case,
#   3. one s/|/.../ per row adds the side panel and the next row's border,
#      taking the preview cells and the numbers from behind the "~",
#   4. then the cells are coloured, and the title goes on top.
# The order matters: the panel text is lower case and the title upper case,
# so the y and the colouring of piece letters must not see them.
:frame
h
s/^[^;]*;(.);[^;]*;[^;]*;(S[^;]*);(L[^;]*);(V[^;]*);[^\n]*\n(.*)/\5~\1\2;\4;\3;/
s/@//
y/iotszjl/IOTSZJL/
s/^#*//
s/#*~/|~/
s/######/|/g
# The next piece's 4x4 box, row by row: "_" is an empty preview cell.
s/~I/~____IIII________/
s/~O/~_OO__OO_________/
s/~T/~_T__TTT_________/
s/~S/~_SS_SS__________/
s/~Z/~ZZ___ZZ_________/
s/~J/~J___JJJ_________/
s/~L/~__L_LLL_________/
# The level, in unary, gets its carries too; then column unary to decimal:
# each run of x becomes its digit, an empty column a 0, and leading zeros go.
:vcarry
s/,(x*)x{10}/x,\1/
t vcarry
s/V(x*)x{10}/Vx,\1/
t vcarry
s/x{9}/9/g
s/x{8}/8/g
s/x{7}/7/g
s/x{6}/6/g
s/x{5}/5/g
s/x{4}/4/g
s/xxx/3/g
s/xx/2/g
s/x/1/g
:zero
s/([SLV,])([,;])/\10\2/g
t zero
s/,//g
s/([SLV])0*([0-9])/\1\2/g
# The 20 rows, top to bottom.
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[38;5;60m╭──\x1b[m \x1b[38;5;244mnext\x1b[m \x1b[38;5;60m──────╮\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[38;5;60m│\x1b[m              \x1b[38;5;60m│\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|(.*~)(....)/\x1b[38;5;60m║\x1b[m   \x1b[38;5;60m│\x1b[m   \2   \x1b[38;5;60m│\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m\1/
s/\|(.*~)(....)/\x1b[38;5;60m║\x1b[m   \x1b[38;5;60m│\x1b[m   \2   \x1b[38;5;60m│\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m\1/
s/\|(.*~)(....)/\x1b[38;5;60m║\x1b[m   \x1b[38;5;60m│\x1b[m   \2   \x1b[38;5;60m│\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m\1/
s/\|(.*~)(....)/\x1b[38;5;60m║\x1b[m   \x1b[38;5;60m│\x1b[m   \2   \x1b[38;5;60m│\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m\1/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[38;5;60m│\x1b[m              \x1b[38;5;60m│\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[38;5;60m╰──────────────╯\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[38;5;244mscore\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|(.*~)S([0-9]*);/\x1b[38;5;60m║\x1b[m   \x1b[1m\2\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m\1/
s/\|(.*~)V([0-9]*);L([0-9]*);/\x1b[38;5;60m║\x1b[m   \x1b[38;5;244mlevel\x1b[m \x1b[1m\2\x1b[m  \x1b[38;5;244mlines\x1b[m \x1b[1m\3\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m\1/
s/\|/\x1b[38;5;60m║\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[38;5;244mcontrols\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[1m← a\x1b[m  \x1b[38;5;244mmove left\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[1m→ d\x1b[m  \x1b[38;5;244mmove right\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[1m↑ w\x1b[m  \x1b[38;5;244mrotate\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[1m↓ s\x1b[m  \x1b[38;5;244msoft drop\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[1m␣ z\x1b[m  \x1b[38;5;244mhard drop\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
s/\|/\x1b[38;5;60m║\x1b[m   \x1b[1m  q\x1b[m  \x1b[38;5;244mquit\x1b[m\x1b[K\n \x1b[38;5;60m╚════════════════════╝\x1b[m\x1b[K/
s/~.*//
# Colour the cells and the preview, then the banner and the title.
s/\./\x1b[38;5;237m ·\x1b[m/g
s/I/\x1b[38;5;51m██\x1b[m/g
s/O/\x1b[38;5;226m██\x1b[m/g
s/T/\x1b[38;5;135m██\x1b[m/g
s/S/\x1b[38;5;46m██\x1b[m/g
s/Z/\x1b[38;5;196m██\x1b[m/g
s/J/\x1b[38;5;33m██\x1b[m/g
s/L/\x1b[38;5;208m██\x1b[m/g
s/_/  /g
s/%{10}/\x1b[1;7m     GAME  OVER     \x1b[m/
s/^/\x1b[H  \x1b[1;38;5;75mS E D T R I S\x1b[m\x1b[K\n \x1b[38;5;60m╔════════════════════╗\x1b[m\x1b[K\n \x1b[38;5;60m║\x1b[m/
p
/GAME  OVER/q
d

# A tick that moved nothing: keep the new countdown, print nothing.
:noframe
h
d
