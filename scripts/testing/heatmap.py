#! /usr/bin/env python

from PIL import Image, ImageDraw, ImageFont
import os, sys, gzip, math, argparse, colorsys, datetime
from collections import defaultdict
from itertools import *

urlretrieve = lambda a, b: None
try:
    import urllib.request
    urlretrieve = urllib.request.urlretrieve
except:
    import urllib
    urlretrieve = urllib.urlretrieve

# todo:
# matplotlib powered --interactive
# arbitrary freq marker spacing
# ppm
# blue-less marker grid
# fast summary thing
# gain normalization
# check pil version for brokenness

vera_url = "https://github.com/keenerd/rtl-sdr-misc/raw/master/heatmap/Vera.ttf"
vera_path = os.path.join(sys.path[0], "Vera.ttf")

tape_height = 25
tape_pt = 10

if not os.path.isfile(vera_path):
    urlretrieve(vera_url, vera_path)

try:
    font = ImageFont.truetype(vera_path, 10)
except:
    print('Please download the Vera.ttf font and place it in the current directory.')
    sys.exit(1)

def build_parser():
    parser = argparse.ArgumentParser(description='Convert rtl_power CSV files into graphics.')
    parser.add_argument('input_path', metavar='INPUT', type=str,
        help='Input CSV file. (may be a .csv.gz)')
    parser.add_argument('output_path', metavar='OUTPUT', type=str,
        help='Output image. (various extensions supported)')
    parser.add_argument('--offset', dest='offset_freq', default=None,
        help='Shift the entire frequency range, for up/down converters.')
    parser.add_argument('--ytick', dest='time_tick', default=None,
        help='Place ticks along the Y axis every N seconds/minutes/hours/days.')
    parser.add_argument('--db', dest='db_limit', nargs=2, default=None,
        help='Minimum and maximum db values.')
    parser.add_argument('--compress', dest='compress', default=0,
        help='Apply a gradual asymptotic time compression.  Values > 1 are the new target height, values < 1 are a scaling factor.')
    slicegroup = parser.add_argument_group('Slicing',
        'Efficiently render a portion of the data. (optional)  Frequencies can take G/M/k suffixes.  Timestamps look like "YYYY-MM-DD HH:MM:SS"  Durations take d/h/m/s suffixes.')
    slicegroup.add_argument('--low', dest='low_freq', default=None,
        help='Minimum frequency for a subrange.')
    slicegroup.add_argument('--high', dest='high_freq', default=None,
        help='Maximum frequency for a subrange.')
    slicegroup.add_argument('--begin', dest='begin_time', default=None,
        help='Timestamp to start at.')
    slicegroup.add_argument('--end', dest='end_time', default=None,
        help='Timestamp to stop at.')
    slicegroup.add_argument('--head', dest='head_time', default=None,
        help='Duration to use, starting at the beginning.')
    slicegroup.add_argument('--tail', dest='tail_time', default=None,
        help='Duration to use, stopping at the end.')
    parser.add_argument('--palette', dest='palette', default='default',
        help='Set Color Palette: default, extended, charolastra, twente')
    return parser

def frange(start, stop, step):
    i = 0
    while (i*step + start <= stop):
        yield i*step + start
        i += 1

def min_filter(row):
    size = 3
    result = []
    for i in range(size):
        here = row[i]
        near = row[0:i] + row[i+1:size]
        if here > min(near):
            result.append(here)
            continue
        result.append(min(near))
    for i in range(size-1, len(row)):
        here = row[i]
        near = row[i-(size-1):i]
        if here > min(near):
            result.append(here)
            continue
        result.append(min(near))
    return result

def floatify(zs):
    # nix errors with -inf, windows errors with -1.#J
    zs2 = []
    previous = 0  # awkward for single-column rows
    for z in zs:
        try:
            z = float(z)
        except ValueError:
            z = previous
        if math.isinf(z):
            z = previous
        if math.isnan(z):
            z = previous
        zs2.append(z)
        previous = z
    return zs2

def freq_parse(s):
    suffix = 1
    if s.lower().endswith('k'):
        suffix = 1e3
    if s.lower().endswith('m'):
        suffix = 1e6
    if s.lower().endswith('g'):
        suffix = 1e9
    if suffix != 1:
        s = s[:-1]
    return float(s) * suffix

