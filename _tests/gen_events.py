#!/usr/bin/env python3
"""Generate deterministic event streams for _tests/check.sh.

    gen_events.py bot SEED [PIECES]   a greedy bot that clears lines
    gen_events.py fuzz SEED [COUNT]   random keys and ticks, including edge cases

Writes the seed on the first line, then one event per line, as SPEC.md describes.
"""
import random
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from reference import Game, cells, H, W  # noqa: E402


def heights_and_holes(board):
    agg = holes = 0
    hs = []
    for x in range(W):
        col = [board[y][x] for y in range(H)]
        top = next((y for y in range(H) if col[y]), H)
        hs.append(H - top)
        holes += sum(1 for y in range(top, H) if not col[y])
    agg = sum(hs)
    bump = sum(abs(hs[i] - hs[i + 1]) for i in range(W - 1))
    return agg, holes, bump


def evaluate(g, r, x):
    """Score dropping the current piece at rotation r, column x (lower is better)."""
    if not g.fits(x, 0, r):
        return None
    y = 0
    while g.fits(x, y + 1, r):
        y += 1
    board = [row[:] for row in g.board]
    for cx, cy in cells(g.cur, r):
        board[y + cy][x + cx] = 1
    full = sum(1 for row in board if 0 not in row)
    board = [row for row in board if 0 in row]
    board = [[0] * W for _ in range(H - len(board))] + board
    agg, holes, bump = heights_and_holes(board)
    return 0.51 * agg + 0.36 * holes * 2 + 0.18 * bump - 0.76 * full


def bot(seed, pieces):
    rnd = random.Random(seed)
    g = Game(seed)
    ev = []

    def send(e):
        ev.append(e)
        g.event(e)

    for _ in range(pieces):
        if g.over:
            break
        best = None
        for r in range(4):
            for x in range(-2, W):
                v = evaluate(g, r, x)
                if v is not None and (best is None or v < best[0]):
                    best = (v, r, x)
        if best is None:
            send(5)
            continue
        _, r, x = best
        start = g.cur
        for _ in range(r):
            send(3)
            for _ in range(rnd.randint(0, 2)):
                send(0)
        while g.cur == start and not g.over and g.x != x:
            send(1 if g.x > x else 2)
            if g.x != x and not g.fits(g.x + (1 if x > g.x else -1), g.y, g.r):
                break
            for _ in range(rnd.randint(0, 3)):
                send(0)
        if g.cur == start and not g.over:
            if rnd.random() < 0.3:
                for _ in range(rnd.randint(1, 3)):
                    send(4)
            send(5)
    return seed, ev


def fuzz(seed, count):
    rnd = random.Random(seed)
    weights = {0: 40, 1: 10, 2: 10, 3: 12, 4: 8, 5: 3, 7: 1}
    pool = [e for e, w in weights.items() for _ in range(w)]
    return seed, [rnd.choice(pool) for _ in range(count)]


def main():
    mode, seed = sys.argv[1], int(sys.argv[2])
    n = int(sys.argv[3]) if len(sys.argv) > 3 else (300 if mode == "bot" else 4000)
    s, ev = (bot if mode == "bot" else fuzz)(seed, n)
    # end with a quit event and a few ticks the engine must not act on
    sys.stdout.write(f"{s}\n" + "".join(f"{e}\n" for e in ev + [9, 0, 5, 0]))


if __name__ == "__main__":
    main()
