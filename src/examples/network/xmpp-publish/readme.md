# XMPP microblog publishing

This example publishes one UTF-8 message to an account's personal XMPP microblog
node using VOC's native XMPP library and the
[`xmpp-publish` port](../../../ports/norayr/xmpp-publish/README.md).
It requires Linux and an XMPP account whose server supports PEP microblogs.

From the VOC checkout:

```sh
make -C src/examples/network/xmpp-publish
make -C src/examples/network/xmpp-publish test
```

The program is `build/examples/network/xmpp-publish/2/XmppPublish`. Tests use
synthetic credentials and local TLS peers; they do not publish to a live server.
They require Python 3.13+ and OpenSSL.

`make native-test` builds and tests a shared-module consumer. Use `HRESH_BUILD`
to select the modular compiler/library output directory and a separate `BUILD`
directory for its executable.

Set up a mode-`0600` configuration file as described in the
[package README](../../../ports/norayr/xmpp-publish/README.md#configure-and-publish),
including explicit `allow_plain=yes`, then run:

```sh
XMPP_CONFIG=/path/to/account.conf build/examples/network/xmpp-publish/2/XmppPublish
```

Unicode JIDs, domains and messages are supported. The program verifies TLS,
checks the publish IQ result and returns nonzero on failure. Automatic SRV
lookup, SCRAM and live PEP interoperability testing remain pending. A failure
after sending may leave the publication outcome uncertain; the program does
not retry automatically.
