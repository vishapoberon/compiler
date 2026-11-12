import argparse
import os
from pathlib import Path
import re
import shlex
import shutil
import select
import signal
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--voc', required=True)
parser.add_argument('--vocroot', required=True)
parser.add_argument('--work', required=True)
parser.add_argument('--model', choices=('2', 'C'), default='2')
parser.add_argument('--cc', default=os.environ.get('CC', 'gcc'))
parser.add_argument('--device', action='store_true')
parser.add_argument('--ptx-arch')
parser.add_argument('--hresh')
parser.add_argument('--modules')
parser.add_argument('--timeout', type=int, default=120)
parser.add_argument('--cflags', default=os.environ.get('CFLAGS', '-O2 -fno-strict-aliasing'))
args = parser.parse_args()
if args.timeout <= 0:
    parser.error('--timeout must be positive')
voc = str(Path(args.voc).resolve())
image = Path(args.vocroot).resolve()
work = Path(args.work).resolve()
work.mkdir(parents=True, exist_ok=True)
sources = Path(__file__).resolve().parent
cc = shlex.split(args.cc)
assert cc and shutil.which(cc[0]), args.cc
compile_flags = os.environ.get('VOC_OPENMP_CFLAGS', '')
link_flags = os.environ.get('VOC_OPENMP_LDFLAGS', '')
if not args.device:
    compile_flags = '-fopenmp' + (' -foffload=disable' if 'gcc' in Path(cc[0]).name else '')
    link_flags = compile_flags
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / 'lib'),
           OBERON=str(image / args.model / 'sym'), CC=args.cc,
           CFLAGS=args.cflags, LDFLAGS='', LDLIBS='',
           VOC_OPENMP_CFLAGS=compile_flags, VOC_OPENMP_LDFLAGS=link_flags,
           OMP_TARGET_OFFLOAD='MANDATORY' if args.device else 'DISABLED',
           LD_LIBRARY_PATH=str(image / 'lib') + os.pathsep + os.environ.get('LD_LIBRARY_PATH', ''))
if not args.device:
    env.update(OMP_NUM_THREADS='4', OMP_DYNAMIC='FALSE', OMP_THREAD_LIMIT='4')
else:
    print('device thread settings: ' + ', '.join(name + '=' + env.get(name, '<runtime default>')
          for name in ('OMP_NUM_THREADS', 'OMP_THREAD_LIMIT', 'OMP_TEAMS_THREAD_LIMIT', 'OMP_DYNAMIC')), flush=True)
print('GPU test C flags: ' + args.cflags, flush=True)


def execute(command, extra_env=None):
    try:
        return subprocess.run(list(map(str, command)), cwd=work,
                              env=dict(env, **(extra_env or {})), text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=args.timeout)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ''
        if isinstance(output, bytes):
            output = output.decode(errors='replace')
        raise AssertionError('timed out after ' + str(args.timeout) + ' seconds: ' +
                             shlex.join(map(str, command)) + '\ncaptured output:\n' + output) from None


def run(command, success=True, extra_env=None):
    result = execute(command, extra_env)
    assert (result.returncode == 0) == success, (command, result.stdout)
    return result.stdout


def module(name, declarations, body):
    path = work / (name + '.Mod')
    path.write_text('MODULE ' + name + ';\n' + declarations + '\nBEGIN\n' + body + '\nEND ' + name + '.\n')
    return path


run([*cc, *shlex.split(args.cflags), *shlex.split(compile_flags or '-fopenmp'), sources / 'DeviceProbe.c',
     *shlex.split(link_flags or '-fopenmp'), '-o', work / 'DeviceProbe'])
probe = execute([work / 'DeviceProbe'])
if args.device:
    assert probe.returncode == 0, ('GPU execution was not verified', probe.returncode, probe.stdout)
    print('omp_is_initial_device: actual device execution verified', flush=True)
else:
    assert probe.returncode == 77, (probe.returncode, probe.stdout)
    print('omp_is_initial_device: host fallback confirmed; this run does not verify a GPU', flush=True)

run([*cc, *shlex.split(args.cflags), *shlex.split(compile_flags or '-fopenmp'), sources / 'TeamsProbe.c',
     *shlex.split(link_flags or '-fopenmp'), '-o', work / 'TeamsProbe'])
for bounds in ('constant', 'captured'):
    for mode in ('32', '64'):
        label = 'C teams probe, ' + mode + '-bit loop, ' + bounds + ' bound'
        print(label + ': begin', flush=True)
        probe = execute([work / 'TeamsProbe', mode, *(['captured'] if bounds == 'captured' else [])])
        assert probe.returncode == (0 if args.device else 77), (mode, bounds, probe.returncode, probe.stdout)
        print(label + ': complete', flush=True)

