import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess


parser = argparse.ArgumentParser(description='Check GCC auto-vectorization of generated CPU loops.')
parser.add_argument('--voc', required=True)
parser.add_argument('--vocroot', required=True)
parser.add_argument('--work', required=True, type=Path)
parser.add_argument('--model', choices=('2', 'C'), default='2')
parser.add_argument('--cc', default='gcc')
parser.add_argument('--mode', choices=('sequential', 'cpu'), default='cpu')
args = parser.parse_args()
voc = str(Path(args.voc).resolve())
image = Path(args.vocroot).resolve()
work = args.work.resolve()
work.mkdir(parents=True, exist_ok=True)
sources = Path(__file__).resolve().parent
report = work / 'vectorization.txt'
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / 'lib'),
           OBERON=str(image / args.model / 'sym'), CC=args.cc, LC_ALL='C',
           CFLAGS='-O3 -march=native -fno-strict-aliasing -ffp-contract=off -fno-lto '
                  '-fopt-info-vec-optimized=' + shlex.quote(str(report)),
           VOC_OPENMP_CFLAGS='-fopenmp', VOC_OPENMP_LDFLAGS='-fopenmp')
report.write_text('')
result = subprocess.run([voc, '-O' + args.model, '-sFSj' + ('P' if args.mode == 'cpu' else ''), sources / 'CPUVectorize.Mod'],
                        cwd=work, env=env, text=True, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, timeout=120)
assert result.returncode == 0, result.stdout
result = subprocess.run([*shlex.split(args.cc), *shlex.split(env['CFLAGS']),
                         *(['-fopenmp'] if args.mode == 'cpu' else []),
                         '-I' + str(image / args.model / 'include'), '-c', 'CPUVectorize.c', '-o', 'CPUVectorize.o'],
                        cwd=work, env=env, text=True, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, timeout=120)
assert result.returncode == 0, result.stdout
generated = (work / 'CPUVectorize.c').read_text()
assert ('#pragma omp parallel for' in generated) == (args.mode == 'cpu')
assert ('reduction(+' in generated) == (args.mode == 'cpu')
optimized = {int(line) for line in re.findall(r'CPUVectorize\.c:(\d+):\d+: optimized: loop vectorized',
                                             report.read_text())}


def function_lines(pattern):
    match = re.search(pattern, generated)
    assert match, pattern
    start = generated.index('{', match.start())
    depth = 0
    for end in range(start, len(generated)):
        if generated[end] == '{':
            depth += 1
        elif generated[end] == '}':
            depth -= 1
            if depth == 0:
                return generated.count('\n', 0, start) + 1, generated.count('\n', 0, end) + 1
    raise AssertionError('unterminated generated function')


for name, pattern in (
    ('grid', r'\nvoid CPUVectorize_Grid \([^\n]*\)\n\{'),
    ('16-stage grid', r'\nvoid CPUVectorize_Grid16 \([^\n]*\)\n\{'),
    ('integer sum', r'\nstatic INT64 __all\d+__reduce\([^\n]*\)\n\{'),
):
    first, last = function_lines(pattern)
    assert any(first <= line <= last for line in optimized), (name, report.read_text())
    print('GCC auto-vectorizes the ' + args.mode + ' ' + name + ' kernel', flush=True)
assert not re.search(r'#pragma\s+omp[^\n]*\bsimd\b', generated)
print('vectorization report:', report)
