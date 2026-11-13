# in-band registration

`XmppRegister` implements XEP-0077 legacy-field retrieval, explicit submissions,
authenticated account/service changes and removal through the bounded IQ router.
Rebuild code using `XmppClient` and `XmppIQ` when updating: their hook and
request interfaces now include the registration lifecycle.

## before login

Create a separate registration-only client:

```oberon
router := IQ.New(application);
client := Client.NewRegistration(transport, router, domain, error);
IF (client # NIL) & client.Start() THEN
  (* drive client.Step until RegistrationReady or an error *)
END;
```

The transport must verify TLS for `domain`, directly or through STARTTLS. The
client requires a fresh registration feature advertisement after TLS; a
plaintext advertisement is not enough. It sends no SASL response and binds no
resource. `authenticated` remains false and `jid` remains `NIL`.

Implement `XmppClient.Hook.RegistrationReady(client)` to start the exchange.
This is separate from authenticated `Ready(client, jid)`. Presence and MUC
trackers forward it without activating their authenticated state. Ordinary IQ
handlers are not served before login.

The pre-login router accepts only registration queries to the verified service
domain. The client also checks directly sent stanzas: they must be registration
IQ gets/sets with a nonempty ID, no claimed sender and no foreign destination.
Anonymous messages, presence and unrelated queries are rejected.
Router-generated pre-login IQs use the stream's implicit service destination;
their request records retain the canonical peer for strict reply matching.

Successful registration does not log the account in. Close this client, then
create a normal `XmppClient.New` session with fresh hooks/router and the chosen
credentials.

## retrieving and answering fields

Call `Register.Query(router, peer, timeoutMS, action, error)` after the transport
is ready. An empty peer means the connected service. Authenticated clients can
explicitly query another service JID; the application chooses which service to
trust and what credentials to disclose. Login credentials are never copied into
registration fields automatically.

In the IQ action's completion callback, `Register.Read(request)` returns a
`Form`, or `NIL` for failed, malformed or unrelated responses. The form exposes
`instructions`, `registered`, `legacy`, `fields` and `count`. Legacy names follow
XEP-0077, including `username`, `password`, `email` and the optional server `key`.
`form.Get(name)` returns a copy; `form.Set(name, value)` changes only an advertised
legacy field. Values use UTF-16 code units; use `XmppItems.UTF8` for UTF-8 input.

Inspect the instructions and ask for the required answers. Explicitly call
`Register.Submit(router, form, timeoutMS, action, error)` to send them. The form
is bound to its original peer and client connection, preserving field order
and the server key. It cannot be redirected or reused on another connection.
Conflicts do not trigger automatic retries.

`dataForm` and `outOfBand` flag other workflows. `legacy` is false if the
response requires either workflow, contains an unknown requirement, or has no
answer fields. Submission then fails with an unsupported-workflow diagnostic.
These checks protect the legacy-field workflow. Servers requiring data-form
or CAPTCHA registration need another registration client. The response tree is
available through the IQ request; no URLs are fetched or instructions approved
automatically.

## authenticated changes and removal

A normal online client can retrieve and submit the same fields, for example to
change a password or gateway registration. A response can include `registered`
alongside editable fields.

`Register.Remove(router, peer, timeoutMS, action, error)` explicitly requests
removal. It requires an authenticated online client: TLS and the pre-login
registration state alone do not authorize it. User confirmation and connection
policy after removal belong to the caller; the library does not disconnect or
reconnect automatically.

Use `XmppIQ.EmptyResult(request)` to confirm a successful submission/removal.
Errors, conflicts, deadlines, cancellation, queue limits and send failures use
the normal IQ statuses. Replies must match the exact peer, ID and local recipient
rules. Before login there is no bound local JID, so only omitted recipients are
accepted. `request.client` identifies the connection that issued the request.

Drive `router.Tick(elapsedMS)` for deadlines. Normal close/error hooks cancel
pending requests. Before `client.Abort`, stop the IQ router and any tracking
hooks explicitly, since abort skips callbacks.

## limits and secrets

Parsing bounds direct content parts, field count, each value to 4,096 UTF-16
units and combined instructions/values to 16,384 units. Duplicate fields,
instructions or registration markers and nested legacy values fail. The XML
stream's byte, node, attribute and nesting limits apply first.

Submitted values are copied into an outgoing query; its retained mutable text
buffers are cleared after sending. The editable form remains usable until
`form.Clear`. Clearing wipes parsed/edited legacy values and their legacy
response buffers, releases the connection reference and disables resubmission.
Copies returned by `Get`, unsupported response payloads and application-owned
credential strings remain the caller's responsibility.

Output hooks see the original stanza during sending. Keep registration stanzas,
passwords and server keys out of logs. Buffer clearing does not erase external
copies or logs.
