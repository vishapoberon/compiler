#!/usr/bin/env python3
"""Replay Unicode IDNA fixtures and differential scalar-codec/NFC checks."""

import argparse
import hashlib
import importlib
import json
from pathlib import Path
import random
import re
import subprocess
import sys
import types
import unicodedata as ucd

ROOT = Path(__file__).resolve().parents[1]


def reference():
    hashes = {
        ROOT / "data/idnadata.py": "486f2385a184e778a20fa078f69b76a704effd4bc295c89613e379e28476a785",
        ROOT / "data/uts46data.py": "1fd277e55903d05f4bf6628eaa378d19dd80f956ba1653e8cfa273e0aee1fa9b",
        ROOT / "tests/reference/core.py": "3f6ebf5d5c9cb8c4d9d51da634ad594445733399af4f375a6c15dfc99554d4b7",
        ROOT / "tests/reference/intranges.py": "6a652d91d8587101bc66bf82a0c33f91545a731922bc2d568313756fadca29d5",
        ROOT / "data/IdnaTestV2.txt": "ffcf59f6e97d765caa5ac8315e9511ba3b42955a554cbc431e4c016f20d25ca9",
    }
    for path, digest in hashes.items():
        assert hashlib.sha256(path.read_bytes()).hexdigest() == digest, path
    package = types.ModuleType("idna_reference")
    package.__path__ = [str(ROOT / "data"), str(ROOT / "tests/reference")]
    sys.modules[package.__name__] = package
    return importlib.import_module("idna_reference.core")


