# -*- coding:utf-8 -*-
# HW validation test for variant 7 (integer cube root), matches tb.sv
from __future__ import division
import random
import udm
from udm import *

COM_PORT = 'COM4'          # <-- put the COM port of your board
udm = udm(COM_PORT, 921600)
print("")

CSR_CUBE_X_ADDR = 0x10000000
CSR_CUBE_Y_ADDR = 0x20000000

def icbrt(x):  # exact floor cube root
    lo, hi = 0, 1626
    while lo < hi:
        m = (lo + hi + 1) // 2
        if m ** 3 <= x: lo = m
        else: hi = m - 1
    return lo

# 1) directed values (same as the testbench)
directed = [0, 1, 7, 8, 26, 27, 28, 1000, 999999, 1000000,
            0x12345678, 0x7fffffff, 0x80000000, 0xfffffffe, 0xffffffff]
errors = 0
for x in directed:
    udm.wr32(CSR_CUBE_X_ADDR, x)
    y = udm.rd32(CSR_CUBE_Y_ADDR)
    ok = (y == icbrt(x))
    errors += (not ok)
    print("%s x=0x%08x y=0x%x expected=0x%x" % ("OK   " if ok else "ERROR", x, y, icbrt(x)))

# 2) test vectors from check_model.py (vectors.txt: "x y" in hex), if the file exists
try:
    n = 0
    for line in open("vectors.txt"):
        xs, ys = line.split()
        x, exp = int(xs, 16), int(ys, 16)
        udm.wr32(CSR_CUBE_X_ADDR, x)
        y = udm.rd32(CSR_CUBE_Y_ADDR)
        if y != exp:
            errors += 1
            print("ERROR x=0x%08x y=0x%x expected=0x%x" % (x, y, exp))
        n += 1
    print("vectors.txt: %d vectors checked" % n)
except IOError:
    print("vectors.txt not found - skipped")

print("RESULT:", "PASSED" if errors == 0 else "FAILED (%d errors)" % errors)
udm.disconnect()
