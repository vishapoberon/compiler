MODULE XmppConst;

CONST
  streamClose* = '</stream:stream>';
  streamStream* = 'stream:stream';
  streamFeatures* = 'stream:features';
  streamError* = 'stream:error';

  xmlns* = 'xmlns';
  xmlnsStream* = 'xmlns:stream';

  uriStreams* = 'urn:ietf:params:xml:ns:xmpp-streams';
  uriStream* = 'http://etherx.jabber.org/streams';
  uriSasl* = 'urn:ietf:params:xml:ns:xmpp-sasl';
  uriBind* = 'urn:ietf:params:xml:ns:xmpp-bind';
  uriStanzas* = 'urn:ietf:params:xml:ns:xmpp-stanzas';
  uriTls* = 'urn:ietf:params:xml:ns:xmpp-tls';

  uriSession* = 'urn:ietf:params:xml:ns:xmpp-session';
  set* = 'set';
  get* = 'get';
  result* = 'result';
  error* = 'error';
  code* = 'code';

  version* = 'version';
  to* = 'to';
  id* = 'id';
  from* = 'from';
  xmlLang* = 'xml:lang';
  type* = 'type';

  mechanisms* = 'mechanisms';
  mechanism* = 'mechanism';
  text* = 'text';
  bind* = 'bind';
  iq* = 'iq';
  message* = 'message';
  presence* = 'presence';
  session* = 'session';
  resource* = 'resource';

  auth* = 'auth';
  challenge* = 'challenge';
  response* = 'response';
  success* = 'success';
  failure* = 'failure';
  jabberClient* = 'jabber:client';

  DIGESTMD5* = 'DIGEST-MD5';
  PLAIN* = 'PLAIN';

  saslNonce* = 'nonce';
  saslQop* = 'qop';
  saslCharset* = 'charset';
  saslAlgorithm* = 'algorithm';
  saslUsername* = 'username';
  saslCnonce* = 'cnonce';
  saslNc* = 'nc';
  saslDigestUri* = 'digest-uri';
  saslResponse* = 'response';
  saslRealm* = 'realm';
  saslRspauth* = 'rspauth';
  xmpp* = 'xmpp';

END XmppConst.