run([*cc, *shlex.split(args.cflags), *shlex.split(compile_flags or '-fopenmp'), sources / 'NumericalProbe.c',
     *shlex.split(link_flags or '-fopenmp'), '-o', work / 'NumericalProbe'])
print('C mapped numerical probe: begin', flush=True)
run([work / 'NumericalProbe'])
print('C mapped numerical probe: complete', flush=True)

print('compiling generated GPU numerical tests', flush=True)
output = run([voc, '-O' + args.model, '-sVjmG', sources / 'TestGPU.Mod'])
assert '-fopenmp' in output
generated = (work / 'TestGPU.c').read_text()
assert '#pragma omp target teams distribute parallel for' in generated
assert ' map(to: ' in generated and ' map(tofrom: ' in generated
assert ' firstprivate(' in generated
print('running generated GPU numerical tests', flush=True)
output = run([work / 'TestGPU'])
print(output, end='', flush=True)
assert 'GPU ALL numerical tests passed' in output
for region in generated.split('#pragma omp target teams distribute parallel for')[1:]:
    start = region.index('{')
    depth = 0
    for end in range(start, len(region)):
        if region[end] == '{':
            depth += 1
        elif region[end] == '}':
            depth -= 1
            if depth == 0:
                break
    assert depth == 0
    body = region[start:end]
    assert not any(name in body for name in ('__HALT', '__X(', '__SHORT', '__CHR',
                                            '__DIV(', '__MOD(', '__ENTIER', '__curr',
                                            'SYSTEM_CheckCommandInterrupt')), body
print('numerical arrays, open arrays, captures, private variables, bounds and integer endpoints passed', flush=True)

if args.ptx_arch:
    ptx = work / ('TestGPU-' + args.ptx_arch + '.ptx')
    run([*cc, *shlex.split(args.cflags), '-fopenmp', '-fopenmp-targets=nvptx64-nvidia-cuda',
         '--offload-arch=' + args.ptx_arch, '--offload-device-only', '-nogpulib', '-nocudainc', '-S',
         '-I' + str(image / args.model / 'include'), work / 'TestGPU.c', '-o', ptx])
    device_code = ptx.read_text()
    assert '.target ' + args.ptx_arch in device_code and '__omp_offloading_' in device_code
    assert not any(name in device_code for name in ('Modules_', 'SYSTEM_', '__curr'))
    print('device-only PTX compilation passed for ' + args.ptx_arch + '; device linking/execution unverified', flush=True)

declarations = ('TYPE Cell = RECORD value: REAL END; Buffer = POINTER TO ARRAY OF REAL;\n'
                'VAR a, b: ARRAY 8 OF LONGINT; values: ARRAY 8 OF REAL; letters: ARRAY 8 OF CHAR;\n'
                'cells: ARRAY 8 OF Cell; matrix: ARRAY 8, 2 OF REAL; p: Buffer;')
invalid = [
    ('Record', 'ALL r = 0 .. 7 DO cells[r].value := 0 END', 168),
    ('Matrix', 'ALL r = 0 .. 7 DO matrix[r, 0] := 0 END', 168),
    ('Heap', 'NEW(p, 8); ALL r = 0 .. 7 DO p[r] := 0 END', 168),
    ('Shift', 'ALL r = 0 .. 6 DO a[r+1] := r END', 170),
    ('Indirect', 'ALL r = 0 .. 7 DO a[r] := b[a[r]] END', 170),
    ('Division', 'ALL r = 0 .. 7 DO a[r] := r DIV 3 END', 171),
    ('Modulo', 'ALL r = 0 .. 7 DO a[r] := r MOD 3 END', 171),
    ('Entier', 'ALL r = 0 .. 7 DO a[r] := ENTIER(values[r]) END', 172),
    ('Character', 'ALL r = 0 .. 7 DO letters[r] := CHR(r) END', 172),
    ('Narrow', 'ALL r = 0 .. 7 WITH t: SHORTINT DO t := SHORT(SHORT(a[r])); a[r] := t END', 172),
    ('ScalarWrite', 'ALL r = 0 .. 0 DO p := NIL END', 168),
]
for name, body, error in invalid:
    path = module('BadGPU' + name, declarations, body)
    flags = '-sSjmG' + ('r' if name in ('Character', 'Narrow') else '')
    output = run([voc, '-O' + args.model, flags, path], success=False)
    assert re.search(r'err\s+' + str(error) + r'\s', output), (name, output)

