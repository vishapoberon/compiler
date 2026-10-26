MODULE XmppStdBus;
(**	project	= "Xmpp"
	organization	= ""
	contributors	= ""
 	purpose	= ""
	changes	= "
	- , nn, ...
	"
	issues	= ""
	selectors	= ????
**)
	
	IMPORT SYSTEM, Bus:=XmppBus, Meta, Kernel, Strings, DS:=StringsDyn, Items:=XmlcoreItems, Md5:=ypkCryptMd5, Services, (* SternMeta, *) Const:=XmppConst, Log;
		
	TYPE
		StdConv = POINTER TO RECORD(Bus.Converter) END; 
		DynString = DS.DynString;
	
	VAR
		strval: RECORD(Meta.Value) p*: POINTER TO ARRAY OF CHAR END; 
		sstrval: RECORD(Meta.Value) p*: POINTER TO ARRAY OF SHORTCHAR END;
		ival: RECORD(Meta.Value) p*: POINTER TO ARRAY OF INTEGER END; 
		lival: RECORD(Meta.Value) p*: POINTER TO ARRAY OF LONGINT END; 
		bval: RECORD(Meta.Value) p*: POINTER TO ARRAY OF BYTE END; 
		sival: RECORD(Meta.Value) p*: POINTER TO ARRAY OF SHORTINT END; 
		rval: RECORD(Meta.Value) p*: POINTER TO ARRAY OF REAL END; 
		srval: RECORD(Meta.Value) p*: POINTER TO ARRAY OF SHORTREAL END; 
		sval: RECORD(Meta.Value) p*: POINTER TO ARRAY OF SET END; 
		
					
	PROCEDURE LookupItem (VAR r: ANYREC; OUT i: Meta.Item);
	VAR type: Kernel.Type; mod: Kernel.Module; attr: Kernel.ItemAttr;
	BEGIN	(* create a meta item for a global variable passed as VAR parameter *)
		attr.obj := Meta.varObj;
		attr.typ := Meta.recTyp;
		attr.vis := Meta.exported;
		attr.adr := SYSTEM.ADR(r);
		attr.mod := NIL;
		attr.desc := SYSTEM.VAL(Kernel.Type, SYSTEM.TYP(r));
		attr.ptr := NIL;
		attr.ext := NIL;
		attr.mod := NIL;
		Meta.GetThisItem(attr, i)
	END LookupItem;	
	
	PROCEDURE GetTypeFp(VAR x : ANYREC; OUT fprint : ARRAY OF CHAR);
	VAR mod, name : ARRAY 127 OF CHAR; res : INTEGER; m : Kernel.Module; type : Kernel.Type;
	BEGIN
		(* Strings.Find(type, '.', 0, res);
		Strings.Extract(type, 0, res, mod); Strings.Extract(type, res+1, LEN(type$), name);
		m:=Kernel.ThisMod(mod);
		desc:=Kernel.ThisObject(m, SHORT(name));
		Strings.IntToString(desc.fprint+desc.offs, fprint); *)
		type:=Kernel.TypeOf(x);
		Strings.IntToString(type.size*type.id, fprint);
	END GetTypeFp;
		
	PROCEDURE (c : StdConv) MsgToItem(VAR msg : Bus.Message; OUT x : Items.Item);
	VAR name, summ : ARRAY 127 OF CHAR; y: Items.Item; item : Meta.Item;  hash : Md5.Hash; i : INTEGER; fnum, str : ARRAY 127 OF CHAR;
		
			PROCEDURE Inc(OUT s : ARRAY OF CHAR);
			BEGIN
				INC(i);
				Strings.IntToString(i, s);
				s:=Bus.fTyp+'-'+s;
			END Inc;
		
			PROCEDURE Scan(root : Items.Item; x : Meta.Item);
			VAR rec, arr : Items.Item; y : Meta.Item; sc : Meta.Scanner; i, j : INTEGER; ds : DynString; ch : CHAR; mod, name: Meta.Name;
			BEGIN
				ds:=DS.Create('');
				IF x.vis=Meta.exported THEN
					CASE x.typ OF 
						Meta.anyRecTyp, Meta.anyPtrTyp : 
						|Meta.recTyp: 
							rec:=Items.New(Bus.recTyp); root.Add(rec); 
							sc.ConnectTo(x); sc.Scan;
							WHILE ~sc.eos DO
								IF sc.this.Valid() THEN Scan(rec, sc.this) END;
								sc.Scan;
							END;
						|Meta.arrTyp: 
							arr:=Items.New(Bus.arrTyp); root.Add(arr);
							arr.SetIntParam(Const.type, x.BaseTyp());
							arr.SetIntParam(Bus.len, x.Len());
							CASE x.BaseTyp() OF
								Meta.recTyp, Meta.arrTyp, Meta.ptrTyp: 
									FOR i:=0 TO x.Len()-1 DO x.Index(i, y); IF y.Valid() THEN Scan(arr, y) END END;
								|Meta.sCharTyp, Meta.charTyp : 
									ds:=DS.Create(''); ch:=1X;
									WHILE (i < x.Len()) & (ch#0X) DO x.Index(i, y); IF y.Valid() THEN ch:=y.CharVal(); ds.AddChar(ch) END; INC(i) END;
									arr.SetData(ds.String());
								|Meta.boolTyp:
									ds:=DS.Create('(');
									FOR i:=0 TO x.Len()-1 DO x.Index(i, y); 
									IF y.Valid() THEN 
										IF y.BoolVal() THEN ds.AddString('true') ELSE ds.AddString('false') END;
										IF i<x.Len()-1 THEN ds.AddChar(',') END;
									END END;
									ds.AddChar(')');
									arr.SetData(ds.String());
								|Meta.byteTyp, Meta.sIntTyp, Meta.intTyp:
									ds:=DS.Create('(');
									FOR i:=0 TO x.Len()-1 DO x.Index(i, y); 
									IF y.Valid() THEN 
										Strings.IntToString(y.IntVal(), str); ds.AddString(str);
										IF i<x.Len()-1 THEN ds.AddChar(',') END;
									END END;
									ds.AddChar(')');
									arr.SetData(ds.String());
								|Meta.longTyp:
									ds:=DS.Create('(');
									FOR i:=0 TO x.Len()-1 DO x.Index(i, y); 
									IF y.Valid() THEN 
										Strings.IntToString(y.LongVal(), str); ds.AddString(str);
										IF i<x.Len()-1 THEN ds.AddChar(',') END;
									END END;
									ds.AddChar(')');
									arr.SetData(ds.String());
								|Meta.sRealTyp, Meta.realTyp:
									ds:=DS.Create('(');
									FOR i:=0 TO x.Len()-1 DO x.Index(i, y); 
									IF y.Valid() THEN 
										Strings.RealToString(y.RealVal(), str); ds.AddString(str);
										IF i<x.Len()-1 THEN ds.AddChar(',') END;
									END END;
									ds.AddChar(')');
									arr.SetData(ds.String());
								|Meta.setTyp:
									ds:=DS.Create('(');
									FOR i:=0 TO x.Len()-1 DO x.Index(i, y); 
									IF y.Valid() THEN 
										ds.AddChar('{');
										FOR j:=0 TO 32 DO 
											IF (j IN y.SetVal()) THEN 
												Strings.IntToString(j, str); ds.AddString(str);
												IF j<31 THEN ds.AddChar(',') END;
											END;
										END;
										ds.AddChar('}');
										IF i<x.Len()-1 THEN ds.AddChar(',') END;
									END END;
									ds.AddChar(')');
									arr.SetData(ds.String());
							ELSE END; 
						|Meta.ptrTyp: 
							x.GetTypeName(mod, name);
							IF mod$+'.'+name$ = 'XmlcoreItems.Item' THEN
								rec:=Items.New(Bus.special);
								IF x.Valid() THEN rec.Add(x.PtrVal()(Items.Item)) END;
								root.Add(rec); 
							ELSE
								x.Deref(y); 
								Scan(root, y)
							END; 
						|Meta.boolTyp: root.SetBoolParam(fnum$, x.BoolVal());
						|Meta.sCharTyp, Meta.charTyp : 
							Strings.IntToString(ORD(x.CharVal()), str); str:=str$+'X'+0X; 
							IF str#'' THEN root.SetParam(fnum$, str) END;
						|Meta.byteTyp, Meta.sIntTyp, Meta.intTyp: root.SetIntParam(fnum$, x.IntVal());
						|Meta.longTyp: Strings.IntToString(x.LongVal(), str); root.SetParam(fnum$, str);
						|Meta.sRealTyp, Meta.realTyp: Strings.RealToString(x.RealVal(), str); root.SetParam(fnum$, str);
						|Meta.setTyp:
							ds.AddChar('{'); j:=0;
							WHILE j<32 DO 
								IF (j IN x.SetVal()) THEN Strings.IntToString(j, str); 
									IF j>0 THEN ds.AddChar(',') END;
									ds.AddString(str); 
								END;
								INC(j);
							END;
							ds.AddChar('}');
							root.SetParam(fnum$, ds.String());
					ELSE END;	
					Inc(fnum);
				END;
			END Scan;
	
	BEGIN
		x:=Items.New(Bus.message);
		msg.Fill(y);
		IF y=NIL THEN
			Services.GetTypeName(msg, name);
			x.SetParam(Const.type, name);
			LookupItem(msg, item);
			IF item.Valid() THEN 
				i:=0; Inc(fnum);
				Scan(x, item);
				(* SternMeta.Md5Hash (item, hash);
				summ:=hash$;
				x.SetParam(Bus.md5summ, summ);*)
				GetTypeFp(msg, str);
				x.SetParam(Bus.fprint, str);
			END
		ELSE
			x.SetParam(Const.type, Bus.special);
			x.Add(y);
		END;
	END MsgToItem;
	
	PROCEDURE (c : StdConv) ItemToMsg(item : Items.Item; VAR msg : Bus.MsgPtr; res : INTEGER);
	VAR name, summ : ARRAY 127 OF CHAR; this : Meta.Item; x : ANYPTR; hash : Md5.Hash; i : INTEGER; fnum, fp : ARRAY 127 OF CHAR; al : Bus.Alien; sp : Bus.Special;
		
			PROCEDURE Inc(OUT s : ARRAY OF CHAR);
			BEGIN
				INC(i);
				Strings.IntToString(i, s);
				s:=Bus.fTyp+'-'+s;
			END Inc;
			
			PROCEDURE Prepare(root: Items.Item; VAR ptr, base: Meta.Item);
				VAR len: INTEGER; ok: BOOLEAN;
			BEGIN
				IF (root#NIL) & (root.GetData()#NIL) THEN len:=LEN(root.GetData()$) ELSE len:=1 END;
				CASE base.typ OF
					|Meta.arrTyp: 
						CASE base.BaseTyp() OF
							|Meta.arrTyp, Meta.recTyp, Meta.ptrTyp: HALT(100); (* not possible to propogate *)
							|Meta.sCharTyp:
								NEW(sstrval.p, len+1);
								ptr.PutVal(sstrval, ok);
								ASSERT(ok, 61);
							|Meta.charTyp:
								NEW(strval.p, len+1);
								ptr.PutVal(strval, ok);
								ASSERT(ok, 61);
							|Meta.byteTyp:
								ok:=root.GetIntParam(Bus.len, len);
								ASSERT(ok, 60);
								NEW(bval.p, len);
								ptr.PutVal(bval, ok);
								ASSERT(ok, 61);
							|Meta.sIntTyp:
								ok:=root.GetIntParam(Bus.len, len);
								ASSERT(ok, 60);
								NEW(sival.p, len);
								ptr.PutVal(sival, ok);
								ASSERT(ok, 61);
							|Meta.intTyp:
								ok:=root.GetIntParam(Bus.len, len);
								ASSERT(ok, 60);
								NEW(ival.p, len);
								ptr.PutVal(ival, ok);
								ASSERT(ok, 61);	
							|Meta.longTyp:
								ok:=root.GetIntParam(Bus.len, len);
								ASSERT(ok, 60);
								NEW(lival.p, len);
								ptr.PutVal(lival, ok);
								ASSERT(ok, 61);
							|Meta.sRealTyp:
								ok:=root.GetIntParam(Bus.len, len);
								ASSERT(ok, 60);
								NEW(srval.p, len);
								ptr.PutVal(srval, ok);
								ASSERT(ok, 61);
							|Meta.realTyp:
								ok:=root.GetIntParam(Bus.len, len);
								ASSERT(ok, 60);
								NEW(rval.p, len);
								ptr.PutVal(rval, ok);
								ASSERT(ok, 61);
							|Meta.setTyp:
								ok:=root.GetIntParam(Bus.len, len);
								ASSERT(ok, 60);
								NEW(sval.p, len);
								ptr.PutVal(sval, ok);
								ASSERT(ok, 61);
						END;
					|Meta.recTyp: ptr.PutPtrVal(ptr.New());
					|Meta.ptrTyp:
				ELSE END;
			END Prepare;
			 	
			PROCEDURE Scan(root : Items.Item; x : Meta.Item);
				VAR this: Items.Item; y, z : Meta.Item; sc : Meta.Scanner; i, j, typ, res, idx : INTEGER; l : LONGINT; r : REAL; ds: DS.DynString; s0: POINTER TO ARRAY OF CHAR; bool : BOOLEAN; str, str2 : ARRAY 127 OF CHAR; s: SET;  mod, name: Meta.Name;
						
			BEGIN
				IF x.vis=Meta.exported THEN
					CASE x.typ OF 
						Meta.anyRecTyp, Meta.anyPtrTyp : 
						|Meta.recTyp: 
							ASSERT(root.GetName()$=Bus.recTyp);
							sc.ConnectTo(x); this:=root.First(); sc.Scan;
							WHILE ~sc.eos DO 
								IF sc.this.typ IN {Meta.recTyp, Meta.arrTyp, Meta.ptrTyp} THEN sc.this.GetBaseType(y) END;
								IF (sc.this.typ IN {Meta.recTyp, Meta.arrTyp}) THEN Scan(this, sc.this); this:=root.Next(this)
								ELSIF (sc.this.typ = Meta.ptrTyp) & (y.typ = Meta.arrTyp) THEN
									z:=sc.this;
									Prepare(this, z, y);
									Scan(this, z); 
									this:=root.Next(this);
								ELSIF (sc.this.typ = Meta.ptrTyp) & (y.typ = Meta.recTyp) THEN
									Scan(this, sc.this);
								ELSE Scan(root, sc.this) END;  
								sc.Scan; 
							END;
						|Meta.arrTyp: 
							ASSERT(root.GetName()$=Bus.arrTyp);
							ASSERT(root.GetIntParam(Const.type, typ));
							ASSERT(typ=x.BaseTyp());
							CASE x.BaseTyp() OF
								Meta.recTyp, Meta.arrTyp, Meta.ptrTyp:
									this:=root.First();
									FOR i:=0 TO x.Len()-1 DO x.Index(i, y); IF y.Valid() THEN Scan(this, y); this:=root.Next(this)  END END;
								|Meta.sCharTyp, Meta.charTyp: 
									ds:=DS.Create(root.GetData()); ds.AddChar(0X);
									FOR i:=0 TO MIN(x.Len(), ds.Length()-1) DO 
										x.Index(i, y); 
										IF y.Valid() THEN y.PutCharVal(ds.Char(i)) END 
									END;
								|Meta.byteTyp, Meta.sIntTyp, Meta.intTyp:
									s0:=root.GetData(); i:=1; idx:=0; str:='';
									WHILE s0[i]#0X DO
										IF (s0[i]=',') OR (s0[i]=')') THEN
											str[LEN(str$)+1]:=0X;
											Strings.StringToInt(str$, j, res);
											ASSERT(res=0);
											x.Index(idx, y); INC(idx);
											y.PutIntVal(j);
											str:='';
										ELSE res:=LEN(str$); str[res]:=s0[i]; str[res+1]:=0X; END; 
										INC(i);
									END;
								|Meta.longTyp:
									s0:=root.GetData(); i:=1;  idx:=0; str:='';
									WHILE s0[i]#0X DO
										IF (s0[i]=',') OR (s0[i]=')') THEN
											Strings.StringToLInt(str, l, res);
											ASSERT(res=0);
											x.Index(idx, y); INC(idx);
											y.PutLongVal(l);
											str:='';
										ELSE res:=LEN(str$); str[res]:=s0[i]; str[res+1]:=0X; END; 
										INC(i);
									END;
								|Meta.sRealTyp, Meta.realTyp:
									s0:=root.GetData(); i:=1;  idx:=0; str:='';
									WHILE s0[i]#0X DO
										IF (s0[i]=',') OR (s0[i]=')') THEN
											Strings.StringToReal(str, r, res);
											ASSERT(res=0);
											x.Index(idx, y); INC(idx);
											y.PutRealVal(r);
											str:='';
										ELSE res:=LEN(str$); str[res]:=s0[i]; str[res+1]:=0X; END; 
										INC(i);
									END;
								|Meta.setTyp:
									s0:=root.GetData(); i:=1;  idx:=0; str:='';
									WHILE s0[i]#0X DO
										IF (s0[i]=',') OR (s0[i]=')') THEN
											s:={};
											FOR j:=0 TO MAX(SET) DO
												Strings.IntToString(j, str2);
												Strings.Find(str, str2, 0, res);
												IF res>=0 THEN INCL(s, j) END;
											END;
											x.Index(idx, y); INC(idx);
											y.PutSetVal(s);
											str:='';
										ELSE res:=LEN(str$); str[res]:=s0[i]; str[res+1]:=0X; END; 
										INC(i);
									END;
							ELSE END; 
						|Meta.ptrTyp:
							x.GetTypeName(mod, name);
							IF mod$+'.'+name$ = 'XmlcoreItems.Item' THEN
								this:=root.First().Copy();
								IF x.Valid() & (this#NIL) THEN x.PutPtrVal(this) END; 
							ELSE
								x.Deref(y);
								Scan(root, y);
							END;	
						|Meta.boolTyp: 
							ASSERT(root.GetBoolParam(fnum, bool));
							x.PutBoolVal(bool);
						|Meta.sCharTyp, Meta.charTyp : 
							str:=root.GetParam(fnum)$;
							Strings.Extract(str$, 0, LEN(str$)-1, str);
							Strings.StringToInt(str, i, res);
							ASSERT(res=0);
							x.PutCharVal(CHR(i));
						|Meta.byteTyp, Meta.sIntTyp, Meta.intTyp: 
							str:=root.GetParam(fnum)$;
							Strings.StringToInt(str, i, res);
							ASSERT(res=0);
							x.PutIntVal(i);
						|Meta.longTyp: 
							str:=root.GetParam(fnum)$;
							Strings.StringToLInt(str, l, res);
							ASSERT(res=0);
							x.PutLongVal(l);
						|Meta.sRealTyp, Meta.realTyp: 
							str:=root.GetParam(fnum)$;
							Strings.StringToReal(str, r, res);
							ASSERT(res=0);
							x.PutRealVal(r);
						|Meta.setTyp:
							str:=root.GetParam(fnum)$; s:={};
							FOR j:=0 TO MAX(SET) DO
								Strings.IntToString(j, str2);
								Strings.Find(str, str2, 0, res);
								IF res>=0 THEN INCL(s, j) END;
							END;
							x.PutSetVal(s);
					ELSE END;	
					Inc(fnum);
				END;
			END Scan;
	BEGIN
		name:=item.GetParam(Const.type)$;
		Meta.LookupPath(name, this);
		IF this.Valid() THEN
			x:=this.New();
			ASSERT(x#NIL);
			msg:=x(Bus.MsgPtr);
			LookupItem(msg, this);
			i:=0; Inc(fnum);
			GetTypeFp(msg, fp);
			IF fp$=item.GetParam(Bus.fprint)$ THEN
				Scan(item.First(), this);
				(* SternMeta.Md5Hash (this, hash);
				summ:=hash$;
				ASSERT(summ$ = item.GetParam(Bus.md5summ)$); *)
				res:=Bus.normal;			
			ELSE
				NEW(al); al.data:=item;
				msg:=al;
				Log.String('[xmpp-bus] alien bus message, unknown module item '+name$);
				res:=Bus.alien;
			END
		ELSE
			NEW(al); al.data:=item;
			msg:=al;
			res:=Bus.alien;
		END;
	END ItemToMsg;
	
	PROCEDURE InstallConv*;
	VAR c : StdConv;
	BEGIN
		NEW(c);
		Bus.SetConv(c)
	END InstallConv;
	
END XmppStdBus.