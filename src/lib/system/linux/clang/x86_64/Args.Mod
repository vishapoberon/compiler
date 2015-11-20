MODULE Args;  (* jt, 8.12.94 *)

  (* command line argument handling for voc (jet backend) *)


  IMPORT SYSTEM;
  
  TYPE
    ArgPtr = POINTER TO ARRAY 1024 OF CHAR;
    ArgVec = POINTER TO ARRAY 1024 OF ArgPtr;

  VAR argc-:INTEGER; argv-: LONGINT;
  (*PROCEDURE -includestdlib() "#include <stdlib.h>";*)
  PROCEDURE -externgetenv() "extern char *getenv(const char *name);"; (* took this from stdlib.h*)
  PROCEDURE -Argc(): INTEGER "SYSTEM_argc";
  PROCEDURE -Argv(): LONGINT "(long)SYSTEM_argv";
  PROCEDURE -getenv(var: ARRAY OF CHAR): ArgPtr
    "(Args_ArgPtr)getenv(var)";

  PROCEDURE Get*(n: INTEGER; VAR val: ARRAY OF CHAR);
    VAR av: ArgVec;
  BEGIN
    IF n < argc THEN av := SYSTEM.VAL(ArgVec, argv); COPY(av[n]^, val) END
  END Get;

  PROCEDURE GetInt*(n: INTEGER; VAR val: LONGINT);
    VAR s: ARRAY 64 OF CHAR; k, d, i: LONGINT;
  BEGIN
    s := ""; Get(n, s); i := 0;
    IF s[0] = "-" THEN i := 1 END ;
    k := 0; d := ORD(s[i]) - ORD("0");
    WHILE (d >= 0 ) & (d <= 9) DO k := k*10 + d; INC(i); d := ORD(s[i]) - ORD("0") END ;
    IF s[0] = "-" THEN d := -d; DEC(i) END ;
    IF i > 0 THEN val := k END
  END GetInt;

  PROCEDURE Pos*(s: ARRAY OF CHAR): INTEGER;
    VAR i: INTEGER; arg: ARRAY 256 OF CHAR;
  BEGIN
    i := 0; Get(i, arg);
    WHILE (i < argc) & (s # arg) DO INC(i); Get(i, arg) END ;
    RETURN i
  END Pos;

  PROCEDURE GetEnv*(var: ARRAY OF CHAR; VAR val: ARRAY OF CHAR);
    VAR p: ArgPtr;
  BEGIN
    p := getenv(var);
    IF p # NIL THEN COPY(p^, val) END
  END GetEnv;

  PROCEDURE getEnv*(var: ARRAY OF CHAR; VAR val: ARRAY OF CHAR): BOOLEAN;
    VAR p: ArgPtr;
  BEGIN
    p := getenv(var);
    IF p # NIL THEN
       COPY(p^, val);
       RETURN TRUE
    ELSE
       RETURN FALSE
    END
  END getEnv;

BEGIN argc := Argc(); argv := Argv()
END Args.