for name, parameters, body, call, error in (
    ('Alias', 'VAR x, y: ARRAY OF REAL', 'ALL r = 0 .. 7 DO x[r] := y[r] END', 'Process(values, values)', 169),
    ('ScalarRef', 'VAR x: ARRAY OF REAL; VAR amount: REAL',
     'ALL r = 0 .. 7 DO x[r] := x[r] + amount END', 'Process(values, values[0])', 168),
):
    path = module('BadGPU' + name, declarations + '\nPROCEDURE Process(' + parameters + ');\nBEGIN\n' +
                  body + '\nEND Process;', call)
    output = run([voc, '-O' + args.model, '-sSjmG', path], success=False)
    assert re.search(r'err\s+' + str(error) + r'\s', output), (name, output)
print(str(len(invalid) + 2) + ' unsupported GPU cases rejected', flush=True)

for name, bounds in (('Below', '-1 .. 0'), ('Above', '7 .. 8')):
    path = module('GPUBounds' + name, 'VAR a: ARRAY 8 OF REAL;', 'ALL r = ' + bounds + ' DO a[r] := r END')
    run([voc, '-O' + args.model, '-sjmG', path])
    output = run([work / ('GPUBounds' + name)], success=False)
    assert 'Halt(-2)' in output, output
path = module('GPUOpenBound', 'VAR a: ARRAY 4 OF REAL;\n'
              'PROCEDURE Process(VAR x: ARRAY OF REAL);\n'
              'BEGIN ALL r = 0 .. 0 DO x[r] := x[4] END END Process;', 'Process(a)')
run([voc, '-O' + args.model, '-sjmG', path])
assert 'Halt(-2)' in run([work / 'GPUOpenBound'], success=False)
print('invalid fixed/open-array bounds trap on the calling thread', flush=True)

run([voc, '-O' + args.model, '-sSjmG', sources / 'TestGPU.Mod'])
output = run([*cc, '-I' + str(image / args.model / 'include'), '-c', work / 'TestGPU.c'], success=False)
assert 'OpenMP GPU output requires' in output, output
if shutil.which('tcc'):
    output = run([voc, '-O' + args.model, '-sjmG', sources / 'TestGPU.Mod'], success=False,
                 extra_env={'CC': 'tcc', 'VOC_OPENMP_CFLAGS': '', 'VOC_OPENMP_LDFLAGS': ''})
    assert 'No OpenMP options configured for tcc' in output, output
    run([voc, '-O' + args.model, '-sSjmG', sources / 'TestGPU.Mod'], extra_env={'CC': 'tcc'})

if args.hresh or args.modules:
    assert args.hresh and args.modules, '--hresh and --modules must be used together'
    modules = str(Path(args.modules).resolve())
    shared_env = dict(env, VOCLIBDIR=modules, OBERON=modules)
    run([voc, '-O' + args.model, '-sjmGL', sources / 'TestGPU.Mod'], extra_env=shared_env)
    assert 'GPU ALL numerical tests passed' in run([work / 'TestGPU'], extra_env=shared_env)
    run([voc, '-O' + args.model, '-sjlG', sources / 'ParallelCommand.Mod'], extra_env=shared_env)
    process = subprocess.Popen([str(Path(args.hresh).resolve()), '-P' + str(work) + ':' + modules],
                               cwd=work, env=shared_env, text=True,
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    try:
        process.stdin.write('ParallelCommand.Run\n')
        process.stdin.flush()
        output = ''
        deadline = time.monotonic() + 30
        while 'parallel command started' not in output:
            assert process.poll() is None and time.monotonic() < deadline, output
            ready, _, _ = select.select([process.stdout], [], [], 1)
            if ready:
                output += os.read(process.stdout.fileno(), 4096).decode()
        time.sleep(0.05)
        process.send_signal(signal.SIGINT)
        commands = ''.join('ParallelCommand.Check\nsystem.Free ParallelCommand\n' for _ in range(3)) + 'quit\n'
        output += process.communicate(commands, timeout=60)[0]
        assert process.returncode == 0, output
        assert 'hresh: command stopped' in output and 'parallel command finished' not in output, output
        assert output.count('parallel command recovered') == 3, output
    finally:
        if process.poll() is None:
            process.kill()
            process.communicate()
    print('shared GPU-mode execution, caller interruption and module unload/reload passed', flush=True)

print('GPU device tests passed' if args.device else 'GPU code-generation and explicit host-fallback tests passed')
