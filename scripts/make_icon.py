"""Draws the 1024x1024 app icon: #03045E background, one #00B4D8 glyph (ring with a slash = "silenced").
Pure standard library (zlib + struct), no PIL needed. Opaque RGB PNG (App Store rejects alpha).
Usage: python scripts/make_icon.py
"""
import math
import struct
import zlib
from pathlib import Path

SIZE = 1024
NAVY = (0x03, 0x04, 0x5E)
CYAN = (0x00, 0xB4, 0xD8)
C = SIZE / 2
RING_R = 264      # centre line of the ring
HALF = 36         # half of the stroke width
# slash from top-left to bottom-right, ends sit inside the ring stroke
A = (C - 187, C - 187)
B = (C + 187, C + 187)


def dist_segment(px, py):
    ax, ay = A
    bx, by = B
    abx, aby = bx - ax, by - ay
    t = ((px - ax) * abx + (py - ay) * aby) / (abx * abx + aby * aby)
    t = max(0.0, min(1.0, t))
    return math.hypot(px - (ax + t * abx), py - (ay + t * aby))


def coverage(px, py):
    d_ring = abs(math.hypot(px - C, py - C) - RING_R) - HALF
    d_seg = dist_segment(px, py) - HALF
    d = min(d_ring, d_seg)
    return max(0.0, min(1.0, 0.5 - d))   # 1px anti-aliased edge


def main():
    rows = []
    for y in range(SIZE):
        row = bytearray([0])  # PNG filter type 0
        for x in range(SIZE):
            a = coverage(x + 0.5, y + 0.5)
            row += bytes(round(NAVY[i] + (CYAN[i] - NAVY[i]) * a) for i in range(3))
        rows.append(bytes(row))
    raw = b"".join(rows)

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    out = Path(__file__).resolve().parent.parent / "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    out.write_bytes(png)
    print("yazildi:", out, len(png), "bayt")


if __name__ == "__main__":
    main()
