MODULE TestListLinks;
IMPORT List, StringList, Out;
VAR l: List.TList;
    a, b, c: List.TObject;
    node: List.Node;
    strings: StringList.TStringList;
    values: StringList.pstrings;
    value: StringList.pstring;
    index: LONGINT;

PROCEDURE Check;
VAR node, prev: List.Node; count: LONGINT;
BEGIN
  node := l.First; prev := NIL; count := 0;
  WHILE node # NIL DO
    ASSERT(node.prev = prev); prev := node; node := node.next; INC(count);
    ASSERT(count <= l.Count)
  END;
  ASSERT(count = l.Count); ASSERT(prev = l.Last);
  IF l.First # NIL THEN ASSERT(l.First.prev = NIL); ASSERT(l.Last.next = NIL) END
END Check;

BEGIN
  l := List.Create(); NEW(a); NEW(b); NEW(c);
  l.Insert(l, 0, a); Check;
  l.Insert(l, 0, b); Check;
  l.Insert(l, 1, c); Check;
  node := l.Get(l, 1); ASSERT(node.obj = c);
  l.Insert(l, -1, c); ASSERT(~l.res); Check;
  l.Insert(l, 4, c); ASSERT(~l.res); Check;
  l.Delete(l, 0); Check; ASSERT(l.First.obj = c);
  l.Delete(l, 1); Check; ASSERT(l.Last.obj = c);
  l.Delete(l, 0); Check; ASSERT(l.Empty(l));
  l.AppendList(l, l); Check;
  index := l.Add(l, a); ASSERT(index = 0);
  l.AppendList(l, l); Check; ASSERT(l.Count = 2);
  node := l.First; ASSERT(l.DeleteNode(l, node)); Check;
  ASSERT(~l.DeleteNode(l, node)); Check;
  ASSERT(l.DeleteNode(l, l.Last)); Check;
  strings := StringList.Create();
  StringList.StringListTopstrings(strings, values); ASSERT(values = NIL);
  value := strings.GetString(strings, 0); ASSERT(value = NIL);
  strings.AppendString(strings, 'a'); strings.AppendString(strings, 'b');
  ASSERT(strings.IndexOf(strings, 'b') = 1);
  strings.Delete(strings, 1); strings.AppendString(strings, 'c');
  value := strings.GetString(strings, 1); ASSERT(value^ = 'c');
  StringList.StringListTopstrings(strings, values);
  ASSERT(LEN(values^) = 2); ASSERT(values[0]^ = 'a'); ASSERT(values[1]^ = 'c');
  Out.String('list link tests passed'); Out.Ln
END TestListLinks.
