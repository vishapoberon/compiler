MODULE JsonTest;   (* :file: JsonTest.Mod  --  Testing Json.Mod *)
IMPORT Json, Files, Out;

CONST
   FilesSize    = 16;
   BufferSize   = 8 * 1024;
   ErrmessSize  = 1024;

   
TYPE
   Name = ARRAY 256 OF CHAR;


VAR
   files : ARRAY FilesSize OF Name;
   yes, shallprint : SET;


PROCEDURE print (s: ARRAY OF CHAR);
BEGIN Out.String (s); Out.Flush END print;

PROCEDURE cprint(c: CHAR);
BEGIN Out.Char (c) END cprint;

PROCEDURE iprint (i: LONGINT);
BEGIN Out.Int (i, 6); cprint (" ") END iprint;

PROCEDURE lf;
BEGIN Out.Ln END lf;

PROCEDURE tab;
BEGIN cprint (09X) END tab;


PROCEDURE SlurpFile (VAR buffer: ARRAY OF CHAR; filename: ARRAY OF CHAR): BOOLEAN;
(** TODO: don't crash if no such file *)
VAR
   f : Files.File;
   r : Files.Rider;
   len : LONGINT;
BEGIN
   f := Files.Old (filename);
   Files.Set       (r, f, 0);
   len := Files.Length (f);
   Files.ReadBytes (r,  buffer, len);
   Files.Close     (f);
   buffer[len] := 0X;
   iprint (len); print (" bytes   ");
   RETURN TRUE
END SlurpFile;


(* ------------------------------------------------------------------------- *)
(* :section:    Try to parse and format back json files *)
PROCEDURE Try (no: INTEGER; filename: ARRAY OF CHAR; shallprint: BOOLEAN);
VAR
   buffer  : ARRAY BufferSize OF CHAR;
   out     : ARRAY BufferSize OF CHAR;
   errmess : ARRAY 1024 OF CHAR;
   i       : INTEGER;
   jval    : Json.Value;
BEGIN
   lf; FOR i := 0 TO 79 DO cprint ('-') END;
   lf; iprint (no); print ("  "); print (filename);
   ASSERT (SlurpFile (buffer, filename), 55);
   print ("parsing ");
   IF Json.Parse (jval, buffer, errmess) THEN
      IF errmess = "" THEN
         print ("OK  ");
      ELSE print ("raised some WARNINGS "); lf; print (errmess); lf;
      END;
      print ("formating ");
      IF Json.Format (out, jval) THEN
         print ("done");
         IF shallprint THEN
            lf; print (out);
         END;
      ELSE print ("FAILED"); lf; print (errmess)
      END
   ELSE print ("FAILED"); lf; print (errmess)
   END;
   lf;
END Try;

PROCEDURE Tests;
VAR
   p : BOOLEAN;
   i : INTEGER;
BEGIN
   lf;
   lf; print ("============  JsonMain");
   lf;
   FOR i := 0 TO FilesSize - 1 DO
      IF i IN yes THEN
         IF i IN shallprint THEN 
            p := TRUE 
         ELSE p := FALSE 
         END;
         Try (i, files[i], p)
      END;
   END;
END Tests;

(* ------------------------------------------------------------------------- *)
(* :section:    get object names and format each one by one *)
PROCEDURE TestUncase;
VAR
   filename : ARRAY 64 OF CHAR;
   buffer   : ARRAY BufferSize OF CHAR;
   errmess  : ARRAY ErrmessSize OF CHAR;
   tree,v   : Json.Value;
   obj      : Json.Obj;
   namelist : Json.NameList;
   name     : Json.jString;
BEGIN
   lf; print ("------------  TestUncase");
   lf;
   filename := "example-2.json"; print (filename);
   ASSERT (SlurpFile  (buffer, filename),      71);
   ASSERT (Json.Parse (tree, buffer, errmess), 72);
   obj      := tree(Json.Obj);
   namelist := Json.ObjNames (obj);
   WHILE namelist # NIL DO
      name     := namelist.name;
      namelist := namelist.next;
      lf; print ("-------   <"); print (name^);
      IF Json.ObjSelect (v, obj, name) THEN
         ASSERT (Json.Format (buffer, v), 74);
         print (">");
         lf; print (buffer);
         lf;
      ELSE
         lf; print ("############  element name not found");
      END;
   END;
   lf; print ("------------  TestUncase done");
   lf;
END TestUncase;

(* ------------------------------------------------------------------------- *)
(* :section:    process a vipack package description 'on paper' *)
PROCEDURE PrintImports (v: Json.Value);
VAR a: Json.Arr;
BEGIN
   print ("< ");
   IF v IS Json.Arr THEN
      a := v(Json.Arr);
      WHILE a # NIL DO
         print (a.value(Json.Str).str^);
         a := a.next
      END;
      print (" >")
   ELSE
      print ("<array expected>")
   END
END PrintImports;

PROCEDURE DownloadRemoteStuff (v: Json.Value);
BEGIN
   lf; print ("        ... Downloads running:"); print ("  uuuhh, thats a tricky one...");
END DownloadRemoteStuff;

PROCEDURE CheckOrInstallDeps(v: Json.Value);
VAR package,version: Json.jString;
   o: Json.Obj;
BEGIN
   IF v = NIL THEN
      lf; print ("   no deps listed");
   ELSE
      lf; print ("        ... Checking deps:  ");
      WITH
       v: Json.Obj DO
         o := v;
         WHILE o # NIL DO
            package := o.name;
            version := o.value(Json.Str).str;
            lf; print ("  "); print (package^);
                print ("   "); print (version^); print ("   ok");
            o := o.next
         END;
       | v: Json.Str DO print (v.str^)
      ELSE
         lf; print ("no idea what to do");
      END;
   END;
END CheckOrInstallDeps;

PROCEDURE DoTheBuild (v: Json.Arr);
VAR cmd :Json.jString;
BEGIN
   WHILE v # NIL DO
      lf; print ("        ... cmd:    ");
      cmd := v.value(Json.Str).str;
      print (cmd^);
      v := v.next;
   END;
END DoTheBuild;

PROCEDURE TestPackage;
VAR
   filename : ARRAY 64 OF CHAR;
   buffer   : ARRAY BufferSize OF CHAR;
   errmess  : ARRAY ErrmessSize OF CHAR;
   tree     : Json.Value;
   o        : Json.Obj;
   s        : Json.jString;
BEGIN
   lf; print ("------------  TestPackage   ");
   filename := "../ssqJson.json";
   print (filename);
   ASSERT (SlurpFile (buffer, filename),       81);
   ASSERT (Json.Parse (tree, buffer, errmess), 82);
   o := tree(Json.Obj);
   lf; print (" 1:   "); print (o.name^); tab; s := o.value(Json.Str).str; print (s^); o := o.next;
   lf; print (" 2:   "); print (o.name^); tab; s := o.value(Json.Str).str; print (s^); o := o.next;
   lf; print (" 3:   "); print (o.name^); tab; print (o.value(Json.Str).str^);         o := o.next;
   lf; print (" 4:   "); print (o.name^); tab; print (o.value(Json.Str).str^);         o := o.next;
   lf; print (" 5:   "); print (o.name^); tab; print (o.value(Json.Str).str^);         o := o.next;
   lf; print (" 6:   "); print (o.name^); tab; print (o.value(Json.Str).str^);         o := o.next;
   lf; print (" 7:   "); print (o.name^); tab; print (o.value(Json.Str).str^);         o := o.next;
   lf; print (" 8:   "); print (o.name^); tab; CheckOrInstallDeps (o.value);           o := o.next;
   lf; print (" 9:   "); print (o.name^); tab; PrintImports (o.value);                 o := o.next;
   lf; print (" 0:   "); print (o.name^); tab; DownloadRemoteStuff (o.value);          o := o.next;
   lf; print (" 1:   "); print (o.name^); tab; DoTheBuild (o.value(Json.Arr));         o := o.next;
   lf;
   lf; print ("------------  TestPackage done");
   lf;
END TestPackage;


(* ------------------------------------------------------------------------- *)
(* :section:    MAIN *)
BEGIN
   Json.Info;
   yes := {0,1,2,3,4,5};
   shallprint := yes;
   (* yes := {4}; *)
   (* shallprint := {7}; *)
   COPY ("data.json",      files[0]);
   COPY ("example-1.json", files[1]);
   COPY ("example-2.json", files[2]);
   COPY ("example-3.json", files[3]);
   COPY ("../ssqJson.json",files[4]);
   COPY ("example-0.json", files[5]);
   Tests;
   TestUncase;
   TestPackage;
   lf; print ("============  JsonMain done.");
   lf;


(* ------------------------------------------------------------------------- *)
END JsonTest.
(* :file: END sts-q 2024-Feb *)
