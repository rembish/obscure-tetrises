divert(-1)
# m4tris.m4 - a falling-block puzzle game written in m4, the macro processor.
#
#   m4 m4tris.m4 -
#
# stdin: macro calls, one per line: E(seed) first, then E(event) with the
# event numbers from ../SPEC.md (0 tick, 1 left, 2 right, 3 rotate, 4 soft
# drop, 5 hard drop, 9 quit). stdout: ANSI frames.
#
# m4 only ever rewrites text. All game state lives in macro definitions:
# _b0 ... _b199 is the board, _x/_y/_r the falling piece, and so on. Each
# E(...) call redefines some of them. Everything runs with output discarded
# (divert(-1)); only the renderer switches output back on, while it prints a frame.
# Every internal macro starts with an underscore, so no word of the frame text
# can expand by accident.

# ---- helpers -----------------------------------------------------------------
define(`_e', format(`%c', 27))
# m4 rescans expansions together with the text that follows, so ESC[m
# followed by _eol would read as the word m_eol. The trailing `' keeps them apart.
define(`_R', `_e()[m`'')
define(`_B', `_e()[38;5;60m$1`'_R()')
define(`_D', `_e()[38;5;244m$1`'_R()')
define(`_eol', `_e()[K
')
# _for(`var', from, to, `body'): body expands with var = from .. to
define(`_for', `ifelse(eval($2 <= $3), 1, `define(`$1', $2)$4`'_for(`$1', incr($2), $3, `$4')')')

# ---- tables --------------------------------------------------------------------
# _cellsP_R: the four cells (x,y) of piece P in rotation R, decoded from the
# masks in SPEC.md. _maskP: the rotation-0 mask, for the next-piece preview.
define(`_cells0_0', `0, 1, 1, 1, 2, 1, 3, 1')define(`_cells0_1', `2, 0, 2, 1, 2, 2, 2, 3')define(`_cells0_2', `0, 2, 1, 2, 2, 2, 3, 2')define(`_cells0_3', `1, 0, 1, 1, 1, 2, 1, 3')
define(`_cells1_0', `1, 0, 2, 0, 1, 1, 2, 1')define(`_cells1_1', `1, 0, 2, 0, 1, 1, 2, 1')define(`_cells1_2', `1, 0, 2, 0, 1, 1, 2, 1')define(`_cells1_3', `1, 0, 2, 0, 1, 1, 2, 1')
define(`_cells2_0', `1, 0, 0, 1, 1, 1, 2, 1')define(`_cells2_1', `1, 0, 1, 1, 2, 1, 1, 2')define(`_cells2_2', `0, 1, 1, 1, 2, 1, 1, 2')define(`_cells2_3', `1, 0, 0, 1, 1, 1, 1, 2')
define(`_cells3_0', `1, 0, 2, 0, 0, 1, 1, 1')define(`_cells3_1', `1, 0, 1, 1, 2, 1, 2, 2')define(`_cells3_2', `1, 1, 2, 1, 0, 2, 1, 2')define(`_cells3_3', `0, 0, 0, 1, 1, 1, 1, 2')
define(`_cells4_0', `0, 0, 1, 0, 1, 1, 2, 1')define(`_cells4_1', `2, 0, 1, 1, 2, 1, 1, 2')define(`_cells4_2', `0, 1, 1, 1, 1, 2, 2, 2')define(`_cells4_3', `1, 0, 0, 1, 1, 1, 0, 2')
define(`_cells5_0', `0, 0, 0, 1, 1, 1, 2, 1')define(`_cells5_1', `1, 0, 2, 0, 1, 1, 1, 2')define(`_cells5_2', `0, 1, 1, 1, 2, 1, 2, 2')define(`_cells5_3', `1, 0, 1, 1, 0, 2, 1, 2')
define(`_cells6_0', `2, 0, 0, 1, 1, 1, 2, 1')define(`_cells6_1', `1, 0, 1, 1, 1, 2, 2, 2')define(`_cells6_2', `0, 1, 1, 1, 2, 1, 0, 2')define(`_cells6_3', `0, 0, 1, 0, 1, 1, 1, 2')
define(`_mask0', 240)define(`_mask1', 102)define(`_mask2', 114)define(`_mask3', 54)
define(`_mask4', 99)define(`_mask5', 113)define(`_mask6', 116)
define(`_col0', 51)define(`_col1', 226)define(`_col2', 135)define(`_col3', 46)
define(`_col4', 196)define(`_col5', 33)define(`_col6', 208)
define(`_pts0', 0)define(`_pts1', 40)define(`_pts2', 100)define(`_pts3', 300)define(`_pts4', 1200)
define(`_kick0', 0)define(`_kick1', -1)define(`_kick2', 1)define(`_kick3', -2)define(`_kick4', 2)

# ---- random numbers --------------------------------------------------------------
# Park-Miller with Schrage's trick: m4's eval is 32-bit, so s * 16807 would
# overflow. s*a mod m = a*(s mod q) - r*(s div q), plus m if negative,
# where q = m div a = 127773 and r = m mod a = 2836.
define(`_draw', `define(`_s', eval(16807 * (_s % 127773) - 2836 * (_s / 127773)))ifelse(eval(_s < 0), 1, `define(`_s', eval(_s + 2147483647))')define(`_nxt', eval(_s % 7))')

define(`_level', `eval(_lines / 10 + 1)')

# ---- fitting and moving ----------------------------------------------------------
# _ok(x, y): 1 if (x, y) is on the board and empty
define(`_ok', `ifelse(eval($1 < 0 || $1 > 9 || $2 < 0 || $2 > 19), 1, 0, `ifelse(indir(`_b'eval($2 * 10 + $1)), 0, 1, 0)')')
define(`_fits4', `eval(_ok(eval(_px + $1), eval(_py + $2)) * _ok(eval(_px + $3), eval(_py + $4)) * _ok(eval(_px + $5), eval(_py + $6)) * _ok(eval(_px + $7), eval(_py + $8)))')
# _fits(x, y, rot): does the current piece fit there? Expands to 1 or 0.
define(`_fits', `define(`_px', $1)define(`_py', $2)_fits4(indir(`_cells'_cur`_'$3))')

# _paint(v): write v into the current piece's cells
define(`_set', `define(`_b'eval((_y + $2) * 10 + _x + $1), $3)')
define(`_paint4', `_set($2, $3, $1)_set($4, $5, $1)_set($6, $7, $1)_set($8, $9, $1)')
define(`_paint', `_paint4($1, indir(`_cells'_cur`_'_r))')

define(`_spawn', `define(`_x', 3)define(`_y', 0)define(`_r', 0)define(`_t', 0)ifelse(_fits(3, 0, 0), 0, `define(`_over', 1)')')

# _compact: walk rows bottom-up, copying every row that isn't full down to _dst
define(`_rowcount', `define(`_cnt', 0)_for(`_j', 0, 9, `ifelse(indir(`_b'eval($1 * 10 + _j)), 0, , `define(`_cnt', incr(_cnt))')')')
define(`_crow', `_rowcount($1)ifelse(_cnt, 10, , `_for(`_j', 0, 9, `define(`_b'eval(_dst * 10 + _j), indir(`_b'eval($1 * 10 + _j)))')define(`_dst', decr(_dst))')')
define(`_compact', `define(`_dst', 19)_for(`_k', 0, 19, `_crow(eval(19 - _k))')define(`_cleared', eval(_dst + 1))_for(`_k', 0, eval(_cleared * 10 - 1), `define(`_b'_k, 0)')')

define(`_lock', `_paint(incr(_cur))_compact()define(`_score', eval(_score + indir(`_pts'_cleared) * _level))define(`_lines', eval(_lines + _cleared))define(`_cur', _nxt)_draw()_spawn()')

define(`_stepdown', `ifelse(_fits(_x, incr(_y), _r), 1, `define(`_y', incr(_y))', `_lock()')')
define(`_left', `ifelse(_fits(decr(_x), _y, _r), 1, `define(`_x', decr(_x))')')
define(`_right', `ifelse(_fits(incr(_x), _y, _r), 1, `define(`_x', incr(_x))')')
define(`_kick', `ifelse(_fits(eval(_x + $1), _y, _nr), 1, `define(`_x', eval(_x + $1))define(`_r', _nr)define(`_done', 1)')')
define(`_rotate', `define(`_nr', eval((_r + 1) % 4))define(`_done', 0)_for(`_k', 0, 4, `ifelse(_done, 0, `_kick(indir(`_kick'_k))')')')
define(`_hd', `ifelse(_fits(_x, incr(_y), _r), 1, `define(`_y', incr(_y))_hd()', `_lock()')')
define(`_tick', `define(`_t', incr(_t))ifelse(eval(_t + _level >= 11), 1, `define(`_t', 0)_stepdown()', `define(`_emit', 0)')')

# ---- rendering -------------------------------------------------------------------
define(`_blk', `_e()[38;5;`'indir(`_col'$1)m██`'_R()')
define(`_cell', `ifelse($1, 0, `_e()[38;5;237m ·_R()', `_blk(decr($1))')')
define(`_nrow', `_for(`_q', 0, 3, `ifelse(eval((indir(`_mask'_nxt) >> ($1 * 4 + _q)) & 1), 1, `_blk(_nxt)', `  ')')')

define(`_p0', `   _B(`╭──') _D(`next') _B(`──────╮')')
define(`_p1', `   _B(`│')              _B(`│')')
define(`_p2', `   _B(`│')   _nrow(0)   _B(`│')')
define(`_p3', `   _B(`│')   _nrow(1)   _B(`│')')
define(`_p4', `   _B(`│')   _nrow(2)   _B(`│')')
define(`_p5', `   _B(`│')   _nrow(3)   _B(`│')')
define(`_p6', defn(`_p1'))
define(`_p7', `   _B(`╰──────────────╯')')
define(`_p9', `   _D(`score')')
define(`_p10', `   _e()[1m`'_score`'_R()')
define(`_p11', `   _D(`level') _e()[1m`'_level`'_R()  _D(`lines') _e()[1m`'_lines`'_R()')
define(`_p13', `   _D(`controls')')
define(`_p14', `   _e()[1m← a`'_R()  _D(`move left')')
define(`_p15', `   _e()[1m→ d`'_R()  _D(`move right')')
define(`_p16', `   _e()[1m↑ w`'_R()  _D(`rotate')')
define(`_p17', `   _e()[1m↓ s`'_R()  _D(`soft drop')')
define(`_p18', `   _e()[1m␣ z`'_R()  _D(`hard drop')')
define(`_p19', `   _e()[1m  q`'_R()  _D(`quit')')
define(`_panel', `ifdef(`_p'_row, `indir(`_p'_row)')')

define(`_line', ` _B(`║')ifelse(eval(_over && _row == 9), 1, `_e()[1;7m     GAME  OVER     _R()', `_for(`_j', 0, 9, `_cell(indir(`_b'eval(_row * 10 + _j)))')')_B(`║')_panel()_eol()')
define(`_frame', `_e()[H  _e()[1;38;5;75mM 4 T R I S`'_R()_eol()dnl
 _B(`╔════════════════════╗')_eol()dnl
_for(`_row', 0, 19, `_line()')dnl
 _B(`╚════════════════════╝')_eol()dnl
_e()[J`'')
define(`_render', `ifelse(_over, 0, `_paint(incr(_cur))')divert(0)_frame()divert(-1)ifelse(_over, 0, `_paint(0)')')

# ---- events ----------------------------------------------------------------------
define(`_init', `define(`_s', $1)define(`_score', 0)define(`_lines', 0)define(`_over', 0)_for(`_k', 0, 199, `define(`_b'_k, 0)')_draw()define(`_cur', _nxt)_draw()_spawn()define(`_started', 1)_render()')
define(`_event', `ifelse($1, 9, `m4exit(0)')define(`_emit', 1)ifelse($1, 0, `_tick()', $1, 1, `_left()', $1, 2, `_right()', $1, 3, `_rotate()', $1, 4, `_stepdown()', $1, 5, `_hd()', `define(`_emit', 0)')ifelse(_emit, 1, `_render()')ifelse(_over, 1, `m4exit(0)')')
define(`_started', 0)
define(`E', `ifelse(_started, 1, `_event($1)', `_init($1)')')
