"""Convert a stroked cubic-bezier polyline into a filled outline SVG path.

Icon Composer renders stroke-only SVG paths as closed shapes, so layers must
use filled outlines. Usage: python3 outline_stroke.py
"""
import math

def cubic(p0, p1, p2, p3, t):
    u = 1 - t
    return (u**3*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t**3*p3[0],
            u**3*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t**3*p3[1])

def sample(segments, steps=120):
    pts = []
    for i, seg in enumerate(segments):
        for k in range(0 if i == 0 else 1, steps + 1):
            pts.append(cubic(*seg, k / steps))
    return pts

def outline(segments, width, cap_steps=24):
    pts = sample(segments)
    r = width / 2
    left, right = [], []
    for i, (x, y) in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        n = math.hypot(dx, dy) or 1
        nx, ny = -dy / n, dx / n
        left.append((x + nx * r, y + ny * r))
        right.append((x - nx * r, y - ny * r))

    def cap(center, start_pt):
        cx, cy = center
        a0 = math.atan2(start_pt[1] - cy, start_pt[0] - cx)
        return [(cx + r * math.cos(a0 - math.pi * k / cap_steps),
                 cy + r * math.sin(a0 - math.pi * k / cap_steps))
                for k in range(1, cap_steps)]

    poly = left + cap(pts[-1], left[-1]) + right[::-1] + cap(pts[0], right[0])
    return 'M ' + ' L '.join(f'{x:.1f} {y:.1f}' for x, y in poly) + ' Z'

# Concept A: S-shaped path.
S_PATH = [
    ((300, 800), (520, 800), (716, 760), (716, 628)),
    ((716, 628), (716, 480), (308, 548), (308, 392)),
    ((308, 392), (308, 280), (432, 236), (540, 236)),
]

if __name__ == '__main__':
    print(outline(S_PATH, 124))
