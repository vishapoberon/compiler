import argparse
import json
import os
from pathlib import Path
import random
import re
import shlex
import statistics
import subprocess
import time


root = Path(__file__).resolve().parents[4]
parser = argparse.ArgumentParser(description='Compare VOC array loops on one CPU thread, CPU OpenMP, and an actual GPU.')
parser.add_argument('--voc', default=str(root / 'install/bin/voc'))
parser.add_argument('--vocroot', default=str(root / 'install'))
parser.add_argument('--work', type=Path, default=root / 'build/benchmarks/arrays')
parser.add_argument('--model', choices=('2', 'C'), default='2')
parser.add_argument('--cpu-cc', default='gcc')
parser.add_argument('--gpu-cc', default='clang')
parser.add_argument('--cpu-cflags', default='-O3 -march=native -fno-strict-aliasing -ffp-contract=off')
parser.add_argument('--gpu-cflags', default='-O3 -fno-strict-aliasing -ffp-contract=off')
parser.add_argument('--threads', nargs='+', type=int, default=(4, 16))
parser.add_argument('--cpu-only', action='store_true')
parser.add_argument('--gpu-only', action='store_true')
parser.add_argument('--quick', action='store_true')
parser.add_argument('--label', default='')
args = parser.parse_args()
if any(number < 1 for number in args.threads) or args.cpu_only and args.gpu_only:
    parser.error('choose positive thread counts and at most one of --cpu-only/--gpu-only')
image = Path(args.vocroot).resolve()
voc = str(Path(args.voc).resolve())
work = args.work.resolve()
work.mkdir(parents=True, exist_ok=True)
base = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / 'lib'),
            OBERON=str(image / args.model / 'sym'), LDFLAGS='', LDLIBS='',
            LD_LIBRARY_PATH=str(image / 'lib') + os.pathsep + os.environ.get('LD_LIBRARY_PATH', ''))
for name in ('OMP_NUM_THREADS', 'OMP_THREAD_LIMIT', 'OMP_TEAMS_THREAD_LIMIT', 'OMP_DYNAMIC',
             'OMP_PLACES', 'OMP_PROC_BIND', 'OMP_WAIT_POLICY', 'GOMP_DEBUG', 'LIBOMPTARGET_INFO', 'LIBOMPTARGET_DEBUG'):
    base.pop(name, None)
gpu_flags = os.environ.get('VOC_OPENMP_CFLAGS', '')
gpu_link = os.environ.get('VOC_OPENMP_LDFLAGS', gpu_flags)