def duration_parse(s):
    suffix = 1
    if s.lower().endswith('s'):
        suffix = 1
    if s.lower().endswith('m'):
        suffix = 60
    if s.lower().endswith('h'):
        suffix = 60 * 60
    if s.lower().endswith('d'):
        suffix = 24 * 60 * 60
    if suffix != 1 or s.lower().endswith('s'):
        s = s[:-1]
    return float(s) * suffix

def date_parse(s):
    if '-' not in s:
        return datetime.datetime.fromtimestamp(int(s))
    return datetime.datetime.strptime(s, '%Y-%m-%d %H:%M:%S')

def palette_parse(s):
    palettes = {'default': default_palette,
                'extended': extended_palette,
                'charolastra': charolastra_palette,
                'twente': twente_palette,
               }
    if s not in palettes:
        print('WARNING: %s not a valid palette' % s)
    return palettes.get(s, default_palette)

def gzip_wrap(path):
    "hides silly CRC errors"
    iterator = gzip.open(path, 'rb')
    running = True
    while running:
        try:
            line = next(iterator)
            if type(line) == bytes:
                line = line.decode('utf-8')
            yield line
        except IOError:
            running = False

def time_compression(y, decay):
    return int(round((1/decay)*math.exp(y*decay) - 1/decay))

def reparse(args, label, fn):
    if args.__getattribute__(label) is None:
        return
    args.__setattr__(label, fn(args.__getattribute__(label)))

def prepare_args():
    # hack, http://stackoverflow.com/questions/9025204/
    for i, arg in enumerate(sys.argv):
        if (arg[0] == '-') and arg[1].isdigit():
            sys.argv[i] = ' ' + arg
    parser = build_parser()
    args = parser.parse_args()

    reparse(args, 'low_freq', freq_parse)
    reparse(args, 'high_freq', freq_parse)
    reparse(args, 'offset_freq', freq_parse)
    if args.offset_freq is None:
        args.offset_freq = 0
    reparse(args, 'time_tick', duration_parse)
    reparse(args, 'begin_time', date_parse)
    reparse(args, 'end_time', date_parse)
    reparse(args, 'head_time', duration_parse)
    reparse(args, 'tail_time', duration_parse)
    reparse(args, 'palette', palette_parse)
    reparse(args, 'head_time', lambda s: datetime.timedelta(seconds=s))
    reparse(args, 'tail_time', lambda s: datetime.timedelta(seconds=s))
    args.compress = float(args.compress)

    if args.db_limit:
        a,b = args.db_limit
        args.db_limit = (float(a), float(b))

    if args.begin_time and args.tail_time:
        print("Can't combine --begin and --tail")
        sys.exit(2)
    if args.end_time and args.head_time:
        print("Can't combine --end and --head")
        sys.exit(2)
    if args.head_time and args.tail_time:
        print("Can't combine --head and --tail")
        sys.exit(2)
    return args

def open_raw_data(path):
    raw_data = lambda: open(path)
    if path.endswith('.gz'):
        raw_data = lambda: gzip_wrap(path)
    return raw_data

def slice_columns(columns, low_freq, high_freq):
    start_col = 0
    stop_col  = len(columns)
    if low_freq  is not None and low <= low_freq  <= high:
        start_col = sum(f<low_freq   for f in columns)
    if high_freq is not None and low <= high_freq <= high:
        stop_col  = sum(f<=high_freq for f in columns)
    return start_col, stop_col-1