def profile(raw, ref):
    raw = raw.split(b"\0", 1)[0]
    if not 0 < len(raw) <= 1023:
        return None
    if any(c < 128 and c not in b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-." for c in raw):
        return None
    try:
        text = raw.decode("utf-8")
        ascii = ref.encode(text, uts46=True, std3_rules=True, transitional=False)
        if len(ascii) > 253 or ascii.endswith(b"."):
            return None
        unicode = ref.decode(ascii)
        labels = unicode.split(".")
        if any(ucd.bidirectional(c) in ("R", "AL", "AN") for c in unicode):
            for label in labels:
                ref.check_bidi(label, check_ltr=True)
        for a, u in zip(ascii.split(b"."), labels):
            if a.startswith(b"xn--"):
                if u.isascii() or b"xn--" + u.encode("punycode") != a:
                    return None
        return ascii.hex().upper(), unicode.encode().hex().upper()
    except (UnicodeError, ValueError):
        return None


def unescape(text):
    if text == '""':
        return ""
    return re.sub(r"\\u([0-9A-Fa-f]{4})|\\x\{([0-9A-Fa-f]+)\}",
                  lambda m: chr(int(m[1] or m[2], 16)), text)


def scalar_hex(text):
    return "".join(f"{ord(c):06X}" for c in text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("runner", type=Path)
    parser.add_argument("--work", type=Path, required=True)
    args = parser.parse_args()
    assert ucd.unidata_version == "16.0.0", "These checks require Python's Unicode 16.0 tables."
    ref = reference()
    rng = random.Random(3492)
    requests, expected, labels = [], [], []
    counts = {"idna_fixtures": 0, "strict_profile_rejections": 0, "domain_differential": 0, "rfc3492": 0, "punycode": 0, "nfc": 0}
    profile_rejections = []

    def add(mode, payload, answer, label):
        requests.append(mode + " " + payload)
        expected.append(answer)
        labels.append(label)

    for line_number, row in enumerate((ROOT / "data/IdnaTestV2.txt").read_text().splitlines(), 1):
        row = row.split("#", 1)[0].strip()
        if not row:
            continue
        fields = [v.strip() for v in row.split(";")]
        source = unescape(fields[0])
        unicode = unescape(fields[1]) if fields[1] else source
        status = fields[4] if fields[4] else fields[2]
        raw = source.encode("utf-8", "surrogatepass")
        answer = None if status not in ("", "[]") else profile(raw, ref)
        if status in ("", "[]") and answer is None:
            counts["strict_profile_rejections"] += 1
            profile_rejections.append({"line": line_number, "source": source, "unicode": unicode})
        if answer is not None:
            ascii = unescape(fields[3]) if fields[3] else unicode
            assert answer == (ascii.encode().hex().upper(), unicode.encode().hex().upper()), line_number
        add("I", raw.hex(), answer, f"IdnaTestV2:{line_number}")
        counts["idna_fixtures"] += 1

    domains = ["ծոց.հայ", "ԾՈՑ.ՀԱՅ", "faß.de", "e\u0301.example", "l·l.cat", "a·b.cat",
               "א.example", "123.א", "a.א", "क्\u200dष.example", "ب\u200cب.example",
               "ａ＠ｂ.example", "a。b", "example.org.", "xn--", "ab--cd.example",
               "a"*63+".example", "a"*64+".example", "xn--abc.example"]
    population = "abcdefghijklmnopqrstuvwxyz0123456789-ծոցհայéößΣσς日本例子אبت١۲कष्\u200c\u200d\u0301\u0300\u034f\u00ad😀。＠／：·\u0375\u05f3・"
    for _ in range(2000):
        domain = "".join(rng.choice(population) for _ in range(rng.randrange(1, 40))) + ".example"
        domains.append(domain)
        try:
            domains.append(ref.encode(domain, uts46=True, std3_rules=True).decode())
        except UnicodeError:
            pass
    for domain in domains:
        raw = domain.encode()
        add("I", raw.hex(), profile(raw, ref), repr(domain))
        counts["domain_differential"] += 1
    for _ in range(300):
        raw = bytes(rng.randrange(1, 256) for _ in range(rng.randrange(1, 100)))
        add("I", raw.hex(), profile(raw, ref), "random UTF-8 bytes")
        counts["domain_differential"] += 1

    for line_number, row in enumerate((ROOT / "tests/rfc3492.txt").read_text().splitlines(), 1):
        if row.startswith("#") or not row:
            continue
        points, encoded = row.split(";")
        text = "".join(chr(int(value, 16)) for value in points.split())
        basic, delimiter, suffix = encoded.rpartition("-")
        canonical = basic + delimiter + suffix.lower()
        add("E", scalar_hex(text), (canonical.encode().hex().upper(),), f"RFC3492:{line_number} encode")
        add("D", encoded.encode().hex(), (scalar_hex(text),), f"RFC3492:{line_number} decode")
        counts["rfc3492"] += 2

    texts = ["", "abc", "ծոց", "հայ", "bücher", "\0", "\U0001f600", "\U0010ffff"*1024]
    for _ in range(1200):
        values = [rng.randrange(0x110000) for _ in range(rng.randrange(0, 100))]
        texts.append("".join(chr(c) for c in values if not 0xD800 <= c <= 0xDFFF))
    for text in texts:
        encoded = text.encode("punycode")
        add("E", scalar_hex(text), (encoded.hex().upper(),), "Punycode encode")
        add("D", encoded.hex(), (scalar_hex(text),), "Punycode decode")
        counts["punycode"] += 2
    for _ in range(300):
        raw = bytes(rng.choice(b"abcdefghijklmnopqrstuvwxyz0123456789-") for _ in range(rng.randrange(1, 120)))
        try:
            text = raw.decode("punycode")
            answer = (scalar_hex(text),) if len(text) <= 1024 and all(not 0xD800 <= ord(c) <= 0xDFFF for c in text) else None
        except UnicodeError:
            answer = None
        add("D", raw.hex(), answer, "hostile Punycode decode")
        counts["punycode"] += 1

    texts = [chr(c) for c in range(0x110000) if ucd.decomposition(chr(c))]
    texts += ["".join(rng.choice("aéΣծ\u0301\u0315\u0300\u0327\u0345\u1100\u1161\u11a8") for _ in range(rng.randrange(1, 60))) for _ in range(1000)]
    for text in texts:
        add("N", scalar_hex(text), (scalar_hex(ucd.normalize("NFC", text)),), "Unicode NFC")
        add("N", scalar_hex(ucd.normalize("NFD", text)), (scalar_hex(ucd.normalize("NFC", text)),), "Unicode NFD to NFC")
        counts["nfc"] += 2

    args.work.mkdir(parents=True, exist_ok=True)
    payload = ("\n".join(requests) + "\n").encode()
    (args.work / "requests.txt").write_bytes(payload)
    completed = subprocess.run([str(args.runner.resolve())], input=payload, capture_output=True, timeout=180)
    (args.work / "output.txt").write_bytes(completed.stdout)
    (args.work / "stderr.txt").write_bytes(completed.stderr)
    assert completed.returncode == 0, f"runner failed: {completed.returncode}"
    rows = completed.stdout.decode().splitlines()
    assert len(rows) == len(expected), (len(rows), len(expected))
    failures = []
    for i, (row, answer) in enumerate(zip(rows, expected)):
        fields = row.split("\t")
        actual = tuple(fields[1:]) if fields[0] == "0" else None
        if actual != answer:
            failures.append({"index": i, "label": labels[i], "request": requests[i], "actual": actual, "expected": answer})
    (args.work / "failures.json").write_text(json.dumps(failures, ensure_ascii=True, indent=2)+"\n")
    (args.work / "summary.json").write_text(json.dumps(counts, indent=2)+"\n")
    (args.work / "profile-rejections.json").write_text(json.dumps(profile_rejections, ensure_ascii=True, indent=2)+"\n")
    if failures:
        for failure in failures[:12]:
            print(failure)
        raise AssertionError(f"{len(failures)} vector mismatches; see {args.work / 'failures.json'}")
    print("Native domain and codec vectors passed:", len(requests), counts)


if __name__ == "__main__":
    main()
