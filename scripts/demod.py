#!/usr/bin/env python3

from scipy.io import wavfile
import numpy as np
import scipy.signal

# import matplotlib.pyplot as plt
# import pylab
from utils import write_px, filt
from PIL import Image
import sys
import os

if len(sys.argv) != 3:
    print("Usage: ./demod.py <audio file.wav> <image output folder>")
    exit(1)

img_filename = os.path.splitext(os.path.basename(sys.argv[1]))[0]

''' constants '''
PORCH_TIME = 0.00208
SYNC_TIME = 0.02
LINE_COMP_TIME = 0.1216

# Carrier detection on header frequency
# written as a raw value from the conversion.
# The threshold helps detection on noisy signal.
freq = 2270
threshold = 100

# How many samples do we need to take care of
# to detect the header.
items = 700

# PD120 transmission duration expressed as
# a raw value from the wav file conversion.
pass_len = 1425000

# How many samples do we need to wait until a
# new pass.
wait_time = pass_len

# If the same audio file has more than one
# transmission, then store the header index
# here.
header_end = []
idx = 0

fs, data = wavfile.read(sys.argv[1])

img = Image.new('YCbCr', (640, 496), "white")

def create_hilbert(atten, delta):
    if atten < 21:
        beta = 0
    elif atten > 21 and atten < 50:
        beta = 0.5842*(atten-21)**(2/5) + 0.07886*(atten-21)
    else:
        beta = 0.1102*(atten-8.7)
    m = 2*((atten-8)/(4.57*delta))
    if int(m) % 2 == 0:
        m = int(m+1)
    else:
        m = int(m+2)
    window = np.kaiser(m, beta)
    filter = []
    for n in range((-m+1)//2, (m-1)//2+1):
        if n % 2 != 0:
            filter.append(2/(np.pi*n))
        else:
            filter.append(0)
    hilbert = filter * window
    return hilbert


def create_analytica(datos, filtro):
    zeros = np.zeros((len(filtro)-1)//2)
    realdata = np.concatenate([zeros, datos, zeros])
    complexdata = np.convolve(datos, filtro)*1j
    return realdata + complexdata

def boundary(val):
    value = min(val, 2300)
    value = max(1500, val)
    return value

def hpf(data, fs):
    firw = scipy.signal.firwin(101, cutoff=800, fs=fs, pass_zero=False)
    return scipy.signal.lfilter(firw, [1.0], data)

def decode(start, samples_list):
    samples = 0
    cont_line = -1
    i = 0
    while i < len(samples_list):
        if 900 <= samples_list[i] <= 1300:
            samples += 1
        if samples > int((SYNC_TIME-0.002)*fs):
            cont_line += 2
            samples = 0
            i = i-int((SYNC_TIME-0.002)*fs)+int((SYNC_TIME+PORCH_TIME)*fs)
            gap = 1200 - np.mean(samples_list[i-int((SYNC_TIME+PORCH_TIME)*fs): i-int(PORCH_TIME*fs)])

            try:
                y_resampled = scipy.signal.resample(samples_list[i:i+int(LINE_COMP_TIME*fs)], 640)
                for col, val in enumerate(y_resampled):
                    write_px(img, col, cont_line,"lum", boundary(val+gap))

                cr_resampled = scipy.signal.resample(samples_list[i+int(LINE_COMP_TIME*fs):i+int(LINE_COMP_TIME*2*fs)], 640)
                for col, val in enumerate(cr_resampled):
                    write_px(img, col, cont_line,"cr", boundary(val+gap))

                cb_resampled = scipy.signal.resample(samples_list[i+int(LINE_COMP_TIME*2*fs):i+int(LINE_COMP_TIME*3*fs)], 640)
                for col, val in enumerate(cb_resampled):
                    write_px(img, col, cont_line,"cb", boundary(val+gap))

                ny_resampled = scipy.signal.resample(samples_list[i+int(LINE_COMP_TIME*3*fs):i+int(LINE_COMP_TIME*4*fs)], 640)
                for col, val in enumerate(ny_resampled):
                    write_px(img, col, cont_line,"nxt_lum", boundary(val+gap))
            except:
                break
            i += int(LINE_COMP_TIME*2*fs)
        i += 1
    imgrgb = img.convert("RGB")
    imgrgb.save("%s/%s-%s.png" % (sys.argv[2], img_filename, start), "PNG")

signal = create_analytica(hpf(data, fs), create_hilbert(40, np.pi/1200))

# xunwrap converts ramp-phase to linear
inst_ph = np.unwrap(np.angle(signal))

inst_fr = (np.diff(inst_ph) / (2.0*np.pi) * fs)
inst_fr = list(filt(inst_fr, 0.2, 0.2, 40))

while idx < len(inst_fr):
    if all((freq - threshold)<x<(freq + threshold) for x in inst_fr[idx:idx+items:1]):
        header_end.append(idx)
        print("found carrier at sample %s" % idx)
        idx += wait_time
    else:
        idx += 1

# fig = plt.figure()
# ax0 = plt.subplot(211)
# ax0.plot(range(len(inst_fr)), inst_fr)
# #ax1 = plt.subplot(212)
# #ax1.plot(t[i+5600*3+1:i+5400*4+1],inst_fr[i+5600*3:i+5400*4])
# pylab.show()


for (idx,padding) in enumerate(header_end):
    print("start: %s \t end: %s" % (padding, padding+pass_len))
    decode(idx,inst_fr[padding:padding+pass_len])
