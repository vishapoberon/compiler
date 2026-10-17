MODULE xattr;
IMPORT SYSTEM, Out, StringList, Strings:= oocStrings;

TYPE
  TStringList* = StringList.TStringList;

PROCEDURE -Aincludesysxattr '#include <sys/xattr.h>';  (* Include the necessary C headers for xattr *)

PROCEDURE -listxattr(path: ARRAY OF CHAR; VAR list: ARRAY OF CHAR; size: LONGINT): LONGINT
  "listxattr(path, list, size)";
PROCEDURE -getxattr(path: ARRAY OF CHAR; name: ARRAY OF CHAR; VAR value: ARRAY OF CHAR; size: LONGINT): LONGINT
  "getxattr(path, name, value, size)";
PROCEDURE -setxattr(path: ARRAY OF CHAR; name: ARRAY OF CHAR; value: ARRAY OF CHAR; size: LONGINT; flags: LONGINT): LONGINT
  "setxattr(path, name, value, size, flags)";
PROCEDURE -removexattr(path: ARRAY OF CHAR; name: ARRAY OF CHAR): LONGINT
  "removexattr(path, name)";

(* Helper procedure to zero out the array for safety *)
PROCEDURE zeroStr*(VAR s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < LEN(s) DO
    s[i] := 0X;
    INC(i);
  END;
END zeroStr;

PROCEDURE listToTStringList(VAR list: ARRAY OF CHAR; size: LONGINT): TStringList;
VAR
  i, j: LONGINT;
  tag: StringList.TString;
  tlist: TStringList;
  tempStr: ARRAY 256 OF CHAR;
  r: LONGINT;
BEGIN
  (*
  Out.String("entered listToTStringList"); Out.Ln;
  Out.String("list='"); Out.String(list); Out.Char("'"); Out.Ln;
  *)
  (* Create a new TStringList *)
  tlist := StringList.Create();

  (* Traverse the list of null-terminated strings *)
  i := 0;
  WHILE i < size DO
    IF list[i] # 0X THEN
      j := 0;
      (* Extract the full null-terminated string into tempStr *)
      WHILE (list[i] # 0X) & (i < size) & (j < LEN(tempStr)-1) DO
        tempStr[j] := list[i];
        INC(i);
        INC(j);
      END;
      tempStr[j] := 0X;  (* Null-terminate the string *)

      (* Skip 'user.tags' immediately to prevent it from being added as a tag *)
      IF ~Strings.Equal(tempStr, "user.tags") THEN
        Out.String("Extracted tag for TStringList: '"); Out.String(tempStr); Out.String("'"); Out.Ln;

        (* Add the string to the TStringList *)
        StringList.TStringFromString(tempStr, tag);
        r := StringList.AddString(tlist, tempStr);
      (*
      ELSE
        Out.String("Skipping 'user.tags' as it is the attribute key."); Out.Ln;
      *)
      END;
    END;
    INC(i);  (* Move to the next string (past the null terminator) *)
  END;
  RETURN tlist;
END listToTStringList;

(* List the attributes of a file and convert to a TStringList *)
PROCEDURE ListAttr*(path: ARRAY OF CHAR; VAR list: ARRAY OF CHAR; size: LONGINT): TStringList;
VAR
  res: LONGINT;
BEGIN
  zeroStr(list);  (* Clear the list *)
  res := listxattr(path, list, size);  (* Call the C function to list attributes *)

  (* Check if listxattr succeeded *)
  IF res > 0 THEN
    (*Out.String("Attributes found for '"); Out.String(path); Out.String("': '"); Out.String(list); Out.String("' with length "); Out.Int(res, 0); Out.Ln;*)
    RETURN listToTStringList(list, res);  (* Convert the list to TStringList *)
  ELSE
    (*Out.String("No attributes found for '"); Out.String(path); Out.String("'"); Out.Ln;*)
    RETURN NIL;  (* Return NIL if no attributes are found *)
  END;
END ListAttr;

PROCEDURE GetAttr*(path: ARRAY OF CHAR; name: ARRAY OF CHAR; VAR value: ARRAY OF CHAR; size: LONGINT): LONGINT;
VAR
  res: LONGINT;
BEGIN
  zeroStr(value);  (* Clear the buffer to avoid leftover characters *)
  res := getxattr(path, name, value, size);

  IF res >= 0 THEN
    (* Ensure the string is null-terminated correctly *)
    IF res < LEN(value) THEN
      value[res] := 0X;
    ELSE
      value[LEN(value)-1] := 0X;  (* Protect against buffer overflow *)
    END;

    (* Debugging output to see the retrieved value *)
    (*
    Out.String("Retrieved value from getxattr: '"); Out.String(value); Out.String("' with length "); Out.Int(res, 0); Out.Ln;
    *)
  (*
  ELSE
    Out.String("File: "); Out.String(path); Out.Ln;
    Out.String("Failed to retrieve value for '"); Out.String(name); Out.String("' from getxattr. Result: "); Out.Int(res, 0); Out.Ln;
  *)
  END;

  RETURN res;
END GetAttr;

PROCEDURE SetAttr*(path: ARRAY OF CHAR; name: ARRAY OF CHAR; value: ARRAY OF CHAR; size: LONGINT; flags: LONGINT): LONGINT;
BEGIN
  (* Call the underlying C function to set the attribute *)
  RETURN setxattr(path, name, value, size, flags);
END SetAttr;

(* Remove an extended attribute *)
PROCEDURE RemoveAttr*(path: ARRAY OF CHAR; name: ARRAY OF CHAR): LONGINT;
BEGIN
  RETURN removexattr(path, name);
END RemoveAttr;

END xattr.
