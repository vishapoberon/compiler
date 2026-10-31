#!/usr/bin/env python3
"""Build the picture ports and replay their preserved fixture/CRC lists."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--voc', default='voc')
parser.add_argument('--build', required=True, type=Path)
parser.add_argument('--build-only', action='store_true')
parser.add_argument('--shared', action='store_true')
args = parser.parse_args()
source = Path(__file__).resolve().parent
root = source.parents[2]
build = args.build.resolve()
build.mkdir(parents=True, exist_ok=True)


def compile(path, main=False):
    flags = ('-smD' if main else '-sFl') if args.shared else ('-sFm' if main else '-sF')
    subprocess.run([args.voc, '-O2', flags, str(path)],
                   cwd=build, check=True)


compile(root / 'src/library/Files.Mod')
for name in ('Zlib', 'ZlibBuffers', 'ZlibInflate', 'ZlibDeflate'):
    compile(root / 'src/ports/s3' / (name + '.Mod'))
compile(source / 'PictureArgs.Mod')
for kind in ('png', 'jpeg', 'gif'):
    package = source / (kind + '-codec')
    adapted = json.loads((package / 'voc-sha256.json').read_text())
    for relative, digest in json.loads((package / 'upstream-sha256.json').read_text()).items():
        path = package / relative
        if path.name == kind.upper() + '0.Mod' or path.suffix in ('.list', '.tgz', '.LICENSE'):
            digest = adapted.get(relative, digest)
            assert hashlib.sha256(path.read_bytes()).hexdigest() == digest, path
    for name in (kind.upper() + '0', kind):
        compile(package / 'src' / (name + '.Mod'))
    command = {'png': 'PngCmd', 'jpeg': 'JpegCmd', 'gif': 'GifCmd'}[kind]
    compile(root / 'src/tools/pictures' / (command + '.Mod'), True)
    if args.build_only:
        continue
    compile(package / 'test' / (kind.upper() + 'Test.Mod'))
    for fixture in (package / 'test').iterdir():
        if fixture.suffix == '.list':
            shutil.copyfile(fixture, build / fixture.name)
        elif fixture.suffix in ('.tgz', '.gz'):
            with tarfile.open(fixture) as archive:
                archive.extractall(build, filter='data')
    name = kind.upper() + 'Check'
    wrapper = build / (name + '.Mod')
    wrapper.write_text(f'MODULE {name}; IMPORT T := {kind.upper()}Test; BEGIN T.Run END {name}.\n')
    compile(wrapper, True)
    result = subprocess.run([str(build / name), kind + 'suite.list'], cwd=build,
                            capture_output=True, text=True, check=True, timeout=120)
    print(result.stdout, end='', flush=True)
    assert '0 failed' in result.stdout and 'FAIL' not in result.stdout
    picture = build / (kind + ' input.ppm')
    picture.write_bytes(b'P6\n2 2\n255\n' + bytes((255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255)))
    encoded = build / (kind + ' output.' + ('jpg' if kind == 'jpeg' else kind))
    decoded = build / (kind + ' decoded.ppm')
    for arguments in (['FromPNM', str(picture), str(encoded)], ['Info', str(encoded)],
                      ['ToPPM', str(encoded), str(decoded)]):
        subprocess.run([str(build / command), *arguments], cwd=build, check=True, timeout=30)
    assert decoded.read_bytes().startswith(b'P6\n2 2\n255\n')
    if kind == 'png':
        assert decoded.read_bytes() == picture.read_bytes()
if not args.build_only:
    compile(source / 'test/PictureMemoryTest.Mod')
    for entry, name in (('Run', 'PictureMemoryCheck'), ('RunFiles', 'PictureFileCheck'),
                        ('RunFixtures', 'PictureMemoryFixtures')):
        wrapper = build / (name + '.Mod')
        wrapper.write_text(f'MODULE {name}; IMPORT PictureMemoryTest; BEGIN PictureMemoryTest.{entry} END {name}.\n')
        compile(wrapper, True)
        if entry == 'RunFixtures':
            continue
        command = [str(build / name)]
        trace = None
        if entry == 'Run' and sys.platform.startswith('linux') and shutil.which('strace'):
            trace = build / 'picture-memory-files.trace'
            command = ['strace', '-f', '-e', 'trace=%file,memfd_create', '-o', str(trace), *command]
        result = subprocess.run(command, cwd=build, capture_output=True,
                                text=True, timeout=120)
        print(result.stdout, end='', flush=True)
        result.check_returncode()
        assert '0 failed' in result.stdout and 'FAIL' not in result.stdout
        if trace:
            text = trace.read_text()
            assert all(marker not in text for marker in ('O_CREAT', 'O_TMPFILE', 'creat(', 'memfd_create(', 'unlink(')), text
            print('Memory picture I/O: no OS files created', flush=True)
    for kind in ('png', 'jpeg', 'gif'):
        result = subprocess.run([str(build / 'PictureMemoryFixtures'), kind, kind+'suite.list'],
                                cwd=build, capture_output=True, text=True, timeout=120)
        print(result.stdout, end='', flush=True)
        result.check_returncode()
        assert '0 failed' in result.stdout and 'FAIL' not in result.stdout
    compile(root / 'src/test/confidence/library/ZlibTest.Mod')
    wrapper = build / 'ZlibCheck.Mod'
    wrapper.write_text('MODULE ZlibCheck; IMPORT ZlibTest; BEGIN ZlibTest.Run END ZlibCheck.\n')
    compile(wrapper, True)
    result = subprocess.run([str(build / 'ZlibCheck')], cwd=build,
                            capture_output=True, text=True, check=True, timeout=120)
    print(result.stdout, end='', flush=True)
    assert '14 checks, 0 failed' in result.stdout
