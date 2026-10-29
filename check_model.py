"""Check that the Python hw model (cube_hw) equals exact integer floor-cbrt on 32-bit inputs,
and that the provided float-based cube_alg does too. Also writes test vectors for the board."""
import random

def cube_hw(x):
    y = 0
    for s in [30, 27, 24, 21, 18, 15, 12, 9, 6, 3, 0]:
        y = 2 * y
        b = (3 * y * (y + 1) + 1) << s
        if x >= b:
            x -= b
            y += 1
    return y

def icbrt(x):  # exact reference
    lo, hi = 0, 1626
    while lo < hi:
        m = (lo + hi + 1) // 2
        if m ** 3 <= x: lo = m
        else: hi = m - 1
    return lo

try:
    import numpy, math
    def cube_alg(x): return math.floor(numpy.cbrt(x))
except ImportError:
    cube_alg = None

xs = {0, 1, 2**32 - 1, 2**31}
for n in range(0, 1626):
    for d in (-1, 0, 1):
        v = n**3 + d
        if 0 <= v < 2**32: xs.add(v)
random.seed(7)
xs.update(random.randrange(2**32) for _ in range(100000))

bad_hw = [x for x in xs if cube_hw(x) != icbrt(x)]
print("cube_hw vs exact: mismatches =", len(bad_hw))
if cube_alg:
    bad_alg = [x for x in xs if int(cube_alg(x)) != icbrt(x)]
    print("cube_alg (float) vs exact: mismatches =", len(bad_alg), bad_alg[:5])

with open("vectors.txt", "w") as f:  # for the on-board test: "x y" in hex
    for x in sorted(random.sample(sorted(xs), 1000)):
        f.write(f"{x:08x} {cube_hw(x):08x}\n")
print("wrote vectors.txt")
