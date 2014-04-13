MODULE extTools;
   IMPORT Args, Unix, Strings, Console, version;
(*
INCLUDEPATH = -Isrc/lib/system/linux/gnuc/x86_64
CCOPT = -fPIC $(INCLUDEPATH) -g
CLOBERONOPTS = -fPIC $(INCLUDEPATH) -L. -L/usr/lib -lVishapOberon -static -g
CC = cc $(CCOPT) -c
*)
CONST compiler="clang";

VAR incPath0, incPath1, ccOpt, ccString, CFLAGS, tmp0, tmp1 : ARRAY 1023 OF CHAR;

PROCEDURE Assemble*(m : ARRAY OF CHAR);
VAR cmd : ARRAY 1023 OF CHAR;
cc : ARRAY 1023 OF CHAR;
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
(*Console.Ln; Console.String (cmd); Console.Ln;*)
Unix.system(cmd);
END Assemble;


PROCEDURE LinkMain*(VAR m : ARRAY OF CHAR; statically : BOOLEAN; additionalopts : ARRAY OF CHAR);
VAR lpath : ARRAY 1023 OF CHAR;
cc : ARRAY 1023 OF CHAR;
ccopt : ARRAY 1023 OF CHAR;
cmd : ARRAY 1023 OF CHAR;
ext : ARRAY 5 OF CHAR;
cmd2 : ARRAY 1023 OF CHAR;
BEGIN
(*
gcc -g -o hello hello.c -I $RPATH/src/lib/system/linux/gnuc/x86_64 -I. -I$RPATH -lOberon -L. -L$RPATH -static
*)
cmd := "";
cc := "";
ext := ".c";
COPY(ccString, cc);
COPY (cc, cmd);
Strings.Append(" ", cmd);
Strings.Append(m, cmd);
Strings.Append(ext, cmd);
Strings.Append(additionalopts, cmd);
Strings.Append(" ", cmd);
(*IF statically THEN Strings.Append(" -static ", cmd) END;*)
IF statically THEN 
   Strings.Append(version.prefix, cmd);
   Strings.Append("/lib/libVishapOberon.a ", cmd);
END;
Strings.Append(" -o ", cmd);
Strings.Append(m, cmd);
Strings.Append(" ", cmd);
IF ~statically THEN
Strings.Append ("-lVishapOberon -L. -L", ccOpt);
Strings.Append (version.prefix, ccOpt);
Strings.Append ("/lib ", ccOpt);
END;
Strings.Append(ccOpt, cmd);

Console.Ln; Console.String(cmd); Console.Ln; (* may be it's feasible to add debug mode later *)
Unix.system(cmd);

IF ~statically THEN
   cmd2 := "";
   COPY ("install_name_tool -change libVishapOberon.dylib ", cmd2);
   Strings.Append(version.prefix, cmd2);
   Strings.Append ("/lib/libVishapOberon.dylib ", cmd2);
   Strings.Append (m, cmd2);
   Console.String(cmd2); Console.Ln;
   Unix.system(cmd2);
   END
END LinkMain;

BEGIN

incPath0 := "src/lib/system/darwin/";
Strings.Append (compiler, incPath0);
incPath1 := "lib/voc/obj ";
ccOpt := " -fPIC -g ";

COPY ("-I ", tmp1);
Strings.Append (version.prefix, tmp1);
Strings.Append("/", tmp1);
Strings.Append(incPath0, tmp1);
Strings.Append("/", tmp1);
Strings.Append(version.arch, tmp1);
Strings.Append(" -I ", tmp1);
Strings.Append(version.prefix, tmp1);
Strings.Append("/", tmp1);
Strings.Append(incPath1, tmp1);
Strings.Append(tmp1, ccOpt);
Args.GetEnv("CFLAGS", CFLAGS);
Strings.Append (CFLAGS, ccOpt);
Strings.Append (" ", ccOpt);
ccString := compiler;
Strings.Append (" ", ccString);

END extTools.
