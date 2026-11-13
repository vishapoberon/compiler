import argparse
import hashlib
import json
import os
from pathlib import Path
import random
import re
import shlex
import statistics
import subprocess


root = Path(__file__).resolve().parents[4]
parser = argparse.ArgumentParser(description='Measure HALD conversion, excluding file I/O and including GPU transfers.')
parser.add_argument('--build', required=True, type=Path)
parser.add_argument('--image', required=True, type=Path)
parser.add_argument('--lut', required=True, type=Path)
parser.add_argument('--work', type=Path)
parser.add_argument('--modes', nargs='+', choices=('sequential', 'cpu', 'cpu-kernel', 'gpu'), default=('sequential', 'cpu', 'cpu-kernel', 'gpu'))
parser.add_argument('--threads', nargs='+', type=int, default=(1, 4, 16))
parser.add_argument('--sizes', nargs='+', choices=('native', '1080p', '4K'), default=('native', '1080p', '4K'))
parser.add_argument('--gpu-cc', default='clang')
parser.add_argument('--gpu-cflags', default='-O3 -fno-strict-aliasing')
args = parser.parse_args()
if any(number < 1 for number in args.threads):
    parser.error('thread counts must be positive')
try:
    from PIL import Image
except ImportError:
    parser.error('the image benchmark requires Pillow; on Debian install python3-pil')
build = args.build.resolve()
work = (args.work or build / 'benchmark').resolve()
work.mkdir(parents=True, exist_ok=True)
base = dict(os.environ)
for name in ('OMP_NUM_THREADS', 'OMP_THREAD_LIMIT', 'OMP_TEAMS_THREAD_LIMIT', 'OMP_DYNAMIC',
             'OMP_PLACES', 'OMP_PROC_BIND', 'OMP_WAIT_POLICY', 'GOMP_DEBUG', 'LIBOMPTARGET_INFO', 'LIBOMPTARGET_DEBUG'):
    base.pop(name, None)


def run(command, env, log):
    try:
        result = subprocess.run(list(map(str, command)), env=env, cwd=work, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ''
        if isinstance(output, bytes):
            output = output.decode(errors='replace')
        log.write_text(output)
        raise RuntimeError('timed out: ' + shlex.join(map(str, command)) + '\n' + output) from None
    log.write_text(result.stdout)
    if result.returncode:
        raise RuntimeError(shlex.join(map(str, command)) + '\n' + result.stdout)
    return result.stdout


if 'gpu' in args.modes:
    flags = os.environ.get('VOC_OPENMP_CFLAGS', '')
    if not flags:
        parser.error('set VOC_OPENMP_CFLAGS and VOC_OPENMP_LDFLAGS for the GPU')
    env = dict(base, OMP_TARGET_OFFLOAD='MANDATORY')
    run([*shlex.split(args.gpu_cc), *shlex.split(args.gpu_cflags), *shlex.split(flags),
         root / 'src/test/oberonv/DeviceProbe.c', *shlex.split(os.environ.get('VOC_OPENMP_LDFLAGS', flags)),
         '-o', work / 'DeviceProbe'], env, work / 'probe-build.log')
    run([work / 'DeviceProbe'], env, work / 'probe-run.log')
    print('actual GPU execution verified; CPU fallback disabled', flush=True)
with Image.open(args.image) as image:
    original = image.convert('RGBA')
with Image.open(args.lut) as image:
    lut = image.convert('RGBA').tobytes()
count = len(lut) // 4
cube = 2
while cube ** 3 < count:
    cube += 1
if cube ** 3 != count:
    parser.error('LUT pixel count must be a colour cube of range 2 or larger')
lut_path = work / 'lut.rgba'
lut_path.write_bytes(lut)
records = []
rng = random.Random(1010)
for size in args.sizes:
    pixels = original if size == 'native' else original.resize((1920, 1080) if size == '1080p' else (3840, 2160), Image.Resampling.LANCZOS)
    source = work / (size + '.rgba')
    source.write_bytes(pixels.tobytes())
    reference = work / (size + '-reference.rgba')
    run([build / 'sequential/HaldBench', source, lut_path, str(cube), reference],
        dict(base, OMP_TARGET_OFFLOAD='DISABLED'), work / (size + '-reference.log'))
    expected = hashlib.sha256(reference.read_bytes()).hexdigest()
    modes = [(mode, threads) for mode in args.modes for threads in ((1,) if mode in ('sequential', 'gpu') else args.threads)]
    rng.shuffle(modes)
    for mode, threads in modes:
        output = work / (size + '-output.rgba')
        env = dict(base, OMP_TARGET_OFFLOAD='MANDATORY' if mode == 'gpu' else 'DISABLED')
        if mode != 'gpu':
            env.update(OMP_NUM_THREADS=str(threads), OMP_THREAD_LIMIT=str(threads), OMP_DYNAMIC='FALSE',
                       OMP_PLACES='cores', OMP_PROC_BIND='TRUE', OMP_WAIT_POLICY='PASSIVE')
        label = size + '-' + mode + '-' + str(threads)
        print('running', label, flush=True)
        text = run([build / mode / 'HaldBench', source, lut_path, str(cube), output, 'bench'], env, work / (label + '.log'))
        actual = hashlib.sha256(output.read_bytes()).hexdigest()
        if actual != expected:
            raise RuntimeError(label + ': output differs from the original Oberon implementation')
        samples = [float(value.replace('D', 'E')) for value in re.findall(r'sample_us\s+(\S+)', text)]
        if len(samples) != 5 or min(samples) <= 0:
            raise RuntimeError(text)
        record = dict(size=size, width=pixels.width, height=pixels.height, mode=mode, threads=None if mode == 'gpu' else threads,
                      cube_range=cube, median_us=statistics.median(samples), samples_us=samples,
                      cold_us=float(re.search(r'cold_us\s+(\S+)', text).group(1).replace('D', 'E')),
                      repeats=int(re.search(r'repeats\s+(\d+)', text).group(1)), sha256=actual)
        records.append(record)
        (work / 'results.json').write_text(json.dumps(records, indent=2))
        print(json.dumps(record), flush=True)
print('results:', work / 'results.json')
