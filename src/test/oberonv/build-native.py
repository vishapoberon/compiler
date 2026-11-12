import argparse
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys

root = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser()
parser.add_argument('--work', type=Path, default=root / 'build/oberonv-native')
args = parser.parse_args()
if not sys.platform.startswith('linux') or struct.calcsize('P') != 8:
    parser.error('this test builder requires 64-bit Linux')
work = args.work.resolve()
build = work / 'compiler'
image = work / 'image'
build.mkdir(parents=True, exist_ok=True)
for directory in ('bin', 'lib', '2/include', '2/sym'):
    (image / directory).mkdir(parents=True, exist_ok=True)
env = dict(os.environ, CC='gcc', OBERON='.', VOCROOT=str(image), VOCLIBDIR=str(image / 'lib'),
           INSTALLDIR=str(image), LIBDIR=str(image / 'lib'), BINDIR=str(image / 'bin'),
           CFLAGS='', LDFLAGS='', LDLIBS='')
runtime = 'PlatformNative Platform Heap Out Reals Strings Modules Files Texts VT100'.split()
names = ['Configuration', *runtime, *'OPM extTools OPS OPT OPC OPV OPB OPP Compiler'.split()]
for executable in ('gcc', 'ar'):
    if not shutil.which(executable):
        parser.error(executable + ' is required')


def run(command):
    subprocess.run(list(map(str, command)), cwd=build, env=env, check=True)


bootstrap = build / 'bootstrap-voc'
run(['gcc', '-O0', '-g', '-fno-strict-aliasing', '-DVOC_MAIN_PROGRAM=1',
     '-I' + str(root / 'bootstrap/unix-88'), '-I' + str(root / 'bootstrap'),
     root / 'bootstrap/SYSTEM.c', *[root / 'bootstrap/unix-88' / (name + '.c') for name in names],
     '-ldl', '-lm', '-o', bootstrap])
run(['gcc', '-I' + str(root / 'src/runtime'), root / 'src/tools/make/configure.c', '-o', 'configure'])
run([build / 'configure'])
for name in names:
    if name == 'Configuration':
        source = build / 'Configuration.Mod'
    elif name in 'PlatformNative Platform Heap Modules Texts VT100'.split():
        source = root / 'src/runtime' / (name + ('unix' if name in ('PlatformNative', 'Platform') else '') + '.Mod')
    elif name in 'Out Reals Strings Files'.split():
        source = root / 'src/library' / (name + '.Mod')
    else:
        source = root / 'src/compiler' / (name + '.Mod')
    flags = '-SsrF' + ('apx' if name == 'Heap' else '') + ('m' if name == 'Compiler' else '')
    run([bootstrap, flags, '-O2', '-A88', source])
run(['gcc', '-O0', '-g', '-fno-strict-aliasing', '-DVOC_MAIN_PROGRAM=1',
     '-I' + str(build), '-I' + str(root / 'src/runtime'), root / 'src/runtime/SYSTEM.c',
     *[build / (name + '.c') for name in names], '-ldl', '-lm', '-o', image / 'bin/voc'])
for name in runtime:
    shutil.copy2(build / (name + '.h'), image / '2/include')
    shutil.copy2(build / (name + '.sym'), image / '2/sym')
shutil.copy2(root / 'src/runtime/SYSTEM.h', image / '2/include')
shutil.copy2(root / 'src/runtime/Errors.Txt', image / '2/sym')
run(['gcc', '-O0', '-g', '-fPIC', '-fno-strict-aliasing', '-I' + str(build),
     '-I' + str(root / 'src/runtime'), '-c', root / 'src/runtime/SYSTEM.c',
     *[build / (name + '.c') for name in runtime]])
objects = [build / (name + '.o') for name in ['SYSTEM', *runtime]]
run(['ar', 'rcs', image / 'lib/libvoc-O2.a', *objects])
run(['gcc', '-shared', *objects, '-ldl', '-lm', '-o', image / 'lib/libvoc-O2.so'])
print('Built compiler: ' + str(image / 'bin/voc'))
print('Built runtime:  ' + str(image))
