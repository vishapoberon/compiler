import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import random
import re
import shlex
import statistics
import subprocess
import time


root = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description='Measure multidimensional ALL and reductions on the CPU.')
parser.add_argument('--voc', default=str(root / 'install/bin/voc'))
parser.add_argument('--vocroot', default=str(root / 'install'))
parser.add_argument('--work', type=Path, default=root / 'build/benchmarks/cpu-oberonv')
parser.add_argument('--model', choices=('2', 'C'), default='2')
parser.add_argument('--cc', default='gcc')
parser.add_argument('--cflags', default='-O3 -march=native -fno-strict-aliasing -ffp-contract=off -fno-lto')
parser.add_argument('--threads', nargs='+', type=int, default=(1, 2, 4))
parser.add_argument('--samples', type=int, default=5)
parser.add_argument('--batch-ms', type=int, default=150)
parser.add_argument('--workloads', nargs='+', choices=(
    'grid-affine', 'grid-arithmetic16', 'sum-integer', 'sum-real', 'prod-integer', 'prod-real'),
    default=('grid-affine', 'grid-arithmetic16', 'sum-integer', 'sum-real', 'prod-integer', 'prod-real'))
parser.add_argument('--quick', action='store_true')
parser.add_argument('--label', default='')
args = parser.parse_args()
if args.samples < 3 or args.batch_ms < 1 or any(number < 1 for number in args.threads):
    parser.error('choose at least three samples, a positive batch duration and positive thread counts')
if any(flag.startswith('-flto') for flag in shlex.split(args.cflags)):
    parser.error('compile the kernel and timing driver separately without link-time optimization')
image = Path(args.vocroot).resolve()
voc = str(Path(args.voc).resolve())
work = args.work.resolve()
work.mkdir(parents=True, exist_ok=True)
base = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / 'lib'),
            OBERON=str(image / args.model / 'sym'), CC=args.cc, CFLAGS=args.cflags,
            LDFLAGS='', LDLIBS='', VOC_OPENMP_CFLAGS='-fopenmp', VOC_OPENMP_LDFLAGS='-fopenmp',
            OMP_TARGET_OFFLOAD='DISABLED', OMP_DYNAMIC='FALSE', OMP_PLACES='cores',
            OMP_PROC_BIND='TRUE', OMP_WAIT_POLICY='PASSIVE',
            LD_LIBRARY_PATH=str(image / 'lib') + os.pathsep + os.environ.get('LD_LIBRARY_PATH', ''))
for name in ('OMP_NUM_THREADS', 'OMP_THREAD_LIMIT', 'OMP_TEAMS_THREAD_LIMIT', 'OMP_MAX_ACTIVE_LEVELS',
             'GOMP_CPU_AFFINITY', 'KMP_AFFINITY', 'GOMP_DEBUG', 'LIBOMPTARGET_INFO', 'LIBOMPTARGET_DEBUG'):
    base.pop(name, None)