def summarize_pass(args):
    "pumps a bunch of data back into the args construct"
    freqs = set()
    f_cache = set()
    times = set()
    labels = set()
    min_z = 0
    max_z = -100
    start, stop = None, None

    for line in raw_data():
        line = [s.strip() for s in line.strip().split(',')]
        #line = [line[0], line[1]] + [float(s) for s in line[2:] if s]
        line = [s for s in line if s]

        low  = int(line[2]) + args.offset_freq
        high = int(line[3]) + args.offset_freq
        step = float(line[4])
        t = line[0] + ' ' + line[1]
        if '-' not in line[0]:
            t = line[0]

        if args.low_freq  is not None and high < args.low_freq:
            continue
        if args.high_freq is not None and args.high_freq < low:
            continue
        if args.begin_time is not None and date_parse(t) < args.begin_time:
            continue
        if args.end_time is not None and date_parse(t) > args.end_time:
            break
        times.add(t)
        columns = list(frange(low, high, step))
        start_col, stop_col = slice_columns(columns, args.low_freq, args.high_freq)
        f_key = (columns[start_col], columns[stop_col], step)
        zs = line[6+start_col:6+stop_col+1]
        if not zs:
            continue
        if f_key not in f_cache:
            freq2 = list(frange(*f_key))[:len(zs)]
            freqs.update(freq2)
            #freqs.add(f_key[1])  # high
            #labels.add(f_key[0])  # low
            f_cache.add(f_key)

        if not args.db_limit:
            zs = floatify(zs)
            min_z = min(min_z, min(zs))
            max_z = max(max_z, max(zs))

        if start is None:
            start = date_parse(t)
        stop = date_parse(t)
        if args.head_time is not None and args.end_time is None:
            args.end_time = start + args.head_time

    if not args.db_limit:
        args.db_limit = (min_z, max_z)

    if args.tail_time is not None:
        times = [t for t in times if date_parse(t) >= (stop - args.tail_time)]
        start = date_parse(min(times))

    freqs = list(sorted(list(freqs)))
    times = list(sorted(list(times)))
    labels = list(sorted(list(labels)))

    if len(labels) == 1:
        delta = (max(freqs) - min(freqs)) / (len(freqs) / 500.0)
        delta = round(delta / 10**int(math.log10(delta))) * 10**int(math.log10(delta))
        delta = int(delta)
        lower = int(math.ceil(min(freqs) / delta) * delta)
        labels = list(range(lower, int(max(freqs)), delta))

    height = len(times)
    pix_height = height
    if args.compress:
        if args.compress > height:
            args.compress = 0
            print("Image too short, disabling time compression")
        if 0 < args.compress < 1:
            args.compress *= height
        if args.compress:
            args.compress = -1 / args.compress
            pix_height = time_compression(height, args.compress)

    print("x: %i, y: %i, z: (%f, %f)" % (len(freqs), pix_height, args.db_limit[0], args.db_limit[1]))
    args.freqs = freqs
    args.times = times
    args.labels = labels
    args.pix_height = pix_height
    args.start_stop = (start, stop)
    args.pixel_bandwidth = step

def default_palette():
    return [(i, i, 50) for i in range(256)]

def extended_palette():
    p = [(0,0,50)]
    for i in range(1, 256):
        p.append((i, i-1, 50))
        p.append((i-1, i, 50))
        p.append((i, i, 50))
    return p

def charolastra_palette():
    p = []
    for i in range(1024):
        g = i / 1023.0
        c = colorsys.hsv_to_rgb(0.65-(g-0.08), 1, 0.2+g)
        p.append((int(c[0]*256), int(c[1]*256), int(c[2]*256)))
    return p

def twente_palette():
    p = []
    for i in range(20, 100, 2):
        p.append((0, 0, i))
    for i in range(256):
        g = i / 255.0
        p.append((int(g*255), 0, int(g*155)+100))
    for i in range(256):
        p.append((255, i, 255))
    # intentionally blow out the highs
    for i in range(100):
        p.append((255, 255, 255))
    return p

def rgb_fn(palette, min_z, max_z):
    "palette is a list of tuples, returns a function of z"
    def rgb_inner(z):
        tone = (z - min_z) / (max_z - min_z)
        tone_scaled = int(tone * (len(palette)-1))
        return palette[tone_scaled]
    return rgb_inner

def collate_row(x_size):
    # this is more fragile than the old code
    # sensitive to timestamps that are out of order
    old_t = None
    row = [0.0] * x_size
    for line in raw_data():
        line = [s.strip() for s in line.strip().split(',')]
        #line = [line[0], line[1]] + [float(s) for s in line[2:] if s]
        line = [s for s in line if s]
        t = line[0] + ' ' + line[1]
        if '-' not in line[0]:
            t = line[0]
        if t not in args.times:
            continue  # happens with live files and time cropping
        if old_t is None:
            old_t = t
        low = int(line[2]) + args.offset_freq
        high = int(line[3]) + args.offset_freq
        step = float(line[4])
        columns = list(frange(low, high, step))
        start_col, stop_col = slice_columns(columns, args.low_freq, args.high_freq)
        if args.low_freq and columns[stop_col] < args.low_freq:
            continue
        if args.high_freq and columns[start_col] > args.high_freq:
            continue
        start_freq = columns[start_col]
        if args.low_freq:
            start_freq = max(args.low_freq, start_freq)
        # sometimes fails?  skip or abort?
        x_start = args.freqs.index(start_freq)
        zs = floatify(line[6+start_col:6+stop_col+1])
        if t != old_t:
            yield old_t, row
            row = [0.0] * x_size
        old_t = t
        for i in range(len(zs)):
            x = x_start + i
            if x >= x_size:
                continue
            row[x] = zs[i]
    yield old_t, row

