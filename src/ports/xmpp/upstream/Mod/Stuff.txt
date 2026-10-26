MODULE XmppStuff;
(**
	project	= "XMPP"
	organization	= ""
	contributors	= ""
	purpose	= "???????? ??????????????? ?????"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)

	IMPORT Strings, Math, Services, Kernel, SYSTEM, Lists := ListsLinear;
	
	TYPE
	
		List* = POINTER TO LIMITED RECORD
			list- : Lists.List;
		END;
		
		Item* = POINTER TO EXTENSIBLE RECORD (Lists.ListItem) 
			data- : ANYPTR;
		END;
	
	PROCEDURE (l : List) Add*(item : ANYPTR), NEW;
	VAR i : Item;
	BEGIN
		NEW(i);
		i.data:=item;
		l.list.SetLength(l.list.len+1);
		l.list.SetItem(l.list.len-1, i);
	END Add;
	
	PROCEDURE (l : List) Length*() : INTEGER, NEW;
	BEGIN
		RETURN l.list.len;
	END Length;

	PROCEDURE (l : List) Item*(idx : INTEGER) : ANYPTR, NEW;
	VAR i : ANYPTR;
	BEGIN
		ASSERT((idx>=0) & (idx<l.list.len));
		i:=l.list.GetItem(idx);
		ASSERT(i#NIL);
		RETURN i(Item).data;
	END Item;

	PROCEDURE (l : List) Remove*(item : ANYPTR), NEW;
	VAR i : INTEGER; ok : BOOLEAN;
	BEGIN
		i:=0; ok:=FALSE;
		WHILE (i<l.list.len) & ~ok DO
			ok:=(l.Item(i)=item);
			INC(i)
		END;
		DEC(i);
		IF ok THEN l.list.Remove(i) END;
	END Remove;

	PROCEDURE CreateList*():List;
	VAR l : List; 
	BEGIN
		NEW(l);
		l.list:=Lists.NewList();
		RETURN l;
	END CreateList;
END XmppStuff.