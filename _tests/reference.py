#!/usr/bin/env python3
"""Reference implementation of SPEC.md, used as the test oracle.

    reference.py [TITLE] < events > frames

Reads the seed and events from stdin and writes frames to stdout.
"""
import sys

MASKS = [
    [240, 17476, 3840, 8738],   # I
    [102, 102, 102, 102],       # O
    [114, 610, 624, 562],       # T
    [54, 1122, 864, 561],       # S
    [99, 612, 1584, 306],       # Z
    [113, 550, 1136, 802],      # J
    [116, 1570, 368, 547],      # L
]
COLOURS = [51, 226, 135, 46, 196, 33, 208]
W, H = 10, 20
E = "\x1b"
R = E + "[m"


def B(s): return f"{E}[38;5;60m{s}{R}"
def D(s): return f"{E}[38;5;244m{s}{R}"
def block(p): return f"{E}[38;5;{COLOURS[p]}m██{R}"


def cells(p, r):
    m = MASKS[p][r]
    return [(i % 4, i // 4) for i in range(16) if m >> i & 1]


class Game:
    def __init__(self, seed):
        self.s = seed
        self.board = [[0] * W for _ in range(H)]
        self.score = self.lines = 0
        self.over = False
        self.cur = self.rand()
        self.nxt = self.rand()
        self.spawn()

    def rand(self):
        self.s = self.s * 16807 % 2147483647
        return self.s % 7

    def level(self): return self.lines // 10 + 1

    def fits(self, x, y, r):
        for cx, cy in cells(self.cur, r):
            bx, by = x + cx, y + cy
            if not (0 <= bx < W and 0 <= by < H) or self.board[by][bx]:
                return False
        return True

    def spawn(self):
        self.x, self.y, self.r, self.t = 3, 0, 0, 0
        if not self.fits(self.x, self.y, self.r):
            self.over = True

    def lock(self):
        for cx, cy in cells(self.cur, self.r):
            self.board[self.y + cy][self.x + cx] = self.cur + 1
        kept = [row for row in self.board if 0 in row]
        n = H - len(kept)
        self.board = [[0] * W for _ in range(n)] + kept
        self.score += [0, 40, 100, 300, 1200][n] * self.level()
        self.lines += n
        self.cur, self.nxt = self.nxt, self.rand()
        self.spawn()

    def step_down(self):
        if self.fits(self.x, self.y + 1, self.r):
            self.y += 1
        else:
            self.lock()

    def event(self, e):
        """Apply one event; return True if a frame should be printed."""
        if e == 0:
            self.t += 1
            if self.t < max(1, 11 - self.level()):
                return False
            self.t = 0
            self.step_down()
        elif e in (1, 2):
            dx = -1 if e == 1 else 1
            if self.fits(self.x + dx, self.y, self.r):
                self.x += dx
        elif e == 3:
            nr = (self.r + 1) % 4
            for dx in (0, -1, 1, -2, 2):
                if self.fits(self.x + dx, self.y, nr):
                    self.x += dx
                    self.r = nr
                    break
        elif e == 4:
            self.step_down()
        elif e == 5:
            while self.fits(self.x, self.y + 1, self.r):
                self.y += 1
            self.lock()
        else:
            return False
        return True

    def render(self, title):
        grid = [row[:] for row in self.board]
        if not self.over:
            for cx, cy in cells(self.cur, self.r):
                grid[self.y + cy][self.x + cx] = self.cur + 1
        nxt = MASKS[self.nxt][0]
        keys = [("← a", "move left"), ("→ d", "move right"), ("↑ w", "rotate"),
                ("↓ s", "soft drop"), ("␣ z", "hard drop"), ("  q", "quit")]
        panel = {
            0: "   " + B("╭──") + " " + D("next") + " " + B("──────╮"),
            1: "   " + B("│") + " " * 14 + B("│"),
            6: "   " + B("│") + " " * 14 + B("│"),
            7: "   " + B("╰" + "─" * 14 + "╯"),
            9: "   " + D("score"),
            10: f"   {E}[1m{self.score}{R}",
            11: f"   {D('level')} {E}[1m{self.level()}{R}  {D('lines')} {E}[1m{self.lines}{R}",
            13: "   " + D("controls"),
        }
        for y in range(4):
            row = "".join(block(self.nxt) if nxt >> (y * 4 + x) & 1 else "  "
                          for x in range(4))
            panel[2 + y] = "   " + B("│") + "   " + row + "   " + B("│")
        for i, (k, a) in enumerate(keys):
            panel[14 + i] = f"   {E}[1m{k}{R}  {D(a)}"

        lines = [f"  {E}[1;38;5;75m{title}{R}", " " + B("╔" + "═" * 20 + "╗")]
        for y in range(H):
            if self.over and y == 9:
                body = f"{E}[1;7m     GAME  OVER     {R}"
            else:
                body = "".join(block(c - 1) if c else f"{E}[38;5;237m ·{R}"
                               for c in grid[y])
            lines.append(" " + B("║") + body + B("║") + panel.get(y, ""))
        lines.append(" " + B("╚" + "═" * 20 + "╝"))
        return E + "[H" + "".join(l + E + "[K\n" for l in lines) + E + "[J"


def main():
    title = sys.argv[1] if len(sys.argv) > 1 else "J Q T R I S"
    out = sys.stdout
    seed = int(sys.stdin.readline())
    g = Game(seed)
    out.write(g.render(title))
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        if int(line) == 9:
            break
        if g.event(int(line)):
            out.write(g.render(title))
            if g.over:
                break
    out.flush()


if __name__ == "__main__":
    main()
