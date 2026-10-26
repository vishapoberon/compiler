MODULE XmppConst;
	CONST
		streamClose* = '</stream:stream>';
		stream_stream* = 'stream:stream';
		stream_features* = 'stream:features';
		stream_error* = 'stream:error';
		
		xmlns* = 'xmlns';
		xmlns_stream* = 'xmlns:stream';
		
		uri_streams* = 'urn:ietf:params:xml:ns:xmpp-streams';
		uri_stream* = 'http://etherx.jabber.org/streams';
		uri_sasl* = 'urn:ietf:params:xml:ns:xmpp-sasl';
		uri_bind* = 'urn:ietf:params:xml:ns:xmpp-bind';
		uri_stanzas* = 'urn:ietf:params:xml:ns:xmpp-stanzas';
		uri_tls* = 'urn:ietf:params:xml:ns:xmpp-tls';
		
		uri_session* = 'urn:ietf:params:xml:ns:xmpp-session';
		set* = 'set';
		get* = 'get';
		result* = 'result';
		error* = 'error';
		code* = 'code';
		
		version* = 'version';
		to* = 'to';
		id* = 'id';
		from* = 'from';
		xml_lang* = 'xml:lang';
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
		jabber_client* = 'jabber:client';
		
		
		DIGEST_MD5* = 'DIGEST-MD5';
		PLAIN* = 'PLAIN';
		
		sasl_nonce* = 'nonce';
		sasl_qop* = 'qop';
		sasl_charset* = 'charset';
		sasl_algorithm* = 'algorithm';
		sasl_username* = 'username';
		sasl_cnonce* = 'cnonce';
		sasl_nc* = 'nc';
		sasl_digest_uri* = 'digest-uri';
		sasl_response* = 'response';
		sasl_realm* = 'realm';
		sasl_rspauth* = 'rspauth';
		xmpp* = 'xmpp';
		
END XmppConst.