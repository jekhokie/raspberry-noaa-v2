import collections
import math
import numpy as np

def mapper(value):
    return int((value-1500)/800*255)

def write_px(img, col, line, channel, val):
    if line >= img.height:
        return
    if channel == "lum":
        prev = img.getpixel((col,line-1))
        datapixel = (mapper(val), prev[1], prev[2])
        img.putpixel((col,line-1), datapixel)
    if channel == "cr":
        prev = img.getpixel((col,line-1))
        nxt_prev = img.getpixel((col,line))
        datapixel = (prev[0], prev[1], mapper(val))
        nxt_datapixel = (nxt_prev[0], nxt_prev[1], mapper(val))
        img.putpixel((col,line-1), datapixel)
        img.putpixel((col,line), nxt_datapixel)
    if channel == "cb":
        prev = img.getpixel((col,line-1))
        nxt_prev = img.getpixel((col,line))
        datapixel = (prev[0], mapper(val), prev[2])
        nxt_datapixel = (nxt_prev[0], mapper(val), nxt_prev[2])
        img.putpixel((col,line-1), datapixel)
        img.putpixel((col,line), nxt_datapixel)
    if channel == "nxt_lum":
        prev = img.getpixel((col,line))
        datapixel = (mapper(val), prev[1], prev[2])
        img.putpixel((col,line), datapixel)


def lowpass(cutout, delta_w, atten):
    beta = 0
    if atten > 50:
        beta = 0.1102 * (atten - 8.7)
    elif atten < 21:
        beta = 0
    else:
        beta = 0.5842 * (atten - 21)**0.4 + 0.07886 * (atten - 21)

    length = math.ceil((atten - 8) / (2.285 * delta_w * math.pi)) + 1
    if length % 2 == 0:
        length += 1

    coeffs = np.kaiser(length, beta)

    for i, n in enumerate(range(
            int(-(length - 1) / 2),
            int((length - 1) / 2)+1)):

        if n == 0:
            coeffs[i] *= cutout
        else:
            coeffs[i] *= math.sin(n * math.pi * cutout) / (n * math.pi)

    return coeffs

def filt(input, cutout, delta_w, atten):
    coeffs = lowpass(cutout, delta_w, atten)
    buf = collections.deque([0] * len(coeffs))

    for s in input:
        buf.popleft()
        buf.append(s)
        sum = 0
        for j in range(len(coeffs)):
            sum += buf[-j - 1] * coeffs[j]

        yield sum
