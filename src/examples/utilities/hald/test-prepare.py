import argparse
from pathlib import Path
import random
import struct
import subprocess
import zlib


parser = argparse.ArgumentParser(description='Check Oberon decoding and benchmark resizing.')
parser.add_argument('--build', required=True, type=Path)
args = parser.parse_args()
build = args.build.resolve()
work = build / 'prepare-tests'
work.mkdir(exist_ok=True)
program = build / 'sequential/HaldPrepare'


def chunk(kind, data):
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))


def write_png(path, width, height, pixels, channels=4):
    rows = b''.join(b'\0' + pixels[y*width*channels:(y+1)*width*channels] for y in range(height))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' +
                     chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6 if channels == 4 else 2, 0, 0, 0)) +
                     chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


def run(image, sizes=(), lut=None, directory=None):
    return subprocess.run([str(program), str(image), str(lut or work / 'lut.png'), str(directory or work), *sizes],
                          text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)


def axis(index, source, target):
    position = ((2*index+1)*source-target)*128 // target
    position = max(0, min((source-1)*256, position))
    low, fraction = divmod(position, 256)
    return low, min(low+1, source-1), fraction


def resize(pixels, width, height, target_width, target_height):
    result = bytearray()
    for y in range(target_height):
        low_y, high_y, fy = axis(y, height, target_height)
        for x in range(target_width):
            low_x, high_x, fx = axis(x, width, target_width)
            for channel in range(4):
                values = [pixels[4*(row*width+column)+channel]
                          for row in (low_y, high_y) for column in (low_x, high_x)]
                top = (values[0]*(256-fx)+values[1]*fx+128)//256
                bottom = (values[2]*(256-fx)+values[3]*fx+128)//256
                result.append((top*(256-fy)+bottom*fy+128)//256)
    return bytes(result)


lut = bytes(component for b in (0, 255) for g in (0, 255) for r in (0, 255) for component in (r, g, b, 255))
write_png(work / 'lut.png', 4, 2, lut)
rng = random.Random(256)
targets = ((1, 1), (1, 7), (7, 1), (2, 3), (3, 2), (5, 7), (8, 6))
for width, height in ((1, 1), (1, 5), (5, 1), (2, 2), (3, 4), (8, 6)):
    pixels = rng.randbytes(width*height*4)
    write_png(work / 'source.png', width, height, pixels)
    sizes = ['native', *[str(w)+'x'+str(h) for w, h in targets]]
    result = run(work / 'source.png', sizes)
    assert result.returncode == 0, result.stdout
    assert 'cube 2\n' in result.stdout and 'preparation oberon-bilinear256-v1\n' in result.stdout
    assert (work / 'lut.rgba').read_bytes() == lut
    assert (work / 'native.rgba').read_bytes() == pixels
    for w, h in targets:
        label = str(w)+'x'+str(h)
        assert 'image '+label+' '+str(w)+' '+str(h)+'\n' in result.stdout
        assert (work / (label+'.rgba')).read_bytes() == resize(pixels, width, height, w, h), (width, height, w, h)
print('RGBA decoding, native pixels, bilinear resizing and alpha match the integer reference', flush=True)

corners = bytes((0, 0, 0, 0, 255, 0, 0, 64, 0, 255, 0, 128, 255, 255, 0, 255))
write_png(work / 'corners.png', 2, 2, corners)
result = run(work / 'corners.png', ['1x1', '3x3'])
assert result.returncode == 0, result.stdout
assert (work / '1x1.rgba').read_bytes() == bytes((128, 128, 0, 112))
assert (work / '3x3.rgba').read_bytes()[16:20] == bytes((128, 128, 0, 112))
print('pixel-centre averaging and independent alpha rounding passed', flush=True)

write_png(work / 'solid.png', 1, 1, bytes((17, 101, 233, 73)))
result = run(work / 'solid.png', ['1080p', '4K'])
assert result.returncode == 0, result.stdout
for size, width, height in (('1080p', 1920, 1080), ('4K', 3840, 2160)):
    assert (work / (size+'.rgba')).read_bytes() == bytes((17, 101, 233, 73))*(width*height)
    assert 'image '+size+' '+str(width)+' '+str(height)+'\n' in result.stdout
print('1080p and 4K dimensions and constant channels passed', flush=True)

rgb = bytes((0, 127, 255, 33, 66, 99))
write_png(work / 'rgb.png', 2, 1, rgb, channels=3)
result = run(work / 'rgb.png')
assert result.returncode == 0, result.stdout
assert (work / 'native.rgba').read_bytes() == bytes((0, 127, 255, 255, 33, 66, 99, 255))


def segment(marker, payload):
    return b'\xff' + bytes((marker,)) + struct.pack('>H', len(payload)+2) + payload


jpeg = (b'\xff\xd8' + segment(0xdb, b'\0'+bytes((1,))*64) +
        segment(0xc0, struct.pack('>BHHBBBB', 8, 8, 8, 1, 1, 0x11, 0)) +
        segment(0xc4, b'\0\x01'+bytes(15)+b'\0'+b'\x10\x01'+bytes(15)+b'\0') +
        segment(0xda, bytes((1, 1, 0, 0, 63, 0))) + b'\x3f\xff\xd9')
(work / 'gray.jpg').write_bytes(jpeg)
result = run(work / 'gray.jpg')
assert result.returncode == 0, result.stdout
assert (work / 'native.rgba').read_bytes() == bytes((128, 128, 128, 255))*64
print('RGB PNG and baseline grayscale JPEG decode to opaque RGBA', flush=True)

for size in ('0x1', '1x0', '67108865x1', '8193x8193', '2x3extra', '../escape', 'x2'):
    result = run(work / 'solid.png', [size])
    assert result.returncode != 0, size
write_png(work / 'invalid-lut.png', 1, 1, bytes(4))
result = run(work / 'solid.png', lut=work / 'invalid-lut.png')
assert result.returncode != 0 and 'pixel count must be a colour cube' in result.stdout
(work / 'broken.png').write_bytes(b'\x89')
for image in (work / 'broken.png', work / 'absent.png'):
    assert run(image).returncode != 0, image
result = run(work / 'solid.png', directory=work / 'absent-directory')
assert result.returncode != 0, result.stdout
print('invalid sizes, LUTs, images and output paths rejected', flush=True)