def run(command, folder, env, log):
    try:
        result = subprocess.run(list(map(str, command)), cwd=folder, env=env, text=True,
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


if not args.cpu_only:
    if not gpu_flags:
        parser.error('set VOC_OPENMP_CFLAGS and VOC_OPENMP_LDFLAGS for the GPU')
    env = dict(base, OMP_TARGET_OFFLOAD='MANDATORY')
    run([*shlex.split(args.gpu_cc), *shlex.split(args.gpu_cflags), *shlex.split(gpu_flags),
         root / 'src/test/oberonv/DeviceProbe.c', *shlex.split(gpu_link), '-o', work / 'DeviceProbe'],
        work, env, work / 'probe-build.log')
    run([work / 'DeviceProbe'], work, env, work / 'probe-run.log')
    print('actual GPU execution verified; transfers included', flush=True)

driver = '''MODULE ArrayTiming;
IMPORT ArrayKernel, Out, Platform;
VAR repeats, pass, sample: LONGINT; start, elapsed: LONGREAL;
PROCEDURE Now(): LONGREAL;
VAR sec, usec: LONGINT;
BEGIN Platform.GetTimeOfDay(sec, usec); RETURN sec * 1.0D6 + usec END Now;
BEGIN
  ArrayKernel.Initialize;
  start := Now(); ArrayKernel.Apply; elapsed := Now() - start;
  Out.String("cold_us "); Out.LongReal(elapsed, 0); Out.Ln; Out.Flush;
  repeats := 1;
  LOOP
    start := Now();
    FOR pass := 1 TO repeats DO ArrayKernel.Apply END;
    elapsed := Now() - start;
    IF (elapsed >= 150000) OR (repeats >= 4096) THEN EXIT END;
    repeats := repeats * 2
  END;
  FOR sample := 1 TO 5 DO
    start := Now();
    FOR pass := 1 TO repeats DO ArrayKernel.Apply END;
    elapsed := Now() - start;
    Out.String("sample_us "); Out.LongReal(elapsed / repeats, 0); Out.Ln; Out.Flush
  END;
  ArrayKernel.Check;
  Out.String("verified "); Out.Int(repeats, 0); Out.Ln
END ArrayTiming.
'''
sizes = [('small', 640 * 480 * 3)] if args.quick else [('1080p', 1920 * 1080 * 3), ('4K', 3840 * 2160 * 3)]
records = []
rng = random.Random(42)
for workload in ('affine', 'arithmetic16'):
    body = 'a[r] := b[r] * factor + bias'
    locals_decl = ''
    expected = 'b[i] * 0.5 + 0.25'
    if workload == 'arithmetic16':
        locals_decl = ' WITH t: REAL'
        body = 't := b[r]; ' + '; '.join(['t := t * factor + bias'] * 16) + '; a[r] := t'
        expected = 'b[i] / 65536 + (0.5 - 0.5 / 65536)'
    for size, count in sizes:
        modes = [] if args.gpu_only else [('sequential', '', 1), *[('cpu' + str(number), 'P', number) for number in args.threads]]
        if not args.cpu_only:
            modes.append(('gpu', 'G', 0))
        rng.shuffle(modes)
        for mode, option, threads in modes:
            folder = work / (workload + '-' + size + '-' + mode)
            folder.mkdir(exist_ok=True)
            (folder / 'ArrayKernel.Mod').write_text(f'''MODULE ArrayKernel;
CONST n = {count};
VAR a, b: ARRAY n OF REAL; factor, bias: REAL;
PROCEDURE Initialize*;
VAR i: LONGINT;
BEGIN
  factor := 0.5; bias := 0.25;
  FOR i := 0 TO n-1 DO a[i] := 0; b[i] := i MOD 256 END
END Initialize;
PROCEDURE Apply*;
BEGIN ALL r = 0 .. n-1{locals_decl} DO {body} END END Apply;
PROCEDURE Check*;
VAR i: LONGINT;
BEGIN
  FOR i := 0 TO n-1 DO ASSERT(a[i] = {expected}); ASSERT(b[i] = i MOD 256) END
END Check;
END ArrayKernel.
''')
            (folder / 'ArrayTiming.Mod').write_text(driver)
            gpu = mode == 'gpu'
            cc = args.gpu_cc if gpu else args.cpu_cc
            cflags = args.gpu_cflags if gpu else args.cpu_cflags
            flags = gpu_flags if gpu else '-fopenmp'
            link = gpu_link if gpu else flags
            env = dict(base, CC=cc, CFLAGS=cflags, VOC_OPENMP_CFLAGS=flags, VOC_OPENMP_LDFLAGS=link,
                       OMP_TARGET_OFFLOAD='MANDATORY' if gpu else 'DISABLED')
            if not gpu:
                env.update(OMP_NUM_THREADS=str(threads), OMP_THREAD_LIMIT=str(threads), OMP_DYNAMIC='FALSE',
                           OMP_PLACES='cores', OMP_PROC_BIND='TRUE', OMP_WAIT_POLICY='PASSIVE')
            print('running', workload, size, mode, flush=True)
            run([voc, '-O' + args.model, '-sFjSc' + option, 'ArrayKernel.Mod'], folder, env, folder / 'kernel-translate.log')
            run([*shlex.split(cc), *shlex.split(cflags), *(shlex.split(flags) if option else []),
                 '-I' + str(image / args.model / 'include'), '-c', folder / 'ArrayKernel.c', '-o', folder / 'ArrayKernel.o'],
                folder, env, folder / 'kernel-build.log')
            run([voc, '-O' + args.model, '-sFjm' + option, 'ArrayTiming.Mod'], folder, env, folder / 'driver-build.log')
            output = run([folder / 'ArrayTiming'], folder, env, folder / 'run.log')
            samples = [float(value.replace('D', 'E')) for value in re.findall(r'sample_us\s+(\S+)', output)]
            if 'verified ' not in output or len(samples) != 5 or min(samples) <= 0:
                raise RuntimeError(output)
            record = dict(workload=workload, size=size, channels=count, mode=mode, threads=None if gpu else threads,
                          compiler=cc, cflags=cflags, openmp_flags=flags, label=args.label,
                          median_us=statistics.median(samples), samples_us=samples,
                          cold_us=float(re.search(r'cold_us\s+(\S+)', output).group(1).replace('D', 'E')),
                          repeats=int(re.search(r'verified\s+(\d+)', output).group(1)))
            records.append(record)
            (work / 'results.json').write_text(json.dumps(records, indent=2))
            print(json.dumps(record), flush=True)
print('results:', work / 'results.json')
