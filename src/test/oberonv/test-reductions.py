import argparse
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys


parser = argparse.ArgumentParser()
parser.add_argument('--voc', required=True)
parser.add_argument('--vocroot', required=True)
parser.add_argument('--work', required=True, type=Path)
parser.add_argument('--model', choices=('2', 'C'), default='2')
parser.add_argument('--mode', choices=('sequential', 'cpu'), default='sequential')
parser.add_argument('--cc')
parser.add_argument('--cflags', default='-O2 -fno-strict-aliasing -ffp-contract=off')
args = parser.parse_args()
voc = str(Path(args.voc).resolve())
image = Path(args.vocroot).resolve()
work = args.work.resolve()
work.mkdir(parents=True, exist_ok=True)
sources = Path(__file__).resolve().parent
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / 'lib'),
           OBERON=str(image / args.model / 'sym'),
           LD_LIBRARY_PATH=str(image / 'lib') + os.pathsep + os.environ.get('LD_LIBRARY_PATH', ''),
           OMP_TARGET_OFFLOAD='DISABLED')
flags = '-fopenmp' if args.mode == 'cpu' else ''
link_flags = flags
option = {'sequential': '', 'cpu': 'P'}[args.mode]


def run(command, success=True, extra=None):
    result = subprocess.run(list(map(str, command)), cwd=work, env=dict(env, **(extra or {})), text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    assert (result.returncode == 0) == success, (command, result.stdout)
    return result.stdout


def source(name, declarations, body):
    path = work / (name + '.Mod')
    path.write_text('MODULE ' + name + ';\n' + declarations + '\nBEGIN\n' + body + '\nEND ' + name + '.\n')
    return path


def translate(path, enabled=True):
    return run([voc, '-O' + args.model, '-sFSmr' + ('j' + option if enabled else ''), path])


translate(sources / 'TestReductions.Mod')
generated = (work / 'TestReductions.c').read_text()
assert '__reduce' in generated
assert ('#pragma omp' in generated) == (args.mode != 'sequential')
if args.mode != 'sequential':
    assert 'reduction(+' in generated and 'reduction(*' in generated
compilers = [args.cc] if args.cc else [cc for cc in ('gcc', 'clang', 'tcc') if shutil.which(cc)]
if args.mode != 'sequential':
    compilers = [cc for cc in compilers if 'tcc' not in cc]
assert compilers
for cc in compilers:
    executable = work / ('TestReductions-' + Path(shlex.split(cc)[0]).name)
    run([*shlex.split(cc), *shlex.split(args.cflags), *shlex.split(flags), '-DVOC_MAIN_PROGRAM=1',
         '-I' + str(image / args.model / 'include'), work / 'TestReductions.c',
         image / 'lib' / ('libvoc-O' + args.model + '.a'),
         *(['-ldl'] if sys.platform.startswith('linux') else []), '-lm', *shlex.split(link_flags), '-o', executable])
    for threads in ((1, 2, 4) if args.mode == 'cpu' else (1,)):
        assert 'SUM and PROD tests passed' in run([executable], extra={
            'OMP_NUM_THREADS': str(threads), 'OMP_THREAD_LIMIT': str(threads), 'OMP_DYNAMIC': 'FALSE'})
    print(cc + ': ' + args.mode + ' reductions passed', flush=True)

    dot = source('ReductionDot',
                 'VAR a: ARRAY 4 OF LONGINT; s: LONGINT;\n'
                 'PROCEDURE Dot(VAR x, y: ARRAY OF LONGINT): LONGINT;\n'
                 'BEGIN RETURN SUM([i = 0 .. LEN(x)-1: x[i] * y[i]]) END Dot;',
                 'a[0] := 1; a[1] := 2; a[2] := 3; a[3] := 4; s := Dot(a, a); ASSERT(s = 30)')
    translate(dot)
    output = work / ('ReductionDot-' + Path(shlex.split(cc)[0]).name)
    run([*shlex.split(cc), *shlex.split(args.cflags), *shlex.split(flags), '-DVOC_MAIN_PROGRAM=1',
         '-I' + str(image / args.model / 'include'), work / 'ReductionDot.c',
         image / 'lib' / ('libvoc-O' + args.model + '.a'),
         *(['-ldl'] if sys.platform.startswith('linux') else []), '-lm', *shlex.split(link_flags), '-o', output])
    run([output], extra={'OMP_NUM_THREADS': '4', 'OMP_THREAD_LIMIT': '4', 'OMP_DYNAMIC': 'FALSE'})

    for bounds in ('-1 .. 0', '3 .. 4'):
        bad = source('ReductionBounds', 'VAR a: ARRAY 4 OF INTEGER; s: INTEGER;',
                     's := SUM([i = ' + bounds + ': a[i]]); ASSERT(s = 0)')
        translate(bad)
        output = work / 'ReductionBounds'
        run([*shlex.split(cc), *shlex.split(args.cflags), *shlex.split(flags), '-DVOC_MAIN_PROGRAM=1',
             '-I' + str(image / args.model / 'include'), work / 'ReductionBounds.c',
             image / 'lib' / ('libvoc-O' + args.model + '.a'),
             *(['-ldl'] if sys.platform.startswith('linux') else []), '-lm', *shlex.split(link_flags), '-o', output])
        assert 'Halt(-2)' in run([output], success=False, extra={
            'OMP_NUM_THREADS': '4', 'OMP_THREAD_LIMIT': '4', 'OMP_DYNAMIC': 'FALSE'})

    if args.mode == 'sequential':
        ordered = source('ReductionRounding', 'VAR a: ARRAY 3 OF REAL; r: REAL;',
                         'a[0] := 16777216; a[1] := 1; a[2] := -16777216; '
                         'r := SUM([i = 0 .. 2: a[i]]); ASSERT(r = 0)')
        translate(ordered)
        output = work / 'ReductionRounding'
        run([*shlex.split(cc), *shlex.split(args.cflags), '-DVOC_MAIN_PROGRAM=1',
             '-I' + str(image / args.model / 'include'), work / 'ReductionRounding.c',
             image / 'lib' / ('libvoc-O' + args.model + '.a'),
             *(['-ldl'] if sys.platform.startswith('linux') else []), '-lm', '-o', output])
        run([output])

declarations = 'VAR a: ARRAY 4 OF INTEGER; s: LONGINT;'
invalid = [
    ('RealBound', 's := SUM([i = 0.0 .. 3: i])', 179),
    ('BooleanBound', 's := PROD([i = FALSE .. TRUE: i])', 179),
    ('TypeBound', 's := SUM([i = INTEGER .. 3: i])', 179),
    ('BooleanValue', 's := SUM([i = 0 .. 3: TRUE])', 174),
    ('SetValue', 's := PROD([i = 0 .. 3: {}])', 174),
    ('ArrayValue', 's := SUM([i = 0 .. 3: a])', 174),
    ('TypeValue', 's := SUM([i = 0 .. 3: INTEGER])', 174),
    ('Multiple', 's := SUM([i, j = 0 .. 3: i])', 173),
    ('MultipleRanges', 's := SUM([i = 0 .. 3, j = 0 .. 3: i])', 173),
    ('Nested', 's := SUM([i = 0 .. 3: PROD([j = 0 .. 3: j])])', 176),
    ('InsideAll', 'ALL k = 0 .. 3 DO a[k] := SUM([i = 0 .. 3: i]) END', 176),
    ('Escaping', 's := SUM([i = 0 .. 3: i]); s := i', 0),
]
for name, body, error in invalid:
    path = source('BadReduction' + name, declarations, body)
    output = run([voc, '-O' + args.model, '-sFSmj' + option, path], success=False)
    assert 'err ' + str(error) + ' ' in output, (name, output)
for place in ('F() .. 3: i', '0 .. F(): i', '0 .. 3: F()'):
    path = source('BadReductionCall', declarations + '\nPROCEDURE F(): INTEGER; BEGIN RETURN 1 END F;',
                  's := SUM([i = ' + place + '])')
    output = run([voc, '-O' + args.model, '-sFSmj' + option, path], success=False)
    assert 'err 177 ' in output, output
compat = source('ReductionNames', 'VAR SUM, PROD: INTEGER;', 'SUM := 3; PROD := 4; ASSERT(SUM + PROD = 7)')
translate(compat, enabled=False)
translate(compat)
shadow = source('ReductionShadow', 'PROCEDURE SUM(x: INTEGER): INTEGER; BEGIN RETURN x+1 END SUM;',
                'ASSERT(SUM(3) = 4)')
translate(shadow)
unavailable = source('ReductionDisabled', declarations, 's := SUM([i = 0 .. 3: i])')
assert 'err 0 ' in run([voc, '-O' + args.model, '-sFSm', unavailable], success=False)
print('reduction types, constructor diagnostics, scope and Oberon-2 compatibility passed', flush=True)

for name, declarations, expression in (
    ('Record', 'TYPE R = RECORD x: LONGINT END; VAR r: R; s: LONGINT;', 'r.x'),
    ('Heap', 'TYPE P = POINTER TO ARRAY OF LONGINT; VAR p: P; s: LONGINT;', 'p[i]'),
    ('Matrix', 'VAR a: ARRAY 4, 4 OF LONGINT; s: LONGINT;', 'a[i, 0]'),
):
    path = source('BadReduction' + name, declarations, 's := SUM([i = 0 .. 3: ' + expression + '])')
    output = run([voc, '-O' + args.model, '-sFSmj' + option, path], success=False)
    assert 'err 175 ' in output, (name, output)
print('unsupported reduction captures rejected', flush=True)

for number, expression in enumerate((
    'SUM()', 'SUM(1)', 'SUM([i = 0 .. 3])', 'SUM([i = 0 .. 3: ])',
    'SUM([i = 0 .. 3: i)', 'SUM([i = 0 .. 3: i], 1)',
    'PROD([i = 0 .. 3: i', 'SUM([= 0 .. 3: 1])', 'SUM([i = 0 .. : i])',
)):
    path = source('MalformedReduction' + str(number), 'VAR s: LONGINT;', 's := ' + expression)
    output = run([voc, '-O' + args.model, '-sFSmj' + option, path], success=False)
    assert 'err ' in output and 'Terminated by Halt' not in output, (expression, output)
print('malformed constructor forms produce compiler diagnostics', flush=True)
