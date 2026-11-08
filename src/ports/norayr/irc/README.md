# IRC client library

`IRC` provides parsed-message callbacks, registration, CAP/SASL, bounded
outgoing queues and reconnect handling. `IRCTCP` supplies TCP transport and
`IRCTLS` supplies verified TLS 1.3 through VOC's pure-Oberon TLS library.
The library is included in the Linux model-2 networking profile.

Build VOC with networking enabled before compiling applications. The
[upstream API documentation](https://github.com/norayr/irc#client-api)
describes `Config`, `New`, `Start`, `Poll`, `Stop`, callbacks and messages.
The history bot in `src/examples/network/irc-bot` demonstrates application
ownership of history, logging, channel policy and paced replies.

```sh
make -C src/examples/network/irc-bot
make -C src/examples/network/irc-bot test
```

The networking profile uses Linux socket bindings. DNS resolution is
currently synchronous. TLS certificate verification performs synchronous
computation and CA-file reading, and handshakes are serialized by the TLS
parser's shared state. Established socket I/O is resumable. The underlying
TLS arithmetic is not constant-time and has not been independently audited.

Parser, lifecycle, backpressure, authentication and loopback tests live in
`src/test/ports/irc` and run with the networking port regressions.

The sources are synchronized with upstream; provenance and adaptations are
recorded in `PORT.toml`. Copyright (C) 2017–2026 Norayr Chilingarian;
LGPL-3.0-only, with license texts in `LICENSE` and `COPYING`.
