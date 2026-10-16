# local TLS servers for the client tests (src/tlsConnect.Mod): one port per case, HTTP answer "ok";
# usage: testservers.py seconds dir; writes the keys and dir/ca.pem, then
#   SSL_CERT_FILE=dir/ca.pem ./tlsConnect localhost 18443
# 18443 RSA and 18444 ECDSA connect; 18445 wrong host, 18446 untrusted CA, 18447 expired,
# 18448 self-signed and 18449 TLS 1.2 only are refused; 18450 cut (no close_notify), 18451 closed
# properly, 18452 shorter than its Content-Length, 18453 1 MB (dir/big.ref); 18454 (127.0.0.1) and
# 18455 ([::1]) have only IP addresses as names; 18456 a P-521 key, 18457 an RSASSA-PSS signed
# certificate (under a second, RSA, root in ca.pem); 18458 asks for an optional client certificate
import ssl, socket, threading, datetime, sys, os, time, ipaddress
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, ec, padding
D = sys.argv[2]
now = datetime.datetime.now(datetime.timezone.utc)
def name(cn): return x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, cn)])
def mk(subject, key, issuer, ikey, ca, san=None, t0=None, t1=None, pss=False):
    b = (x509.CertificateBuilder().subject_name(name(subject)).issuer_name(name(issuer)).public_key(key.public_key())
         .serial_number(x509.random_serial_number()).not_valid_before(t0 or now - datetime.timedelta(days=1))
         .not_valid_after(t1 or now + datetime.timedelta(days=30))
         .add_extension(x509.BasicConstraints(ca=ca, path_length=None), critical=True))
    if san: b = b.add_extension(x509.SubjectAlternativeName(
        [x509.IPAddress(ipaddress.ip_address(s[3:])) if s.startswith("ip:") else x509.DNSName(s) for s in san]), critical=False)
    if not ca: b = b.add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.SERVER_AUTH]), critical=False)
    if pss: return b.sign(ikey, hashes.SHA256(), rsa_padding=padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=32))
    return b.sign(ikey, hashes.SHA256())
def pem(c): return c.public_bytes(serialization.Encoding.PEM)
def keypem(k): return k.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption())
ca_k = ec.generate_private_key(ec.SECP256R1()); ca = mk("Test CA", ca_k, "Test CA", ca_k, True)
other_k = ec.generate_private_key(ec.SECP256R1()); other = mk("Other CA", other_k, "Other CA", other_k, True)
rsaca_k = rsa.generate_private_key(65537, 2048); rsaca = mk("Test RSA CA", rsaca_k, "Test RSA CA", rsaca_k, True)
open(os.path.join(D, "ca.pem"), "wb").write(pem(ca) + pem(rsaca))
rk = rsa.generate_private_key(65537, 2048); ek = ec.generate_private_key(ec.SECP256R1())
cases = {  # port: (certificate chain, key, TLS 1.2 only)
 18443: ([mk("localhost", rk, "Test CA", ca_k, False, ["localhost"])], rk, False),                 # RSA: valid
 18444: ([mk("localhost", ek, "Test CA", ca_k, False, ["localhost"])], ek, False),                 # ECDSA: valid
 18445: ([mk("other.test", ek, "Test CA", ca_k, False, ["other.test"])], ek, False),               # wrong host
 18446: ([mk("localhost", ek, "Other CA", other_k, False, ["localhost"])], ek, False),             # untrusted CA
 18447: ([mk("localhost", ek, "Test CA", ca_k, False, ["localhost"], now - datetime.timedelta(days=60), now - datetime.timedelta(days=30))], ek, False),  # expired
 18448: ([mk("localhost", ek, "localhost", ek, False, ["localhost"])], ek, False),                # self-signed
 18449: ([mk("localhost", ek, "Test CA", ca_k, False, ["localhost"])], ek, True),                 # TLS 1.2 only
}
good = cases[18444]
MODE = {18450: 'cut', 18451: 'closed', 18452: 'short', 18453: 'big'}  # answers other than "ok"
for p in MODE: cases[p] = good
ipcert = ([mk("ip", ek, "Test CA", ca_k, False, ["ip:127.0.0.1", "ip:::1"])], ek, False)
cases[18454] = ipcert    # https://127.0.0.1:18454/ (the names are only IP addresses)
cases[18455] = ipcert    # https://[::1]:18455/, on ::1
p521k = ec.generate_private_key(ec.SECP521R1())
cases[18456] = ([mk("localhost", p521k, "Test CA", ca_k, False, ["localhost"])], p521k, False)  # CertificateVerify 0603
cases[18457] = ([mk("localhost", rk, "Test RSA CA", rsaca_k, False, ["localhost"], pss=True)], rk, False)  # an RSASSA-PSS certificate
cases[18458] = good  # asks for a client certificate (CertificateRequest), optional
BIG = bytes((i * 7 + i // 251) % 256 for i in range(1 << 20))
open(os.path.join(D, "big.ref"), "wb").write(BIG)
def answer(port, t):
    m = MODE.get(port)
    if m == 'cut':      # the body up to the end, then the TCP connection closes without close_notify
        t.sendall(b"HTTP/1.1 200 OK\r\nConnection: close\r\n\r\nno end"); t.close()
    elif m == 'closed': # the same, closed with close_notify
        t.sendall(b"HTTP/1.1 200 OK\r\nConnection: close\r\n\r\nproper end")
        try: t.unwrap().close()
        except Exception: t.close()
    elif m == 'short':  # 10 bytes announced, 2 sent
        t.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 10\r\nConnection: close\r\n\r\nok"); t.close()
    elif m == 'big':
        t.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % len(BIG) + BIG); t.close()
    else:
        t.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok"); t.close()
def serve(port, chain, key, tls12):
    cf = os.path.join(D, "c%d.pem" % port); kf = os.path.join(D, "k%d.pem" % port)
    open(cf, "wb").write(b"".join(pem(c) for c in chain)); open(kf, "wb").write(keypem(key))
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); ctx.load_cert_chain(cf, kf)
    if port == 18458: ctx.verify_mode = ssl.CERT_OPTIONAL; ctx.load_verify_locations(os.path.join(D, "ca.pem"))
    if tls12: ctx.minimum_version = ctx.maximum_version = ssl.TLSVersion.TLSv1_2
    else: ctx.minimum_version = ssl.TLSVersion.TLSv1_3
    if port == 18455: s = socket.socket(socket.AF_INET6); addr = ("::1", port)
    else: s = socket.socket(); addr = ("127.0.0.1", port)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(addr); s.listen(5); s.settimeout(1)
    end = time.time() + float(sys.argv[1])
    while time.time() < end:
        try: c, _ = s.accept()
        except socket.timeout: continue
        try:
            t = ctx.wrap_socket(c, server_side=True); t.settimeout(60); req = b""
            while b"\r\n\r\n" not in req:
                d = t.recv(4096)
                if not d: break
                req += d
            answer(port, t)
        except Exception as e: print(port, repr(e), flush=True); c.close()
for p, (chain, key, t12) in cases.items(): threading.Thread(target=serve, args=(p, chain, key, t12), daemon=True).start()
time.sleep(float(sys.argv[1]))
