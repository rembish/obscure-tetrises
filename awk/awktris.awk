# awktris.awk - a falling-block puzzle game written in awk.
#
#   awk -f awktris.awk < events > frames
#
# The first input line is the random seed; every line after it is one event
# number (0 tick, 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop, 9 quit).
# After every event that changes something, a whole frame is printed with
# printf and flushed, so the game is playable through a pipe. The rules and
# the exact output bytes are in ../SPEC.md.
#
# Only POSIX awk is used (no gawk extensions): no bitwise functions, no
# arrays of arrays, no `@` anything. It runs the same on mawk, gawk,
# `gawk --posix` and busybox awk.

BEGIN {
    W = 10; H = 20

    # Piece rotations as 16-bit masks, bit y*4+x. awk has no bitwise
    # operators, so the masks are decoded once into cell lists:
    # CX[p,r,k], CY[p,r,k] for the k-th cell (k = 1..4) of piece p, rotation r.
    split("240 17476 3840 8738 102 102 102 102 114 610 624 562 " \
          "54 1122 864 561 99 612 1584 306 113 550 1136 802 " \
          "116 1570 368 547", MASK, " ")
    for (p = 0; p < 7; p++)
        for (r = 0; r < 4; r++) {
            m = MASK[p * 4 + r + 1]; k = 0
            for (i = 0; i < 16; i++) {
                if (m % 2) { k++; CX[p, r, k] = i % 4; CY[p, r, k] = int(i / 4) }
                m = int(m / 2)
            }
        }

    # Escape sequences and pre-built pieces of the frame.
    ESC = "\033"; RST = ESC "[m"
    split("51 226 135 46 196 33 208", COLOUR, " ")
    for (p = 0; p < 7; p++) BLOCK[p] = ESC "[38;5;" COLOUR[p + 1] "m\342\226\210\342\226\210" RST
    EMPTY = ESC "[38;5;237m \302\267" RST
    split("0 40 100 300 1200", POINTS, " ")
    split("0 -1 1 -2 2", KICK, " ")

    HBAR = ""; for (i = 0; i < 20; i++) HBAR = HBAR "\342\225\220"     # "═"
    SBAR = ""; for (i = 0; i < 14; i++) SBAR = SBAR "\342\224\200"     # "─"
    TOP    = " " B("\342\225\224" HBAR "\342\225\227")                    # ╔═╗
    BOTTOM = " " B("\342\225\232" HBAR "\342\225\235")                    # ╚═╝
    WALL   = B("\342\225\221")                                           # ║
    SIDE   = B("\342\224\202")                                           # │

    # Side-panel text for the rows that never change (2-5 and 10-11 are
    # filled in per frame).
    PANEL[0] = "   " B("\342\225\255\342\224\200\342\224\200") " " D("next") " " \
               B("\342\224\200\342\224\200\342\224\200\342\224\200\342\224\200\342\224\200\342\225\256")
    PANEL[1] = PANEL[6] = "   " SIDE "              " SIDE
    PANEL[7] = "   " B("\342\225\260" SBAR "\342\225\257")
    PANEL[9] = "   " D("score")
    PANEL[13] = "   " D("controls")
    split("\342\206\220 a|\342\206\222 d|\342\206\221 w|\342\206\223 s|\342\220\243 z|  q", KEY, "|")
    split("move left|move right|rotate|soft drop|hard drop|quit", ACTION, "|")
    for (i = 1; i <= 6; i++)
        PANEL[13 + i] = "   " ESC "[1m" KEY[i] RST "  " D(ACTION[i])

    TITLE = "  " ESC "[1;38;5;75mA W K T R I S" RST
    started = 0
}

function B(s) { return ESC "[38;5;60m" s RST }      # border colour
function D(s) { return ESC "[38;5;244m" s RST }     # dim text

# Park-Miller: seed * 16807 stays below 2^46, exact in a double.
function rand7() {
    seed = (seed * 16807) % 2147483647
    return seed % 7
}

function level() { return int(lines / 10) + 1 }

# Does the current piece fit at (px, py) in rotation pr?
function fits(px, py, pr,    k, bx, by) {
    for (k = 1; k <= 4; k++) {
        bx = px + CX[cur, pr, k]; by = py + CY[cur, pr, k]
        if (bx < 0 || bx >= W || by < 0 || by >= H || board[by * W + bx]) return 0
    }
    return 1
}

