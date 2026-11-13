import argparse
import hashlib
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess


SOURCE_SHA256 = '406a6287bccff453abcef4846cd369775e59243f24fa904320044dd2337b3951'


def block_end(text, start):
    if text[start] != '{':
        raise ValueError('expected a C block')
    depth = 0
    for index in range(start, len(text)):
        if text[index] == '{':
            depth += 1
        elif text[index] == '}':
            depth -= 1
            if depth == 0:
                return index + 1
    raise ValueError('unclosed C block')


def divide255(text):
    count = 0
    while '__DIV(' in text:
        start = text.index('__DIV(')
        first = start + len('__DIV(')
        depth = 0
        comma = None
        for index in range(first, len(text)):
            char = text[index]
            if char == '(':
                depth += 1
            elif char == ')':
                if depth == 0:
                    if comma is None or text[comma+1:index].strip() != '255':
                        raise ValueError('expected interpolation division by 255')
                    text = text[:start] + '((' + text[first:comma] + ') / 255)' + text[index+1:]
                    break
                depth -= 1
            elif char == ',' and depth == 0:
                comma = index
        else:
            raise ValueError('unclosed interpolation division')
        count += 1
    if count != 21:
        raise ValueError('expected 21 interpolation divisions, found ' + str(count))
    return text


def disjoint(left, left_size, right, right_size):
    a = '(uintptr_t)' + left
    b = '(uintptr_t)' + right
    return ('(' + a + ' <= ' + b + ' ? ' + b + ' - ' + a + ' >= (uintptr_t)' + left_size +
            ' : ' + a + ' - ' + b + ' >= (uintptr_t)' + right_size + ')')


def transform(text, backend):
    if text.count('#pragma omp parallel for') != 1:
        raise ValueError('expected one HALD ALL loop')
    marker = text.index('#pragma omp parallel for')
    loop = text.index('for (UINT64 __all0__offset', marker)
    start = text.index('{', loop)
    body = text[start+1:block_end(text, start)-1]
    declaration = re.search(r'\b(INT(?:16|32|64)) __all0 =', body)
    if declaration is None:
        raise ValueError('missing signed ALL range type')
    range_type = declaration.group(1)
    body, removed = re.subn(r'^\s*(UINT64 __all0__value =[^\n]*|INT(?:16|32|64) __all0 =[^\n]*)\n', '', body, flags=re.MULTILINE)
    if removed != 2:
        raise ValueError('unexpected ALL range declarations')
    body = divide255(body)
    if any(token in body for token in ('__X(', '__DIV(', '__MOD(', '__CHR(', '__HALT', 'SYSTEM_')):
        raise ValueError('runtime helper remains in the HALD kernel')
    function = re.search(r'void HaldClut_Apply [^\n]*\n\{', text)
    if function is None:
        raise ValueError('missing HaldClut.Apply implementation')
    end = block_end(text, function.end()-1)
    outer = text.index('\n\t{\n\t\t' + range_type + ' __all0__start', function.end())
    prefix = text[:outer]
    if prefix[function.end():].count('__ASSERT(') != 4:
        raise ValueError('expected four host-side HALD argument checks')
    for check in ('range >= 2', 'target__len >= source__len', 'coordinates[value].fraction'):
        if check not in prefix[function.end():]:
            raise ValueError('missing HALD host validation or coordinate preparation')
    guard = '#if !defined(_OPENMP) || _OPENMP < 200805'
    if guard not in prefix:
        raise ValueError('missing OpenMP compiler guard')
    if backend == 'gpu':
        prefix = prefix.replace(guard, '#if !defined(_OPENMP) || _OPENMP < 201511', 1)
        prefix = prefix.replace('OpenMP CPU output requires an OpenMP 3.0+ C compiler',
                                'HALD GPU output requires an OpenMP 4.5+ C compiler', 1)
    checks = ''.join('\t\t__ASSERT(' + disjoint(*pair) + ', 0);\n' for pair in (
        ('source', 'source__len', 'lut', 'lut__len'),
        ('source', 'source__len', 'target', 'source__len'),
        ('lut', 'lut__len', 'target', 'source__len'),
    ))
    pragma = ('#pragma omp target teams distribute parallel for '
              'map(to: source[0:source__len], lut[0:lut__len], coordinates[0:256]) '
              'map(from: target[0:source__len]) firstprivate(range, count)' if backend == 'gpu'
              else '#pragma omp parallel for schedule(static)')
    replacement = ('\n\tif (count > 0) {\n' + checks + '\t\t' + pragma +
                   '\n\t\tfor (' + range_type + ' __all0 = 0; __all0 < count; ++__all0) {\n' + body + '\n\t\t}\n\t}\n}')
    return '#include <stdint.h>\n' + prefix + replacement + text[end:]


def main():
    parser = argparse.ArgumentParser(description='Build the checked HALD OpenMP kernel from its Oberon source.')
    parser.add_argument('--voc', required=True)
    parser.add_argument('--vocroot', required=True)
    parser.add_argument('--source', type=Path, default=Path(__file__).with_name('HaldClut.Mod'))
    parser.add_argument('--work', type=Path, required=True)
    parser.add_argument('--model', choices=('2', 'C'), default='2')
    parser.add_argument('--backend', choices=('cpu', 'gpu'), default='gpu')
    parser.add_argument('--cc', default=os.environ.get('CC', 'clang'))
    parser.add_argument('--cflags', default=os.environ.get('CFLAGS', '-O3 -fno-strict-aliasing'))
    args = parser.parse_args()
    if hashlib.sha256(args.source.read_bytes()).hexdigest() != SOURCE_SHA256:
        parser.error('HaldClut.Mod has changed; review the kernel backend before rebuilding')
    image = Path(args.vocroot).resolve()
    folder = args.work.resolve()
    folder.mkdir(parents=True, exist_ok=True)
    flags = os.environ.get('VOC_OPENMP_CFLAGS', '')
    if not flags:
        parser.error('set VOC_OPENMP_CFLAGS for the selected OpenMP compiler and target')
    source = folder / 'HaldClut.Mod'
    if source.resolve() != args.source.resolve():
        shutil.copy2(args.source, source)
    env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=os.environ.get('VOCLIBDIR', str(image / 'lib')),
               OBERON=str(image / args.model / 'sym'), CC=args.cc, CFLAGS=args.cflags)
    subprocess.run([str(Path(args.voc).resolve()), '-O' + args.model, '-sFjPSx', str(source)], cwd=folder, env=env, check=True)
    generated = folder / 'HaldClut.c'
    original = generated.read_text()
    try:
        result = transform(original, args.backend)
    except (ValueError, IndexError) as error:
        parser.error('unsupported VOC output: ' + str(error))
    (folder / 'HaldClut.voc.c').write_text(original)
    generated.write_text(result)
    command = [*shlex.split(args.cc), *shlex.split(args.cflags), *shlex.split(flags),
               '-I' + str(image / args.model / 'include'), '-c', str(generated), '-o', str(folder / 'HaldClut.o')]
    print(shlex.join(command), flush=True)
    subprocess.run(command, cwd=folder, env=env, check=True)


if __name__ == '__main__':
    main()
