MODULE XmppRegister;
	(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
	purpose	= "???????? ?????????? XEP 0077 ???????? ??????!!!
	changes	= "
	- , nn, ...
	"
	issues	= ""
	**)

	IMPORT Core := XmppCore, Items := XmlcoreItems, Const := XmppConst, Log, Stuff := XmppStuff, DS := StringsDyn, Services, Strings, Console := XmppConsole, Rand := ypkMathRandom;

	CONST
		QUERY = 'query';
		URI_REGISTER* = 'jabber:iq:register';
		REG = 'register';
		INSTRUCTIONS = 'instructions';
		showConsole =TRUE ;
		MAXFAILS = 10;

	TYPE
		DynString = DS.DynString;

		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;

		IBReg* = POINTER TO LIMITED RECORD (Core.Extension)
			valid-: BOOLEAN;
			hook: Hook;
			step: INTEGER;
			lastId: ARRAY 17 OF CHAR
		END;

		Hook* = POINTER TO ABSTRACT RECORD END;

		StdHook = POINTER TO RECORD(Hook) END;

		RegisterHook* = POINTER TO ABSTRACT RECORD END;

		StartAction = POINTER TO RECORD(Services.Action) END;
		ContinueAction = POINTER TO RECORD(Services.Action) fails: INTEGER END;

		Field* = POINTER TO LIMITED RECORD
			name-, value*: ARRAY 256 OF CHAR
		END;

		QueryIq = POINTER TO RECORD(Core.Iq) END;
		AnswerIq = POINTER TO RECORD (Core.Iq)
			instructions: POINTER TO ARRAY OF CHAR;
			list: Stuff.List
		END;

		ErrorHook = POINTER TO RECORD(Core.ErrorHook) END;

	VAR
		dir-: Directory;
		reg-: RECORD
			s-: Core.Session;
			ibr: IBReg;
			username, password: ARRAY 256 OF CHAR;
			hook: RegisterHook
		END;

	PROCEDURE (h: Hook) InitFields- (ibr: IBReg; IN instructions: ARRAY OF CHAR; fields: Stuff.List), NEW, ABSTRACT;
	PROCEDURE (h: Hook) Registered- (ibr: IBReg; IN id: ARRAY OF CHAR), NEW, ABSTRACT;

	PROCEDURE (q: QueryIq) Do (): Items.Item;
		VAR n, n1, n2, n3: Items.Item;
	BEGIN
		n := Items.New(Const.iq);
		n1 := Items.New(QUERY); n1.SetParam(Const.xmlns, URI_REGISTER);
		n.Add(n1);
		RETURN n
	END Do;

	PROCEDURE (q: QueryIq) Use (data: Items.Item), EMPTY;

	PROCEDURE (a: AnswerIq) Do (): Items.Item;
		VAR n, n1, n2, n3: Items.Item; i: INTEGER;
	BEGIN
		n := Items.New(Const.iq);
		n1 := Items.New(QUERY); n1.SetParam(Const.xmlns, URI_REGISTER);
		FOR i := 0 TO a.list.Length() - 1 DO
			n2 := Items.New(a.list.Item(i)(Field).name);
			n2.SetData(a.list.Item(i)(Field).value);
			n1.Add(n2)
		END;
		n.Add(n1);
		RETURN n
	END Do;

	PROCEDURE (a: AnswerIq) Use (data: Items.Item);
		VAR n: Items.Item; f: Field;
	BEGIN
		n := data.First(); 
		IF n#NIL THEN n := n.First(); a.list:=Stuff.CreateList(); a.instructions:=DS.Create('').String();
			WHILE n#NIL DO  (* ?????? ????? ????????*)
				IF (n#NIL) & (n.GetName()$ = INSTRUCTIONS) THEN a.instructions := n.GetData() 
				ELSIF (n.GetName()$ # 'x') THEN
					NEW(f); f.name := n.GetName()$; f.value := '';
					a.list.Add(f);	
				END;
				n := n.Next(n)
			END;
			a.type := Const.set
		END;
		
		IF a.type$ = Const.result THEN (* ?????? ????? *)

		END
	END Use;

	PROCEDURE InitFields (ibr: IBReg; aiq: AnswerIq);
		VAR ok: BOOLEAN; i: INTEGER;
	BEGIN
		ASSERT(ibr.hook # NIL, 20);
		ibr.hook.InitFields(ibr, aiq.instructions, aiq.list);
		ok := TRUE;
		FOR i := 0 TO aiq.list.Length() - 1 DO
			ok := aiq.list.Item(i)(Field).value # ''
		END;
		ASSERT(ok, 61)
	END InitFields;

	PROCEDURE Registered (ibr: IBReg; aiq: AnswerIq);
	BEGIN
		ASSERT(ibr.hook # NIL, 20);
		ASSERT(aiq.type$ = Const.result, 21);
		ibr.hook.Registered(ibr, aiq.id)
	END Registered;

	PROCEDURE (ibr: IBReg) Iq- (data: Items.Item; VAR res: INTEGER);
		VAR e: Items.Item; aiq: AnswerIq;
	BEGIN
		e := data.First();
		IF (e # NIL) & (e.GetParam(Const.xmlns)$ = URI_REGISTER) & (data.GetParam(Const.id)$ = ibr.lastId$) & (data.NofItems() = 1) THEN
			CASE ibr.step OF
				0: NEW(aiq); aiq.Init(data); InitFields(ibr, aiq); ibr.owner.Send(aiq); ibr.step := 1
			|1: NEW(aiq); aiq.Init(data); Registered(ibr, aiq); ibr.lastId := ''; ibr.step := - 1
			ELSE END
		ELSIF (e = NIL) & (data.GetParam(Const.type)$ = Const.result) & (data.GetParam(Const.id)$ = ibr.lastId$) THEN
			NEW(aiq); aiq.Init(data); Registered(ibr, aiq); ibr.lastId := ''; ibr.step := - 1
		END;
		res := Core.continue
	END Iq;

	PROCEDURE (ibr: IBReg) SetHook* (h: Hook), NEW;
	BEGIN
		ibr.hook := h
	END SetHook;

	PROCEDURE (ibr: IBReg) Start-;
	BEGIN
		ibr.valid := reg.s.HasFeature('register', '*')
	END Start;

	PROCEDURE (ibr: IBReg) Stop-;
	BEGIN
		ibr.valid := FALSE
	END Stop;

	PROCEDURE Query* (ibr: IBReg; OUT id: ARRAY OF CHAR);
		VAR qiq: QueryIq;
	BEGIN
		NEW(qiq);
		Rand.UniRandStr(id, 5); id := REG + '_' + id$;
		qiq.Set('', '', '', id, Const.get);
		ibr.step := 0; ibr.lastId := id$;
		ibr.owner.Send(qiq)
	END Query;

	PROCEDURE (d: Directory)Create- (session: Core.Session): Core.Extension;
		VAR ibr: IBReg;
	BEGIN
		NEW(ibr);
		ibr.valid := FALSE;
		ibr.step := - 1;
		RETURN ibr
	END Create;

	(** ??????? ???????????, ????????? ????????????? ????????? **)
	PROCEDURE (h: RegisterHook) Registered- (IN username, password: ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (h: RegisterHook) NeedField- (IN name: ARRAY OF CHAR; OUT value: ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (h: RegisterHook) Failed- (IN error: ARRAY OF CHAR), NEW, ABSTRACT;

	PROCEDURE NeedField (IN name: ARRAY OF CHAR; OUT value: ARRAY OF CHAR);
	BEGIN
		ASSERT(reg.hook # NIL, 20);
		reg.hook.NeedField(name, value);
		ASSERT(value # '', 60)
	END NeedField;

	PROCEDURE Failed (msg: ARRAY OF CHAR);
	BEGIN
		reg.s.CloseStream;
		reg.username := ''; reg.password := '';
		reg.hook.Failed(msg)
	END Failed;

	PROCEDURE (h: StdHook) InitFields (ibr: IBReg; IN instruction: ARRAY OF CHAR; fields: Stuff.List);
		VAR i: INTEGER;
	BEGIN
		FOR i := 0 TO fields.Length() - 1 DO
			IF fields.Item(i)(Field).name = 'username' THEN fields.Item(i)(Field).value := reg.username$
			ELSIF fields.Item(i)(Field).name = 'password' THEN fields.Item(i)(Field).value := reg.password$
			ELSE NeedField(fields.Item(i)(Field).name, fields.Item(i)(Field).value) END
		END
	END InitFields;

	PROCEDURE (h: StdHook) Registered- (ibr: IBReg; IN id: ARRAY OF CHAR);
	BEGIN
		reg.s.CloseStream;
		IF reg.hook # NIL THEN
			reg.hook.Registered(reg.username, reg.password)
		END;
		reg.username := ''; reg.password := ''; reg.hook := NIL
	END Registered;

	PROCEDURE (h: ErrorHook) Error (session: Core.Session; data: Core.Error);
	BEGIN
		reg.s.CloseStream;
		IF reg.hook # NIL THEN
			Failed(data.type)
		END
	END Error;

	PROCEDURE (a: StartAction) Do;
		VAR ca: ContinueAction; eh: ErrorHook;
	BEGIN
		IF reg.s.StreamFeatures() = NIL THEN
			reg.s.StartStream;
			NEW(eh); reg.s.SetErrorHook(eh);
			NEW(ca); ca.fails := 0; Services.DoLater(ca, Services.Ticks() + 250)
		END
	END Do;

	PROCEDURE (a: ContinueAction) Do;
		VAR id: ARRAY 17 OF CHAR; res: INTEGER; ibh: StdHook;
	BEGIN
		IF reg.s.StreamFeatures() # NIL THEN
			reg.ibr := reg.s.LoadExtension('XmppRegister', res)(IBReg);
			ASSERT(res = Core.loaded);
			NEW(ibh); reg.ibr.SetHook(ibh);
			reg.ibr.valid := reg.s.HasFeature(REG, '*');
			IF reg.ibr.valid THEN
				Query(reg.ibr, id)
			ELSE Failed('not supported') END
		ELSIF a.fails < MAXFAILS THEN Services.DoLater(a, Services.Ticks() + 250); INC(a.fails)
		ELSE Failed('invalid stream') END
	END Do;

	PROCEDURE Register* (remoteAdr, username, server, password: ARRAY OF CHAR; regHook: RegisterHook);
		VAR a: StartAction; res: INTEGER;
	BEGIN
		reg.s := Core.dir.NewSession(remoteAdr, username$ + '@' + server, password, {Core.noAuth});
		Core.dir.Start(reg.s, res);
		reg.username := username$; reg.password := password$; reg.hook := regHook;
		NEW(a); Services.DoLater(a, Services.Ticks() + 200);
		IF showConsole THEN Console.Open(reg.s) END
	END Register;

	PROCEDURE Init;
		VAR d: Directory;
	BEGIN
		NEW(d);
		dir := d;
		reg.username := ''; reg.password := ''; reg.hook := NIL; reg.s := NIL; reg.ibr := NIL
	END Init;

BEGIN
	Init
END XmppRegister.