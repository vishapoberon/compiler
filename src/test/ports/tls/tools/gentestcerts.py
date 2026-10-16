#!/usr/bin/env python3
# gentestcerts.py dir: certificate chains for TLSTestChain (DER files, and PEM bundles of roots).
# Valid from 2025 to 2035 unless said otherwise; the test takes 2026-06-01 as now.
import sys, os, datetime, ipaddress
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID, ObjectIdentifier
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, ec, padding

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
T0 = datetime.datetime(2025, 1, 1); T1 = datetime.datetime(2035, 1, 1)

def name(cn): return x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, cn)])

def general(s):  # "ip:10.0.0.0/8", "ip:1.2.3.4", "email:x@y", "dir:O", else a DNS name
    if s.startswith("ip:"):
        v = s[3:]
        return x509.IPAddress(ipaddress.ip_network(v) if "/" in v else ipaddress.ip_address(v))
    if s.startswith("email:"): return x509.RFC822Name(s[6:])
    if s.startswith("dir:"): return x509.DirectoryName(x509.Name([x509.NameAttribute(NameOID.ORGANIZATION_NAME, s[4:])]))
    return x509.DNSName(s)

def cert(subject, key, issuer, ikey, h, ca=None, pathlen=None, ku=None, eku=None, san=None,
         unknown_critical=False, t0=T0, t1=T1, permitted=None, excluded=None, org=None, pss_salt=None):
    subj = name(subject)
    if org: subj = x509.Name([x509.NameAttribute(NameOID.ORGANIZATION_NAME, org), x509.NameAttribute(NameOID.COMMON_NAME, subject)])
    b = (x509.CertificateBuilder().subject_name(subj).issuer_name(name(issuer))
         .public_key(key.public_key()).serial_number(x509.random_serial_number())
         .not_valid_before(t0).not_valid_after(t1))
    if ca is not None:
        b = b.add_extension(x509.BasicConstraints(ca=ca, path_length=pathlen), critical=True)
    if ku is not None:
        flags = dict(digital_signature=False, content_commitment=False, key_encipherment=False,
                     data_encipherment=False, key_agreement=False, key_cert_sign=False, crl_sign=False,
                     encipher_only=False, decipher_only=False)
        flags.update(ku)
        b = b.add_extension(x509.KeyUsage(**flags), critical=True)
    if eku is not None: b = b.add_extension(x509.ExtendedKeyUsage(eku), critical=False)
    if san is not None: b = b.add_extension(x509.SubjectAlternativeName([general(s) for s in san]), critical=False)
    if permitted is not None or excluded is not None:
        b = b.add_extension(x509.NameConstraints(
            permitted_subtrees=[general(s) for s in permitted] if permitted else None,
            excluded_subtrees=[general(s) for s in excluded] if excluded else None), critical=True)
    if unknown_critical:
        b = b.add_extension(x509.UnrecognizedExtension(ObjectIdentifier("1.3.6.1.4.1.99999.1"), b"\x05\x00"), critical=True)
    if pss_salt is not None:  # RSASSA-PSS, MGF1 with the same hash
        return b.sign(ikey, h, rsa_padding=padding.PSS(mgf=padding.MGF1(h), salt_length=pss_salt))
    return b.sign(ikey, h)

def save(fname, c): open(os.path.join(out, fname), 'wb').write(c.public_bytes(serialization.Encoding.DER))
def pem(fname, *cs): open(os.path.join(out, fname), 'wb').write(b"".join(c.public_bytes(serialization.Encoding.PEM) for c in cs))

