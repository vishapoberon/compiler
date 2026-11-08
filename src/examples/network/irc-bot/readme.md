# IRC history bot

`vocbot` uses VOC's IRC client library to log a channel and answer private
`help`, `last n` and `search [n] pattern` commands. It keeps receiving IRC
traffic while sending paced replies, and restores history from its channel
log after restarting. The sources are synchronized with
[norayr/irc_bot](https://github.com/norayr/irc_bot).

After building VOC's Linux model-2 networking profile:

```sh
make -C src/examples/network/irc-bot
make -C src/examples/network/irc-bot test
```

The executable is `build/examples/network/irc-bot/2/vocbot`. Run it from a
directory where its channel log should be kept:

```sh
/path/to/voc/build/examples/network/irc-bot/2/vocbot \
  -h irc.libera.chat -p 6697 -o owner -u vocbot -n vocbot -r '#test'
```

Verified TLS is the default. For SASL PLAIN, export `IRC_SASL_PASSWORD` and
add `-a account-name`. `-s NAME` selects another password environment
variable; `-w password` is the separate IRC server PASS credential.
`SSL_CERT_FILE` selects a CA bundle. For a controlled plaintext server,
explicitly select `-x plain`. `-l` changes the history limit, default 200.
The pure-Oberon TLS library's platform and security limitations apply.

Tests use local peers and synthetic credentials; they do not join live IRC
channels. They require Python 3. `make native-test` exercises a shared-module
consumer; select `HRESH_BUILD` and a separate `BUILD` directory as needed.
`make run ARGS='...'` runs from the build directory so logs stay with its
generated files. Ctrl-C stops reconnecting and flushes logs.

Copyright (C) 2017–2026 Norayr Chilingarian. GPL-3.0-only; see `LICENSE`.
