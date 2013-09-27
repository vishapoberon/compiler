MODULE extTools;
   IMPORT Args, Unix, Strings := oocOakStrings, Console, version;
(*
INCLUDEPATH = -Isrc/lib/system/gnuc/x86_64
CCOPT = -fPIC $(INCLUDEPATH) -g
CLOBERONOPTS = -fPIC $(INCLUDEPATH) -L. -L/usr/lib -lOberon -static -g
CC = cc $(CCOPT) -c
*)

VAR incPath0, incPath1, ccOpt, ccString, CFLAGS, tmp0, tmp1 : ARRAY 256 OF CHAR;

PROCEDURE Assemble*(m : ARRAY OF CHAR);
VAR cmd : ARRAY 256 OF CHAR;
cc : ARRAY 23 OF CHAR;
ext : ARRAY 5 OF CHAR;
BEGIN
COPY (ccString, cc);
Strings.Append (" -c ", cc);
COPY(cc, cmd);
Strings.Append (" ", cmd);
Strings.Append (ccOpt, cmd);
ext := ".c";
Strings.Append (ext, m);
Strings.Append(m, cmd);
Console.Ln; Console.String (cmd); Console.Ln;
Unix.system(cmd);
END Assemble;


PROCEDURE LinkMain*(VAR m : ARRAY OF CHAR; statically : BOOLEAN);
VAR lpath : ARRAY 256 OF CHAR;
cc : ARRAY 256 OF CHAR;
ccopt : ARRAY 256 OF CHAR;
cmd : ARRAY 256 OF CHAR;
ext : ARRAY 5 OF CHAR;
BEGIN
(*
gcc -g -o hello hello.c -I $RPATH/src/lib/system/gnuc/x86_64 -I. -I$RPATH -lOberon -L. -L$RPATH -static
*)
cmd := "";
cc := "";
ext := ".c";
COPY(ccString, cc);
COPY (cc, cmd);
Strings.Append(" ", cmd);
Strings.Append(m, cmd);
Strings.Append(ext, cmd);
IF statically THEN Strings.Append(" -static ", cmd) END;
Strings.Append(" -o ", cmd);
Strings.Append(m, cmd);
Strings.Append(" ", cmd);
Strings.Append(ccOpt, cmd);
Console.Ln; Console.String(cmd); Console.Ln;
Unix.system(cmd);
END LinkMain;

BEGIN

incPath0 := "src/lib/system/gnuc/x86_64 ";
incPath1 := "lib/voc/obj ";
ccOpt := " -fPIC -g -I ";
COPY (version.prefix, tmp1);
Strings.Append("/", tmp1);
Strings.Append(incPath0, tmp1);
Strings.Append(" -I ", tmp1);
Strings.Append(version.prefix, tmp1);
Strings.Append("/", tmp1);
Strings.Append(incPath1, tmp1);
Strings.Append(tmp1, ccOpt);
Strings.Append ("-lVishapOberon -L. -L", ccOpt);
Strings.Append (version.prefix, ccOpt);
Strings.Append ("/lib ", ccOpt);
Args.GetEnv("CFLAGS", CFLAGS);
Strings.Append (CFLAGS, ccOpt);
Strings.Append (" ", ccOpt);
ccString := "cc ";
(*Strings.Append (ccOpt, ccString);*)

END extTools.