CA_KU = dict(key_cert_sign=True, crl_sign=True)
LEAF_KU = dict(digital_signature=True, key_encipherment=True)
SERVER = [ExtendedKeyUsageOID.SERVER_AUTH]
rsa_root_k = rsa.generate_private_key(65537, 2048); rsa_int_k = rsa.generate_private_key(65537, 2048)
rsa_leaf_k = rsa.generate_private_key(65537, 2048)
rsa_root = cert("RSA Root", rsa_root_k, "RSA Root", rsa_root_k, hashes.SHA256(), ca=True, ku=CA_KU)
rsa_int = cert("RSA Intermediate", rsa_int_k, "RSA Root", rsa_root_k, hashes.SHA384(), ca=True, pathlen=0, ku=CA_KU)
save("rsa_root.der", rsa_root); save("rsa_int.der", rsa_int); pem("rsa_roots.pem", rsa_root)
save("rsa_leaf.der", cert("www.example.test", rsa_leaf_k, "RSA Intermediate", rsa_int_k, hashes.SHA256(),
     ca=False, ku=LEAF_KU, eku=SERVER, san=["www.example.test", "*.shop.example.test"]))

ec_root_k = ec.generate_private_key(ec.SECP384R1()); ec_int_k = ec.generate_private_key(ec.SECP256R1())
ec_leaf_k = ec.generate_private_key(ec.SECP256R1())
ec_root = cert("EC Root", ec_root_k, "EC Root", ec_root_k, hashes.SHA384(), ca=True, ku=CA_KU)
ec_int = cert("EC Intermediate", ec_int_k, "EC Root", ec_root_k, hashes.SHA384(), ca=True, ku=CA_KU)
save("ec_root.der", ec_root); save("ec_int.der", ec_int); pem("roots.pem", rsa_root, ec_root)
save("ec_leaf.der", cert("ec.example.test", ec_leaf_k, "EC Intermediate", ec_int_k, hashes.SHA256(),
     ca=False, ku=dict(digital_signature=True), eku=SERVER, san=["ec.example.test"]))

bad_k = rsa.generate_private_key(65537, 2048)
# an intermediate that is not a CA, and the leaf it signed
save("noca_int.der", cert("No CA", bad_k, "RSA Root", rsa_root_k, hashes.SHA256(), ca=False, ku=CA_KU))
save("noca_leaf.der", cert("a.example.test", rsa_leaf_k, "No CA", bad_k, hashes.SHA256(), eku=SERVER, san=["a.example.test"]))
# a CA without keyCertSign
save("nokcs_int.der", cert("No KCS", bad_k, "RSA Root", rsa_root_k, hashes.SHA256(), ca=True, ku=dict(digital_signature=True)))
save("nokcs_leaf.der", cert("b.example.test", rsa_leaf_k, "No KCS", bad_k, hashes.SHA256(), eku=SERVER, san=["b.example.test"]))
# path length: rsa_int allows 0 CAs below it; one more CA under it
sub_k = rsa.generate_private_key(65537, 2048)
save("sub_int.der", cert("Sub CA", sub_k, "RSA Intermediate", rsa_int_k, hashes.SHA256(), ca=True, ku=CA_KU))
save("sub_leaf.der", cert("c.example.test", rsa_leaf_k, "Sub CA", sub_k, hashes.SHA256(), eku=SERVER, san=["c.example.test"]))
# a leaf for clients only, one with an unknown critical extension, an expired one
save("client_leaf.der", cert("d.example.test", rsa_leaf_k, "RSA Intermediate", rsa_int_k, hashes.SHA256(),
     ku=LEAF_KU, eku=[ExtendedKeyUsageOID.CLIENT_AUTH], san=["d.example.test"]))
save("crit_leaf.der", cert("e.example.test", rsa_leaf_k, "RSA Intermediate", rsa_int_k, hashes.SHA256(),
     ku=LEAF_KU, eku=SERVER, san=["e.example.test"], unknown_critical=True))
save("expired_leaf.der", cert("f.example.test", rsa_leaf_k, "RSA Intermediate", rsa_int_k, hashes.SHA256(),
     ku=LEAF_KU, eku=SERVER, san=["f.example.test"], t0=datetime.datetime(2020, 1, 1), t1=datetime.datetime(2021, 1, 1)))
# a leaf signed by the RSA leaf (a certificate that is not a CA)
save("byleaf_leaf.der", cert("g.example.test", bad_k, "www.example.test", rsa_leaf_k, hashes.SHA256(),
     eku=SERVER, san=["g.example.test"]))