def push_pixels(args):
    "returns PIL img"
    width = len(args.freqs)
    rgb = rgb_fn(args.palette(), args.db_limit[0], args.db_limit[1])
    img = Image.new("RGB", (width, tape_height + args.pix_height + 1))
    pix = img.load()
    x_size = img.size[0]
    average = [0.0] * width
    tally = 0
    old_y = None
    height = len(args.times)
    for t, zs in collate_row(x_size):
        y = args.times.index(t)
        if not args.compress:
            for x in range(len(zs)):
                pix[x,y+tape_height+1] = rgb(zs[x])
            continue
        # ugh
        y = args.pix_height - time_compression(height - y, args.compress)
        if old_y is None:
            old_y = y
        if old_y != y:
            for x in range(len(average)):
                pix[x,old_y+tape_height+1] = rgb(average[x]/tally)
            tally = 0
            average = [0.0] * width
        old_y = y
        for x in range(len(zs)):
            average[x] += zs[x]
        tally += 1
    return img

def closest_index(n, m_list, interpolate=False):
    "assumes sorted m_list, returns two points for interpolate"
    i = len(m_list) // 2
    jump = len(m_list) // 2
    while jump > 1:
        i_down = i - jump
        i_here = i
        i_up =   i + jump
        if i_down < 0:
            i_down = i
        if i_up >= len(m_list):
            i_up = i
        e_down = abs(m_list[i_down] - n)
        e_here = abs(m_list[i_here] - n)
        e_up   = abs(m_list[i_up]   - n)
        e_best = min([e_down, e_here, e_up])
        if e_down == e_best:
            i = i_down
        if e_up == e_best:
            i = i_up
        if e_here == e_best:
            i = i_here
        jump = jump // 2
    if not interpolate:
        return i
    if n < m_list[i] and i > 0:
        return i-1, i
    if n > m_list[i] and i < len(m_list)-1:
        return i, i+1
    return i, i

