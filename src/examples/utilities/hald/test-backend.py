import argparse
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys


parser = argparse.ArgumentParser()
parser.add_argument('--build', type=Path, required=True)
parser.add_argument('--backend', type=Path, required=True)
parser.add_argument('--voc', required=True)
parser.add_argument('--vocroot', type=Path, required=True)
parser.add_argument('--model', choices=('2', 'C'), default='2')
parser.add_argument('--cc', required=True)
parser.add_argument('--cflags', default='-O3 -fno-strict-aliasing')
parser.add_argument('--gpu', action='store_true')
args = parser.parse_args()
sys.dont_write_bytecode = True
build = args.build.resolve()
spec = importlib.util.spec_from_file_location('hald_kernel', args.backend.resolve())
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)
original = (build / 'HaldClut.voc.c').read_text()
for mode in ('cpu', 'gpu'):
    transformed = backend.transform(original, mode)
    assert transformed.count(' / 255)') == 21
    if mode == 'gpu':
        assert 'map(from: target[0:source__len])' in transformed
        assert '_OPENMP < 201511' in transformed
    else:
        assert '#pragma omp target' not in transformed
    assert transformed.count('uintptr_t)source') > 0
for changed in (original.replace('#pragma omp parallel for', '#pragma omp parallel for\n#pragma omp parallel for'),
                original.replace('__ASSERT(', 'CHECK_REMOVED(', 1),
                original.replace('target[', 'SYSTEM_unexpected(); target[', 1)):
    try:
        backend.transform(changed, 'gpu')
    except (ValueError, IndexError):
        pass
    else:
        raise AssertionError('unexpected generated C was accepted')
print('HALD backend rejects unexpected generated structure', flush=True)
folder = build / 'contracts'
folder.mkdir(exist_ok=True)
changed_source = folder / 'ChangedHald.Mod'
changed_source.write_bytes(args.backend.with_name('HaldClut.Mod').read_bytes() + b'\n')
result = subprocess.run([sys.executable, str(args.backend.resolve()), '--voc', args.voc,
                         '--vocroot', str(args.vocroot), '--source', str(changed_source), '--work', str(folder)],
                        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
assert result.returncode != 0 and 'HaldClut.Mod has changed' in result.stdout, result.stdout
for suffix in ('.sym', '.h', '.o'):
    shutil.copy2(build / ('HaldClut' + suffix), folder)
image = args.vocroot.resolve()
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=os.environ.get('VOCLIBDIR', str(image / 'lib')),
           OBERON=str(image / args.model / 'sym'), CC=args.cc, CFLAGS=args.cflags)
declarations = 'VAR source: ARRAY 4 OF CHAR; lut, large: ARRAY 32 OF CHAR; target: ARRAY 8 OF CHAR; i, r, g, b: LONGINT;'
for name, call in (('SourceTarget', 'HaldClut.Apply(source, lut, 2, source)'),
                   ('LutTarget', 'HaldClut.Apply(source, lut, 2, lut)'),
                   ('SourceLut', 'HaldClut.Apply(lut, lut, 2, large)')):
    path = folder / ('Alias' + name + '.Mod')
    path.write_text('MODULE Alias' + name + '; IMPORT HaldClut;\n' + declarations + '\nBEGIN ' + call + ' END Alias' + name + '.\n')
    subprocess.run([str(Path(args.voc).resolve()), '-O' + args.model, '-sFmj' + ('G' if args.gpu else 'P'), str(path)],
                   cwd=folder, env=env, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    result = subprocess.run([str(path.with_suffix(''))], cwd=folder, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
    assert result.returncode != 0 and 'Assertion failure' in result.stdout, (name, result.stdout)
body = '''FOR b := 0 TO 1 DO FOR g := 0 TO 1 DO FOR r := 0 TO 1 DO
  i := 4 * (r + 2 * (g + 2 * b)); lut[i] := CHR(r * 255); lut[i+1] := CHR(g * 255); lut[i+2] := CHR(b * 255)
END END END;
source[0] := 5X; source[1] := 81X; source[2] := 0FFX; source[3] := 49X;
FOR i := 0 TO 7 DO target[i] := 0AAX END;
HaldClut.Apply(source, lut, 2, target);
FOR i := 0 TO 3 DO ASSERT(target[i] = source[i]) END;
FOR i := 4 TO 7 DO ASSERT(target[i] = 0AAX) END
'''
path = folder / 'TargetTail.Mod'
path.write_text('MODULE TargetTail; IMPORT HaldClut;\n' + declarations + '\nBEGIN\n' + body + 'END TargetTail.\n')
subprocess.run([str(Path(args.voc).resolve()), '-O' + args.model, '-sFmj' + ('G' if args.gpu else 'P'), str(path)],
               cwd=folder, env=env, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
subprocess.run([str(path.with_suffix(''))], cwd=folder, env=env, check=True, timeout=30)
print('overlapping buffers rejected; unused target tail preserved', flush=True)
