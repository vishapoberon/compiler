# XMPP microblog publishing

This example publishes one UTF-8 message to an account's personal XMPP microblog
node using VOC's native XMPP library and the
[`xmpp-publish` port](../../../ports/norayr/xmpp-publish/README.md).
It requires Linux and an XMPP account whose server supports PEP microblogs.

From the VOC checkout:

```sh
make -C src/examples/network/xmpp-publish
make -C src/examples/network/xmpp-publish test
make -C src/examples/network/xmpp-publish probe
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

## Publish and verify stored text

`XmppPublishProbe.Mod` is a second runnable example. It reads the same local
configuration, publishes one caller-selected item and retrieves that exact
item to check its stored Atom text. Account details remain in the local file.
For example, create a mode-`0600` configuration using your own account:

```ini
[account]
jid=user@example.org/voc-example
password=replace-with-your-password
message=Hello from VOC.
allow_plain=yes
tls=starttls
port=5222
timeout_ms=30000
```

The example calls `XmppPublisher.RunItem(config, itemID, TRUE, error)`.
Generate and record a fresh ID for each intended new post, then run:

```sh
item_id="$(python3 -c 'import uuid; print(uuid.uuid4())')"
printf 'Item ID: %s\n' "$item_id"
XMPP_CONFIG=/path/to/account.conf \
  build/examples/network/xmpp-publish/2/XmppPublishProbe "$item_id"
```

Success prints `Microblog entry published and retrieved with matching text`.
The post remains on the account's `urn:xmpp:microblog:0` node and may notify
subscribers. Run it only when you intend to publish. If retrieval fails after
publication, retain the item ID and check the stored item before deciding to
send again. Each invocation attempts publication; retries are application-owned.
`make native-probe` builds the same example as a shared-module consumer.

Unicode JIDs, domains and messages are supported. The program verifies TLS,
checks the publish IQ result and returns nonzero on failure. Automatic SRV
lookup and SCRAM remain pending. Live-server tests cover publication and
exact-item retrieval over verified STARTTLS. Broader server interoperability
testing remains pending. A failure after sending may leave the publication
outcome uncertain; the program does not retry automatically.
