import argparse
import os
from pathlib import Path
import random
import struct
import subprocess
import zlib

parser = argparse.ArgumentParser()
parser.add_argument('--build', required=True, type=Path)
args = parser.parse_args()
build = args.build.resolve()
work = build / 'tests'
work.mkdir(exist_ok=True)


def chunk(kind, data):
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))


def write_png(path, width, height, pixels):
    rows = b''.join(b'\0' + bytes(pixels[y*width*4:(y+1)*width*4]) for y in range(height))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' +
                     chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)) +
                     chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


def read_png(path):
    data = path.read_bytes()
    offset = 8
    compressed = bytearray()
    while offset < len(data):
        length = struct.unpack('>I', data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]
        payload = data[offset+8:offset+8+length]
        if kind == b'IHDR':
            width, height, depth, colour, compression, filtering, interlace = struct.unpack('>IIBBBBB', payload)
            assert depth == 8 and colour in (2, 6) and interlace == 0
        elif kind == b'IDAT':
            compressed.extend(payload)
        offset += length + 12
    channels = 4 if colour == 6 else 3
    stride = width * channels
    raw = zlib.decompress(compressed)
    previous = bytearray(stride)
    pixels = bytearray()
    for y in range(height):
        base = y * (stride+1)
        filter_type = raw[base]
        row = bytearray(raw[base+1:base+1+stride])
        for x in range(stride):
            a = row[x-channels] if x >= channels else 0
            b = previous[x]
            c = previous[x-channels] if x >= channels else 0
            if filter_type == 1:
                predictor = a
            elif filter_type == 2:
                predictor = b
            elif filter_type == 3:
                predictor = (a+b)//2
            elif filter_type == 4:
                p = a+b-c
                distances = (abs(p-a), abs(p-b), abs(p-c))
                predictor = (a, b, c)[distances.index(min(distances))]
            else:
                assert filter_type == 0
                predictor = 0
            row[x] = (row[x]+predictor) & 255
        if channels == 4:
            pixels.extend(row)
        else:
            for x in range(0, stride, 3):
                pixels.extend(row[x:x+3] + b'\xff')
        previous = row
    return bytes(pixels)


def reference(source, lut, size):
    target = bytearray()
    for index in range(0, len(source), 4):
        coords = [divmod(value*(size-1), 255) for value in source[index:index+3]]
        lows = [coordinate[0] for coordinate in coords]
        highs = [min(low+1, size-1) for low in lows]
        fractions = [coordinate[1] for coordinate in coords]
        for channel in range(3):
            values = [lut[4*(x+size*(y+size*z))+channel]
                      for z in (lows[2], highs[2])
                      for y in (lows[1], highs[1])
                      for x in (lows[0], highs[0])]
            for fraction in fractions:
                values = [(a*(255-fraction)+b*fraction+127)//255
                          for a, b in zip(values[::2], values[1::2])]
            target.append(values[0])
        target.append(source[index+3])
    return bytes(target)


rng = random.Random(64)
source = bytes([component for value in range(256) for component in (value, 255-value, value//2, value)])
source += bytes([component for b in (0, 255) for g in (0, 255) for r in (0, 255)
                 for component in (r, g, b, 73)])
source += rng.randbytes(4096)
write_png(work / 'source.png', len(source)//4, 1, source)
for size in (2, 3, 4, 16, 64):
    for kind in ('identity', 'invert', 'random'):
        lut = bytearray()
        for z in range(size):
            for y in range(size):
                for x in range(size):
                    values = [(v*255+(size-1)//2)//(size-1) for v in (x, y, z)]
                    if kind == 'invert':
                        values = [255-v for v in values]
                    elif kind == 'random':
                        values = [rng.randrange(256) for _ in range(3)]
                    lut.extend(values + [rng.randrange(256)])
        write_png(work / 'lut.png', size*size, size, lut)
        expected = reference(source, lut, size)
        if size == 2 and kind == 'identity':
            assert expected == source
        for mode, threads in (('sequential', 1), ('cpu', 1), ('cpu', 2), ('cpu', 4)):
            output = work / (mode + '-' + str(threads) + '.png')
            result = subprocess.run([str(build / mode / 'HaldCmd'), str(work / 'source.png'),
                                     str(work / 'lut.png'), str(output)],
                                    env=dict(os.environ, OMP_NUM_THREADS=str(threads), OMP_DYNAMIC='FALSE'),
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
            assert result.returncode == 0, result.stdout
            assert read_png(output) == expected, (size, kind, mode, threads)
        print('range ' + str(size) + ', ' + kind + ': sequential and OpenMP match reference')

for width, height in ((1, 1), (3, 3), (10, 1)):
    write_png(work / 'invalid.png', width, height, bytes(width*height*4))
    result = subprocess.run([str(build / 'sequential/HaldCmd'), str(work / 'source.png'),
                             str(work / 'invalid.png'), '-'],
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
    assert result.returncode != 0 and 'pixel count must be a colour cube' in result.stdout
print('invalid cube sizes rejected')