# a wildcard for a whole top level domain
save("tld_leaf.der", cert("tld", rsa_leaf_k, "RSA Intermediate", rsa_int_k, hashes.SHA256(),
     ku=LEAF_KU, eku=SERVER, san=["*.test"]))
print("written to", out)

# name constraints (RFC 5280 4.2.1.10) on intermediates under the RSA root
nc_k = rsa.generate_private_key(65537, 2048)
save("nc_int.der", cert("NC Intermediate", nc_k, "RSA Root", rsa_root_k, hashes.SHA256(), ca=True, ku=CA_KU,
     permitted=["example.test", "ip:10.0.0.0/8"], excluded=["bad.example.test"]))
def ncleaf(f, issuer, ik, san, org=None):
    save(f, cert("h.example.test", rsa_leaf_k, issuer, ik, hashes.SHA256(), ku=LEAF_KU, eku=SERVER, san=san, org=org))
ncleaf("nc_ok_leaf.der", "NC Intermediate", nc_k, ["www.example.test", "ip:10.1.2.3"])
ncleaf("nc_out_leaf.der", "NC Intermediate", nc_k, ["www.example.test", "www.other.test"])
ncleaf("nc_excl_leaf.der", "NC Intermediate", nc_k, ["x.bad.example.test"])
ncleaf("nc_ip_leaf.der", "NC Intermediate", nc_k, ["www.example.test", "ip:192.168.1.1"])
ncleaf("nc_wild_leaf.der", "NC Intermediate", nc_k, ["*.example.test"])
save("ncdir_int.der", cert("NC Dir Intermediate", nc_k, "RSA Root", rsa_root_k, hashes.SHA256(), ca=True, ku=CA_KU,
     permitted=["dir:Good"]))
ncleaf("ncdir_ok_leaf.der", "NC Dir Intermediate", nc_k, ["h.example.test"], org="Good")
ncleaf("ncdir_bad_leaf.der", "NC Dir Intermediate", nc_k, ["h.example.test"], org="Bad")
save("ncmail_int.der", cert("NC Mail Intermediate", nc_k, "RSA Root", rsa_root_k, hashes.SHA256(), ca=True, ku=CA_KU,
     permitted=["email:example.test"]))
ncleaf("ncmail_ok_leaf.der", "NC Mail Intermediate", nc_k, ["h.example.test"])
ncleaf("ncmail_bad_leaf.der", "NC Mail Intermediate", nc_k, ["h.example.test", "email:a@example.test"])

# RSASSA-PSS signatures (RFC 4055): an intermediate signed by the RSA root, leaves signed by it
pss_k = rsa.generate_private_key(65537, 2048)
save("pss_int.der", cert("PSS Intermediate", pss_k, "RSA Root", rsa_root_k, hashes.SHA256(), ca=True, ku=CA_KU, pss_salt=32))
save("pss_leaf.der", cert("pss.example.test", rsa_leaf_k, "PSS Intermediate", pss_k, hashes.SHA384(),
     ku=LEAF_KU, eku=SERVER, san=["pss.example.test"], pss_salt=48))
save("pss_salt_leaf.der", cert("pss.example.test", rsa_leaf_k, "PSS Intermediate", pss_k, hashes.SHA256(),
     ku=LEAF_KU, eku=SERVER, san=["pss.example.test"], pss_salt=20))
# P-521: an intermediate under the P-384 root, a leaf signed with SHA-512
p521_k = ec.generate_private_key(ec.SECP521R1())
save("p521_int.der", cert("P-521 Intermediate", p521_k, "EC Root", ec_root_k, hashes.SHA384(), ca=True, ku=CA_KU))
save("p521_leaf.der", cert("p521.example.test", ec_leaf_k, "P-521 Intermediate", p521_k, hashes.SHA512(),
     ku=dict(digital_signature=True), eku=SERVER, san=["p521.example.test"]))