def run(command, folder, env, log):
    result = subprocess.run(list(map(str, command)), cwd=folder, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
    log.write_text(result.stdout)
    if result.returncode:
        raise RuntimeError(shlex.join(map(str, command)) + '\n' + result.stdout)
    return result.stdout


def measure(executable, folder, env):
    maximum_threads = 0
    worker_ticks = 0
    with (folder / 'run.log').open('w') as output:
        process = subprocess.Popen([str(executable)], cwd=folder, env=env, stdout=output, stderr=output)
        try:
            deadline = time.monotonic() + 300
            while process.poll() is None:
                if time.monotonic() > deadline:
                    raise RuntimeError('benchmark timed out: ' + str(executable))
                tasks = Path('/proc') / str(process.pid) / 'task'
                if tasks.exists():
                    try:
                        entries = list(tasks.iterdir())
                        maximum_threads = max(maximum_threads, len(entries))
                        ticks = 0
                        for entry in entries:
                            if entry.name != str(process.pid):
                                fields = (entry / 'stat').read_text().rpartition(')')[2].split()
                                ticks += int(fields[11]) + int(fields[12])
                        worker_ticks = max(worker_ticks, ticks)
                    except (FileNotFoundError, ProcessLookupError):
                        pass
                time.sleep(0.02)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
    text = (folder / 'run.log').read_text()
    if process.returncode:
        raise RuntimeError(str(executable) + '\n' + text)
    return text, maximum_threads, worker_ticks


def kernel(workload, rows, cols, count):
    timing = f'samples* = {args.samples}; batchMicroseconds* = {args.batch_ms * 1000};'
    if workload.startswith('grid-'):
        locals_decl = ''
        body = 'a[row, col] := b[row, col] * factor + bias'
        expected = 'b[row, col] * 0.5 + 0.25'
        if workload == 'grid-arithmetic16':
            locals_decl = ' WITH t: REAL'
            body = 't := b[row, col]; ' + '; '.join(['t := t * factor + bias'] * 16) + '; a[row, col] := t'
            expected = 'b[row, col] / 65536 + (0.5 - 0.5 / 65536)'
        return f'''MODULE CpuKernel;
CONST rows = {rows}; cols = {cols}; {timing}
VAR a, b: ARRAY rows, cols OF REAL; factor, bias: REAL;
PROCEDURE Initialize*;
VAR row, col: LONGINT;
BEGIN
  factor := 0.5; bias := 0.25;
  FOR row := 0 TO rows-1 DO
    FOR col := 0 TO cols-1 DO a[row, col] := 0; b[row, col] := (row*cols+col) MOD 256 END
  END
END Initialize;
PROCEDURE Apply*;
BEGIN
  ALL row = 0 .. rows-1, col = 0 .. cols-1{locals_decl} DO {body} END
END Apply;
PROCEDURE Check*;
VAR row, col: LONGINT;
BEGIN
  FOR row := 0 TO rows-1 DO
    FOR col := 0 TO cols-1 DO
      ASSERT(a[row, col] = {expected}); ASSERT(b[row, col] = (row*cols+col) MOD 256)
    END
  END
END Check;
END CpuKernel.
'''
    operation = 'SUM' if workload.startswith('sum-') else 'PROD'
    typ = 'SYSTEM.INT64' if workload.endswith('-integer') else 'LONGREAL'
    if workload == 'sum-integer':
        value = 'i MOD 17 - 8'
        remainder = count % 17
        expected = str(remainder * (remainder - 17) // 2)
    elif workload == 'sum-real':
        value = '(i MOD 16) / 16.0D0'
        expected = '(n DIV 16) * 7.5D0 + (n MOD 16) * ((n MOD 16) - 1) / 32.0D0'
    elif workload == 'prod-integer':
        value = '1 - (i MOD 3 DIV 2) * 2'
        expected = '1 - ((n DIV 3) MOD 2) * 2'
    else:
        value = '2.0D0 - (i MOD 2) * 1.5D0'
        expected = '1.0D0 + (n MOD 2)'
    return f'''MODULE CpuKernel;
IMPORT SYSTEM;
CONST n = {count}; {timing}
VAR values: ARRAY n OF {typ}; result: {typ};
PROCEDURE Initialize*;
VAR i: LONGINT;
BEGIN FOR i := 0 TO n-1 DO values[i] := {value} END END Initialize;
PROCEDURE Apply*;
BEGIN result := {operation}([i = 0 .. n-1: values[i]]) END Apply;
PROCEDURE Check*;
VAR i: LONGINT;
BEGIN
  ASSERT(result = {expected});
  FOR i := 0 TO n-1 DO ASSERT(values[i] = {value}) END
END Check;
END CpuKernel.
'''


driver = '''MODULE CpuTiming;
IMPORT CpuKernel, Out, Platform;
VAR repeats, pass, sample: LONGINT; start, elapsed: LONGREAL;
PROCEDURE Now(): LONGREAL;
VAR sec, usec: LONGINT;
BEGIN Platform.GetTimeOfDay(sec, usec); RETURN sec * 1.0D6 + usec END Now;
BEGIN
  CpuKernel.Initialize;
  start := Now(); CpuKernel.Apply; elapsed := Now() - start;
  CpuKernel.Check;
  Out.String("cold_us "); Out.LongReal(elapsed, 0); Out.Ln; Out.Flush;
  repeats := 1;
  LOOP
    start := Now();
    FOR pass := 1 TO repeats DO CpuKernel.Apply END;
    elapsed := Now() - start;
    IF (elapsed >= CpuKernel.batchMicroseconds) OR (repeats >= 4096) THEN EXIT END;
    repeats := repeats * 2
  END;
  CpuKernel.Check;
  FOR sample := 1 TO CpuKernel.samples DO
    start := Now();
    FOR pass := 1 TO repeats DO CpuKernel.Apply END;
    elapsed := Now() - start;
    CpuKernel.Check;
    Out.String("sample_us "); Out.LongReal(elapsed / repeats, 0); Out.Ln; Out.Flush
  END;
  Out.String("verified "); Out.Int(repeats, 0); Out.Ln
END CpuTiming.
'''
cpuinfo = Path('/proc/cpuinfo')
names = re.findall(r'^model name\s*:\s*(.+)$', cpuinfo.read_text(), re.M) if cpuinfo.exists() else []
metadata = dict(label=args.label, system=platform.platform(), cpu=names[0] if names else platform.processor(),
                timestamp=time.strftime('%Y-%m-%dT%H:%M:%S%z'),
                cpus=os.cpu_count(), affinity=sorted(os.sched_getaffinity(0)) if hasattr(os, 'sched_getaffinity') else None,
                model=args.model, cc=args.cc, cflags=args.cflags, samples=args.samples, batch_ms=args.batch_ms,
                cpu_quota=Path('/sys/fs/cgroup/cpu.max').read_text().strip() if Path('/sys/fs/cgroup/cpu.max').exists() else None,
                benchmark_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                compiler_sha256=hashlib.sha256(Path(voc).read_bytes()).hexdigest(),
                library_sha256=hashlib.sha256((image / 'lib' / ('libvoc-O' + args.model + '.a')).read_bytes()).hexdigest(),
                compiler_version=subprocess.check_output([*shlex.split(args.cc), '--version'], text=True).splitlines()[0],
                omp_places='cores', omp_proc_bind='TRUE', omp_wait_policy='PASSIVE')
print(json.dumps(metadata), flush=True)
records = []
rng = random.Random(42)
sizes = [('quick', 256, 512, 262144)] if args.quick else [
    ('small', 1024, 1024, 1048576), ('large', 2048, 2048, 8388608)]
for workload in dict.fromkeys(args.workloads):
    for size, rows, cols, count in sizes:
        modes = [('sequential', '', 1), *[('cpu' + str(number), 'P', number) for number in dict.fromkeys(args.threads)]]
        rng.shuffle(modes)
        for mode, option, threads in modes:
            folder = work / (workload + '-' + size + '-' + mode)
            folder.mkdir(exist_ok=True)
            (folder / 'CpuKernel.Mod').write_text(kernel(workload, rows, cols, count))
            (folder / 'CpuTiming.Mod').write_text(driver)
            env = dict(base, OMP_NUM_THREADS=str(threads), OMP_THREAD_LIMIT=str(threads))
            print('running', workload, size, mode, flush=True)
            run([voc, '-O' + args.model, '-sFjc' + option, 'CpuKernel.Mod'], folder, env, folder / 'kernel-build.log')
            generated = (folder / 'CpuKernel.c').read_text()
            if ('#pragma omp' in generated) != bool(option):
                raise RuntimeError('unexpected execution mode in ' + str(folder / 'CpuKernel.c'))
            run([voc, '-O' + args.model, '-sFmj' + option, 'CpuTiming.Mod'], folder, env, folder / 'driver-build.log')
            output, observed_threads, worker_ticks = measure(folder / 'CpuTiming', folder, env)
            samples = [float(value.replace('D', 'E')) for value in re.findall(r'sample_us\s+(\S+)', output)]
            if 'verified ' not in output or len(samples) != args.samples or min(samples) <= 0:
                raise RuntimeError(output)
            if option and threads > 1 and Path('/proc').is_dir() and (observed_threads < threads or worker_ticks == 0):
                raise RuntimeError('active OpenMP workers were not observed: ' + str(folder))
            record = dict(workload=workload, size=size, mode=mode, threads=threads,
                          rows=rows if workload.startswith('grid-') else None,
                          cols=cols if workload.startswith('grid-') else None,
                          elements=rows*cols if workload.startswith('grid-') else count,
                          median_us=statistics.median(samples), samples_us=samples,
                          cold_us=float(re.search(r'cold_us\s+(\S+)', output).group(1).replace('D', 'E')),
                          repeats=int(re.search(r'verified\s+(\d+)', output).group(1)),
                          observed_threads=observed_threads, worker_cpu_ticks=worker_ticks)
            records.append(record)
            (work / 'results.json').write_text(json.dumps(dict(metadata=metadata, records=records), indent=2))
            print(json.dumps(record), flush=True)

print('\nworkload size mode median_ms versus_sequential versus_cpu1')
for record in records:
    same = [item for item in records if (item['workload'], item['size']) == (record['workload'], record['size'])]
    sequential = next(item['median_us'] for item in same if item['mode'] == 'sequential')
    cpu1 = next((item['median_us'] for item in same if item['mode'] == 'cpu1'), None)
    speedup = sequential / record['median_us']
    scaling = str(round(cpu1 / record['median_us'], 3)) + 'x' if cpu1 is not None else '-'
    print(record['workload'], record['size'], record['mode'], round(record['median_us'] / 1000, 6),
          str(round(speedup, 3)) + 'x', scaling)
print('results:', work / 'results.json')
