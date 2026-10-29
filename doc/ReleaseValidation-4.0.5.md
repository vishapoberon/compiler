# VOC 4.0.5 validation

The Internet implementation was rebuilt for model 2 with the 32-bit
`Endpoint.scope` field. Local loopback regressions passed: 330 socket checks
and NetSystem basic (26), refused (72), pending (280), blocking (135) and
resume (8) checks.

`Sockets`, `DNS`, `Internet` and `NetSystem` were compared byte-for-byte with
upstream Internet revision `7abf3c1f539aec3fe2e73625c031af1f8219dc04`.
Their bodies also match the local Polpo copies after normalizing imports.

With a matching checkout installation, run:

```sh
make -C src/test/ports test NETWORK=1
```

Compiler, runtime and picture-codec sources are unchanged from 4.0.4 apart
from the reported version. Their previous coverage and platform limitations
are documented in [4.0.4 validation](ReleaseValidation-4.0.4.md); the full
compiler matrix was not repeated for this patch release.