function spawn() {
    x = 3; y = 0; r = 0; t = 0
    if (!fits(x, y, r)) over = 1
}

function lock(    k, row, col, dst, full, n) {
    for (k = 1; k <= 4; k++)
        board[(y + CY[cur, r, k]) * W + x + CX[cur, r, k]] = cur + 1
    # Copy rows bottom-up; the destination only moves up past rows that
    # are not full, so full rows get overwritten. Then clear what is left.
    dst = H - 1
    for (row = H - 1; row >= 0; row--) {
        full = 1
        for (col = 0; col < W; col++) if (!board[row * W + col]) { full = 0; break }
        if (full) continue
        if (dst != row)
            for (col = 0; col < W; col++) board[dst * W + col] = board[row * W + col]
        dst--
    }
    n = dst + 1                     # rows removed
    for (row = dst; row >= 0; row--)
        for (col = 0; col < W; col++) board[row * W + col] = 0
    score += POINTS[n + 1] * level()
    lines += n
    cur = nxt; nxt = rand7()
    spawn()
}

function step_down() {
    if (fits(x, y + 1, r)) y++
    else lock()
}

# Apply one event; return 1 if a frame should be printed.
function event(e,    g, nr, k, dx) {
    if (e == 0) {
        g = 11 - level(); if (g < 1) g = 1
        if (++t < g) return 0
        t = 0
        step_down()
    } else if (e == 1 || e == 2) {
        dx = e == 1 ? -1 : 1
        if (fits(x + dx, y, r)) x += dx
    } else if (e == 3) {
        nr = (r + 1) % 4
        for (k = 1; k <= 5; k++)
            if (fits(x + KICK[k], y, nr)) { x += KICK[k]; r = nr; break }
    } else if (e == 4) {
        step_down()
    } else if (e == 5) {
        while (fits(x, y + 1, r)) y++
        lock()
    } else return 0
    return 1
}

function render(    grid, i, k, row, col, s, line, c, nx, ny) {
    for (i = 0; i < W * H; i++) grid[i] = board[i]
    if (!over)
        for (k = 1; k <= 4; k++)
            grid[(y + CY[cur, r, k]) * W + x + CX[cur, r, k]] = cur + 1

    # Next-piece box: rows 0-3, two spaces per empty cell.
    for (row = 0; row < 4; row++)
        for (col = 0; col < 4; col++) nbox[row, col] = "  "
    for (k = 1; k <= 4; k++) nbox[CY[nxt, 0, k], CX[nxt, 0, k]] = BLOCK[nxt]
    for (row = 0; row < 4; row++)
        PANEL[2 + row] = "   " SIDE "   " nbox[row, 0] nbox[row, 1] nbox[row, 2] nbox[row, 3] "   " SIDE
    PANEL[10] = "   " ESC "[1m" score RST
    PANEL[11] = "   " D("level") " " ESC "[1m" level() RST "  " D("lines") " " ESC "[1m" lines RST

    s = ESC "[H" TITLE ESC "[K\n" TOP ESC "[K\n"
    for (row = 0; row < H; row++) {
        if (over && row == 9)
            line = ESC "[1;7m     GAME  OVER     " RST
        else {
            line = ""
            for (col = 0; col < W; col++) {
                c = grid[row * W + col]
                line = line (c ? BLOCK[c - 1] : EMPTY)
            }
        }
        s = s " " WALL line WALL PANEL[row] ESC "[K\n"
    }
    s = s BOTTOM ESC "[K\n"
    printf "%s", s
    fflush()            # one frame per event, even through a pipe
}

# Skip blank lines, like the reference does.
/^[ \t\r]*$/ { next }

!started {
    started = 1
    seed = $1 + 0
    for (i = 0; i < W * H; i++) board[i] = 0
    score = lines = over = 0
    cur = rand7(); nxt = rand7()
    spawn()
    render()
    if (over) exit
    next
}

{
    e = $1 + 0
    if (e == 9) exit
    if (event(e)) {
        render()
        if (over) exit
    }
}
