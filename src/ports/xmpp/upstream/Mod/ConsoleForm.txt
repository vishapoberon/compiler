MODULE XmppConsoleForm;
(**
	project	= "Xmpp"
	organization	= ""
	contributors	= ""
	version	= "System/Rsrc/About"
	copyright	= "Kushnir Piotr Michailovich"
	license	= "Docu/BB-License"
	purpose	= "????? ???????, ???????? ? ????????? ??????????? ?????? ??? ????????????? ? ??????????? ??"
	changes	= "
	- 20130617, pk, ????????????? ?????????
"
	issues	= ""
**)
	
	IMPORT
		Core:=XmppCore, XmppConsole,
		DS:=StringsDyn, AbfBus,
		Views, Windows, FormViews, FormModels, StdCmds, TextModels, Controllers, Dialog, Stores, TextMappers, Ports, Models, Properties;
		
		
	CONST 
		minVersion = 2; maxVersion = 2;
		user = -1; clear = 0;
		title = '??????? XMPP';
		
	TYPE
		DynString = DS.DynString;
		String = ARRAY OF CHAR;
		
		UpdateMsg = RECORD (Views.Message)
			type : INTEGER;
			session : Core.Session;
			in, out : DynString;
		END;
		
		View = POINTER TO RECORD (Views.View)
			inner: Views.View;	(* v # NIL *)
			session : Core.Session;
		END;	
		
		Console = POINTER TO RECORD (XmppConsole.Console) END;
		
	VAR 
		out* : ARRAY 2048 OF CHAR;
	
(********************************************************************************)
	PROCEDURE Wrap(v : Views.View; session : Core.Session);
		VAR w: View; replace: Controllers.ReplaceViewMsg;
	BEGIN
		IF (v # NIL) & ~(v IS View) THEN
			NEW(w); w.inner := v; w.session:=session; Stores.Join(w, w.inner);
			replace.old := v; replace.new := w;
			Controllers.Forward(replace);
		ELSE Dialog.Beep
		END
	END Wrap;

	PROCEDURE Unwrap;
		VAR poll: Controllers.PollOpsMsg; replace: Controllers.ReplaceViewMsg;
	BEGIN
		Controllers.PollOps(poll);
		IF (poll.singleton # NIL) & (poll.singleton IS View) THEN
			replace.old := poll.singleton; replace.new := poll.singleton(View).inner;
			Controllers.Forward(replace)
		ELSE Dialog.Beep
		END
	END Unwrap;
	
	PROCEDURE (c: Console) ConnectTo(session : Core.Session);
	VAR v : Views.View; win : Windows.Window; form : FormViews.View; rd : FormModels.Reader; ok : BOOLEAN; t : Views.Title;
	BEGIN
		win:=Windows.dir.First();
		WHILE win#NIL DO win.GetTitle(t); IF t$=title THEN win.Close; win:=NIL; ELSE win:=Windows.dir.Next(win); END;END;
		StdCmds.OpenAuxDialog('Xmpp/Rsrc/Console',title);
		form:=Windows.dir.First().doc.OriginalView()(FormViews.View);
		rd:=form.ThisModel().NewReader(NIL); rd.Set(NIL); ok:=FALSE;
		rd.ReadView(v);
		WHILE (v#NIL)&~ok DO
			rd.Set(v);
			IF (v.ThisModel()#NIL)&(v.ThisModel() IS TextModels.Model) THEN Wrap(v, session); ok:=TRUE; END;
			rd.ReadView(v);
		END;
	END ConnectTo;
	
	PROCEDURE Update(m : TextModels.Model);
	VAR win : Windows.Window; t : Views.Title;
	BEGIN
		win:=Windows.dir.First(); 
		WHILE (win#NIL) DO
			win.GetTitle(t);
			IF (t$=title) THEN 
				win.Update;
			END;					
			win:=Windows.dir.Next(win);
		END;
	END Update;
	
	PROCEDURE Map(m : TextModels.Model; text : DynString; type : INTEGER);
	VAR f : TextMappers.Formatter; a : TextModels.Attributes; 
		
		PROCEDURE Write;
		VAR i, j, level : INTEGER; tagClose : BOOLEAN;
		BEGIN
			i:=0;  level:=0; j:=0; tagClose:=FALSE;
			WHILE i<text.Length() DO
				CASE text.Char(i) OF
					0AX, 0DX, 0EX : f.WriteLn;
					|09X : f.WriteTab;
					|'<' :  IF ((i+1)<text.Length()) & ((text.Char(i+1)#0AX) OR (text.Char(i+1)#0DX)) THEN f.WriteLn END; IF ((i+1)<text.Length()) & (text.Char(i+1)='/') THEN DEC(level); tagClose:=TRUE ELSE tagClose:=FALSE; END; FOR j:=1 TO level DO f.WriteTab; END; f.WriteChar(text.Char(i));
					|'>' : f.WriteChar(text.Char(i)); IF ~tagClose&(text.Char(i-1)#'/')&(text.Char(i-1)#'?') THEN INC(level)  END; 
				ELSE 
					f.WriteChar(text.Char(i));  
				END;
				INC(i);
			END;
		END Write;
		
	BEGIN
		f.ConnectTo(m);
		NEW(a); a.InitFromProp(NIL); a:=TextModels.NewSize(a, 8*Ports.point); 
		CASE type OF
			Core.in: 
				a:=TextModels.NewColor(a, Ports.RGBColor(255,0,0)); f.rider.SetAttr(a);
				Write; f.WriteLn;  f.WriteLn;
			|Core.out: 
				a:=TextModels.NewColor(a, Ports.RGBColor(0,0,160)); f.rider.SetAttr(a);
				Write; f.WriteLn;  f.WriteLn;
			|user: 
				a:=TextModels.NewColor(a, Ports.RGBColor(0,128,64)); f.rider.SetAttr(a);
				Write; f.WriteLn;  f.WriteLn;
			|clear: m.Delete(0, m.Length()-1);
		ELSE END;	
		Update(m); 
	END Map;
	
	PROCEDURE (v: View) Internalize (VAR rd: Stores.Reader);
		VAR version: INTEGER;
	BEGIN
		rd.ReadVersion(minVersion, maxVersion, version);
		IF ~rd.cancelled THEN
			Views.ReadView(rd, v.inner)	(* generate Views.Alien if necessary *)
		END
	END Internalize;

	PROCEDURE (v: View) Externalize (VAR wr: Stores.Writer);
	BEGIN
		wr.WriteVersion(maxVersion);
		Views.WriteView(wr, v.inner)	(* handle Views.Alien if necessary *)
	END Externalize;

	PROCEDURE (v: View) CopyFromModelView (source: Views.View; model: Models.Model);
	BEGIN
		WITH source: View DO
			IF model = NIL THEN
				v.inner := Views.CopyOf(source.inner, Views.deep)
			ELSE
				v.inner := Views.CopyWithNewModel(source.inner, model)
			END
		END
	END CopyFromModelView;

	PROCEDURE (v: View) ThisModel (): Models.Model;
	BEGIN
		RETURN v.inner.ThisModel()
	END ThisModel;

	PROCEDURE (v: View) InitContext (context: Models.Context);
	BEGIN
		v.InitContext^(context);
		v.inner.InitContext(context)	(* wrapper and wrapped view share the same context *)
	END InitContext;

	PROCEDURE (v: View) Neutralize;
	BEGIN
		v.inner.Neutralize
	END Neutralize;

	(* GetNewFrame: wrapper uses standard frame *)
	(* GetBackground: wrapper has no intrinsic background color *)

	PROCEDURE (v: View) Restore (f: Views.Frame; l, t, r, b: INTEGER);
	BEGIN
		Views.InstallFrame(f, v.inner, 0, 0, 0, TRUE)	(* create and install wrapped view's frame *)
	END Restore;

	(* RestoreMarks: wrapper has no intrinsic marks, wrapped view's RestoreMarks is called by framework *)
	(* HandleModelMsg: framework performs message propagation *)
	(* HandleViewMsg: framework performs message propagation *)
	PROCEDURE (v: View) HandleViewMsg (f: Views.Frame; VAR msg: Views.Message);
	BEGIN
		WITH msg: UpdateMsg DO
				CASE msg.type OF
					Core.in : IF msg.session=v.session THEN Map(v.inner.ThisModel()(TextModels.Model), msg.in, Core.in); END;
					|Core.out : IF msg.session=v.session THEN Map(v.inner.ThisModel()(TextModels.Model), msg.out, Core.out); END;
					|user :
						v.session.Raw(msg.out.String());
						Map(v.inner.ThisModel()(TextModels.Model), msg.out, user);
					|clear : Map(v.inner.ThisModel()(TextModels.Model), msg.out, clear)
				ELSE HALT(100); END;
		ELSE
		END
	END HandleViewMsg;
	
	PROCEDURE (v: View) HandleCtrlMsg (f: Views.Frame; VAR msg: Controllers.Message; VAR focus: Views.View);
	BEGIN
			focus := v.inner	(* forward all controller messages to wrapped view *)
	END HandleCtrlMsg;

	PROCEDURE (v: View) HandlePropMsg (VAR msg: Properties.Message);
	BEGIN
		Views.HandlePropMsg(v.inner, msg)	(* forward all property messages to wrapped view *)
	END HandlePropMsg;
	
	PROCEDURE Send*;
		VAR msg : UpdateMsg;
	BEGIN
		msg.type:=user; msg.in:=DS.Create(''); msg.out:=DS.Create(out);
		Windows.dir.First().BroadcastViewMsg(msg);
		out:=''; Dialog.UpdateString(out);
	END Send;
	
	PROCEDURE Clear*;
		VAR msg : UpdateMsg;
	BEGIN
		msg.type:=clear; msg.in:=DS.Create(''); msg.out:=DS.Create('');
		Windows.dir.First().BroadcastViewMsg(msg);
	END Clear;
		
	PROCEDURE SendGuard*(VAR par : Dialog.Par);
	BEGIN
		par.disabled:=(out$='');
	END SendGuard;
	
	PROCEDURE HandleBusMsg* (VAR msg: AbfBus.Message);
	VAR viewmsg : UpdateMsg; t : Views.Title; win : Windows.Window;
	BEGIN
		WITH msg : Core.ConsoleMsg DO
			viewmsg.in:=DS.Create(msg.in);  viewmsg.out:=DS.Create(msg.out); viewmsg.session:=msg.session; 
			viewmsg.type:=msg.code;
			win:=Windows.dir.First(); 
			WHILE (win#NIL) DO
				win.GetTitle(t);
				IF (t$=title) THEN win.BroadcastViewMsg(viewmsg); win:=NIL; 
				ELSE win:=Windows.dir.Next(win); END;					
			END;
		ELSE END;
	END HandleBusMsg;
	
	PROCEDURE Init;
		VAR c: Console;
	BEGIN
		AbfBus.Subscribe("XmppConsoleForm", "XmppCore", "ConsoleMsg", FALSE);
		NEW(c);
		XmppConsole.Install(c);
	END Init;

BEGIN
	Init	
END XmppConsoleForm.