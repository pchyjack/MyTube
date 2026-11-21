#!/usr/bin/env python3
"""Generates Resources/Icon-60@2x.png (120x120): glossy blue tile with a play triangle.
Pure standard library, no Pillow needed."""
import struct, sys, zlib

N = 120
SS = 3  # supersampling per axis


def inside_triangle(px, py, a, b, c):
    def s(p, q, r):
        return (p[0] - r[0]) * (q[1] - r[1]) - (q[0] - r[0]) * (p[1] - r[1])
    d1, d2, d3 = s((px, py), a, b), s((px, py), b, c), s((px, py), c, a)
    neg = d1 < 0 or d2 < 0 or d3 < 0
    pos = d1 > 0 or d2 > 0 or d3 > 0
    return not (neg and pos)


def sample(x, y):
    t = y / N
    r, g, b = 0.30 - 0.18 * t, 0.50 - 0.22 * t, 0.80 - 0.25 * t  # blue gradient
    if y < N * 0.48:  # gloss highlight
        k = 0.22 * (1 - y / (N * 0.48))
        r, g, b = r + (1 - r) * k, g + (1 - g) * k, b + (1 - b) * k
    tri = ((44, 32), (44, 88), (92, 60))
    if inside_triangle(x, y, *tri):
        return 1.0, 1.0, 1.0
    shadow = tuple((px, py + 3) for px, py in tri)
    if inside_triangle(x, y, *shadow):
        return r * 0.55, g * 0.55, b * 0.6
    return r, g, b


rows = []
for j in range(N):
    row = bytearray([0])
    for i in range(N):
        acc = [0.0, 0.0, 0.0]
        for sy in range(SS):
            for sx in range(SS):
                c = sample(i + (sx + 0.5) / SS, j + (sy + 0.5) / SS)
                for k in range(3):
                    acc[k] += c[k]
        row += bytes(int(255 * v / (SS * SS)) for v in acc)
    rows.append(bytes(row))


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(b"".join(rows), 9))
png += chunk(b"IEND", b"")

out = sys.argv[1] if len(sys.argv) > 1 else "Resources/Icon-60@2x.png"
open(out, "wb").write(png)
print("wrote", out)
