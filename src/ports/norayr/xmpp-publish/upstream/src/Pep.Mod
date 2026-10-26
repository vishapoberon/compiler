MODULE Pep;
(*  Build the XEP-0060 / Atom stanza that publishes a microblog entry to the
    PEP node "urn:xmpp:microblog:0".

    Mirrors XMPP.Publish from the Modula-2 version:

      <iq from='romeo@montague.lit/pda' to='romeo@montague.lit' type='set'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
          <publish node='urn:xmpp:microblog:0'>
            <item id='...'>
              <entry xmlns='http://www.w3.org/2005/Atom'>
                <title type='text'>...</title>
                <id>tag:domain.tld,date:posts-...</id>
                <published>...</published>
                <updated>...</updated>
              </entry>
            </item>
          </publish>
        </pubsub>
      </iq>
*)

IMPORT Strings, C, Strophe, CStr, Clock;

PROCEDURE CreateItem (ctx: Strophe.Context;
                      name, text: ARRAY OF CHAR): Strophe.Stanza;
VAR
  item, body: Strophe.Stanza;
BEGIN
  item := Strophe.xmpp_stanza_new(ctx);
  Strophe.xmpp_stanza_set_name(item, name);
  body := Strophe.xmpp_stanza_new(ctx);
  Strophe.xmpp_stanza_set_text(body, text);
  Strophe.xmpp_stanza_add_child(item, body);
  Strophe.xmpp_stanza_release(body);
  RETURN item
END CreateItem;

PROCEDURE DomainOf (jid: C.string; VAR domain: ARRAY OF CHAR);
(*  The part of a JID after the first `@', e.g. "romeo@montague.lit/pda" ->
    "montague.lit".  Used to build the Atom tag: URI.  *)
VAR
  text: ARRAY 256 OF CHAR;
  i: INTEGER;
BEGIN
  CStr.CopyOut(jid, text);
  i := 0;
  WHILE (text[i] # 0X) & (text[i] # "@") DO INC(i) END;
  IF text[i] = "@" THEN
    i := i + 1
  ELSE
    i := 0
  END;
  Strings.Extract(text, i, SHORT(LEN(domain) - 1), domain)
END DomainOf;

PROCEDURE Build* (ctx: Strophe.Context;
                  from, to: C.string;
                  text: ARRAY OF CHAR;
                  VAR iqId: ARRAY OF CHAR;
                  VAR itemId: C.string): Strophe.Stanza;
(*  Build and return the publish <iq>.  The caller owns the result (release it)
    and must xmpp_free() ITEMID.  *)
VAR
  iq, pubsub, publish, item, entry, title, aid, published, updated: Strophe.Stanza;
  iqUuid: C.string;
  idText: ARRAY 64 OF CHAR;
  domain, nowIso, today: ARRAY 256 OF CHAR;
  atom, tag1, tag2: ARRAY 640 OF CHAR;
BEGIN
  iqUuid := Strophe.xmpp_uuid_gen(ctx);
  CStr.CopyOut(iqUuid, iqId);
  Strophe.xmpp_free(ctx, iqUuid);

  itemId := Strophe.xmpp_uuid_gen(ctx);
  CStr.CopyOut(itemId, idText);

  domain[0] := 0X;
  DomainOf(to, domain);
  Clock.Today(today);
  Clock.NowIso(nowIso);
  iq := Strophe.xmpp_iq_new(ctx, "set", iqId);
  IF from # NIL THEN
    Strophe.xmpp_stanza_set_from(iq, from)
  END;
  Strophe.xmpp_stanza_set_to(iq, to);

  pubsub := Strophe.xmpp_stanza_new(ctx);
  Strophe.xmpp_stanza_set_name(pubsub, "pubsub");
  Strophe.xmpp_stanza_set_ns(pubsub, "http://jabber.org/protocol/pubsub");

  publish := Strophe.xmpp_stanza_new(ctx);
  Strophe.xmpp_stanza_set_name(publish, "publish");
  Strophe.xmpp_stanza_set_attribute(publish, "node", "urn:xmpp:microblog:0");

  item := Strophe.xmpp_stanza_new(ctx);
  Strophe.xmpp_stanza_set_name(item, "item");
  Strophe.xmpp_stanza_set_id(item, itemId);

  entry := Strophe.xmpp_stanza_new(ctx);
  Strophe.xmpp_stanza_set_name(entry, "entry");
  Strophe.xmpp_stanza_set_ns(entry, "http://www.w3.org/2005/Atom");

  title := CreateItem(ctx, "title", text);
  Strophe.xmpp_stanza_set_type(title, "text");

  (* XEP-0277 tag URI: tag:<domain>,<date>:posts-<id> *)
  Strings.Concat("tag:", domain, tag1);
  Strings.Concat(tag1, ",", tag2);
  Strings.Concat(tag2, today, tag1);
  Strings.Concat(tag1, ":posts-", tag2);
  Strings.Concat(tag2, idText, atom);
  aid := CreateItem(ctx, "id", atom);

  published := CreateItem(ctx, "published", nowIso);
  updated := CreateItem(ctx, "updated", nowIso);

  Strophe.xmpp_stanza_add_child(entry, title);
  Strophe.xmpp_stanza_add_child(entry, aid);
  Strophe.xmpp_stanza_add_child(entry, published);
  Strophe.xmpp_stanza_add_child(entry, updated);
  Strophe.xmpp_stanza_add_child(item, entry);
  Strophe.xmpp_stanza_add_child(publish, item);
  Strophe.xmpp_stanza_add_child(pubsub, publish);
  Strophe.xmpp_stanza_add_child(iq, pubsub);

  Strophe.xmpp_stanza_release(updated);
  Strophe.xmpp_stanza_release(published);
  Strophe.xmpp_stanza_release(aid);
  Strophe.xmpp_stanza_release(title);
  Strophe.xmpp_stanza_release(entry);
  Strophe.xmpp_stanza_release(item);
  Strophe.xmpp_stanza_release(publish);
  Strophe.xmpp_stanza_release(pubsub);

  RETURN iq
END Build;

END Pep.