def word_aa(label, pt, fg_color, bg_color):
    f = ImageFont.truetype(vera_path, pt*3)
    s = f.getsize(label)
    s = (s[0], pt*3 + 3)  # getsize lies, manually compute
    w_img = Image.new("RGB", s, bg_color)
    w_draw = ImageDraw.Draw(w_img)
    w_draw.text((0, 0), label, font=f, fill=fg_color)
    return w_img.resize((s[0]//3, s[1]//3), Image.ANTIALIAS)

def blend(percent, c1, c2):
    "c1 and c2 are RGB tuples"
    # probably isn't gamma correct
    r = c1[0] * percent + c2[0] * (1 - percent)
    g = c1[1] * percent + c2[1] * (1 - percent)
    b = c1[2] * percent + c2[2] * (1 - percent)
    c3 = map(int, map(round, [r,g,b]))
    return tuple(c3)

def tape_lines(draw, freqs, interval, y1, y2, used=set()):
    min_f = min(freqs)
    max_f = max(freqs)
    "returns the number of lines"
    low_f = (min_f // interval) * interval
    high_f = (1 + max_f // interval) * interval
    hits = 0
    blur = lambda p: blend(p, (255, 255, 0), (0, 0, 0))
    for i in range(int(low_f), int(high_f), int(interval)):
        if not (min_f < i < max_f):
            continue
        hits += 1
        if i in used:
            continue
        x1,x2 = closest_index(i, args.freqs, interpolate=True)
        if x1 == x2:
            draw.line([x1,y1,x1,y2], fill='black')
        else:
            percent = (i - args.freqs[x1]) / float(args.freqs[x2] - args.freqs[x1])
            draw.line([x1,y1,x1,y2], fill=blur(percent))
            draw.line([x2,y1,x2,y2], fill=blur(1-percent))
        used.add(i)
    return hits

def tape_text(img, freqs, interval, y, used=set()):
    min_f = min(freqs)
    max_f = max(freqs)
    low_f = (min_f // interval) * interval
    high_f = (1 + max_f // interval) * interval
    for i in range(int(low_f), int(high_f), int(interval)):
        if i in used:
            continue
        if not (min_f < i < max_f):
            continue
        x = closest_index(i, freqs)
        s = str(i)
        if interval >= 1e6:
            s = '%iM' % (i/1e6)
        elif interval > 1000:
            s = '%ik' % ((i/1e3) % 1000)
            if s.startswith('0'):
                s = '%iM' % (i/1e6)
        else:
            s = '%i' % (i%1000)
            if s.startswith('0'):
                s = '%ik' % ((i/1e3) % 1000)
            if s.startswith('0'):
                s = '%iM' % (i/1e6)
        w = word_aa(s, tape_pt, 'black', 'yellow')
        img.paste(w, (x - w.size[0]//2, y))
        used.add(i)

def shadow_text(draw, x, y, s, font, fg_color='white', bg_color='black'):
    draw.text((x+1, y+1), s, font=font, fill=bg_color)
    draw.text((x, y), s, font=font, fill=fg_color)

def create_labels(args, img):
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()
    pixel_bandwidth = args.pixel_bandwidth

    draw.rectangle([0,0,img.size[0],tape_height], fill='yellow')
    min_freq = min(args.freqs)
    max_freq = max(args.freqs)
    delta = max_freq - min_freq
    width = len(args.freqs)
    height = len(args.times)
    label_base = 9

    for i in range(label_base, 0, -1):
        interval = int(10**i)
        low_f = (min_freq // interval) * interval
        high_f = (1 + max_freq // interval) * interval
        hits = len(range(int(low_f), int(high_f), interval))
        if hits >= 4:
            label_base = i
            break
    label_base = 10**label_base

    for scale,y in [(1,10), (5,15), (10,19), (50,22), (100,24), (500, 25)]:
        hits = tape_lines(draw, args.freqs, label_base/scale, y, tape_height)
        pixels_per_hit = width / hits
        if pixels_per_hit > 50:
            tape_text(img, args.freqs, label_base/scale, y-tape_pt)
        if pixels_per_hit < 10:
            break

    start, stop = args.start_stop
    duration = stop - start
    duration = duration.days * 24*60*60 + duration.seconds + 30
    pixel_height = duration / len(args.times)
    hours = int(duration / 3600)
    minutes = int((duration - 3600*hours) / 60)

    if args.time_tick:
        label_format = "%H:%M:%S"
        if args.time_tick % (60*60*24) == 0:
            label_format = "%Y-%m-%d"
        elif args.time_tick % 60 == 0:
            label_format = "%H:%M"
        label_next = datetime.datetime(start.year, start.month, start.day, start.hour)
        tick_delta = datetime.timedelta(seconds = args.time_tick)
        while label_next < start:
            label_next += tick_delta
        last_y = -100
        full_height = args.pix_height
        for y,t in enumerate(args.times):
            label_time = date_parse(t)
            if label_time < label_next:
                continue
            if args.compress:
                y = full_height - time_compression(height - y, args.compress)
            if y - last_y > 15:
                shadow_text(draw, 2, y+tape_height, label_next.strftime(label_format), font)
                last_y = y
            label_next += tick_delta

    margin = 2
    if args.time_tick:
        margin = 60
    shadow_text(draw, margin, img.size[1] - 45, 'Duration: %i:%02i' % (hours, minutes), font)
    shadow_text(draw, margin, img.size[1] - 35, 'Range: %.2fMHz - %.2fMHz' % (min_freq/1e6, (max_freq+pixel_bandwidth)/1e6), font)
    shadow_text(draw, margin, img.size[1] - 25, 'Pixel: %.2fHz x %is' % (pixel_bandwidth, int(round(pixel_height))), font)
    shadow_text(draw, margin,  img.size[1] - 15, 'Started: {0}'.format(start), font)
    # bin size

print("loading")
args = prepare_args()
raw_data = open_raw_data(args.input_path)
summarize_pass(args)

print("drawing")
img = push_pixels(args)

print("labeling")
create_labels(args, img)

print("saving")
img.save(args.output_path)

