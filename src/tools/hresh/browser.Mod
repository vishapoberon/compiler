MODULE browser;

  IMPORT Oberon, BrowserCmd, OPS, OPM, Files, Texts, Out,
    SharedModules, Strings, Platform;

  VAR previousPath: ARRAY 4096 OF CHAR; pathSaved: BOOLEAN;

  PROCEDURE Stopped;
  BEGIN
    IF pathSaved THEN Files.SetSearchPath(previousPath); pathSaved := FALSE END
  END Stopped;

  PROCEDURE Directories(source: ARRAY OF CHAR; VAR path: ARRAY OF CHAR): BOOLEAN;
    VAR i, n: INTEGER;
  BEGIN
    IF source = "" THEN RETURN TRUE END;
    n := Strings.Length(path); i := 0;
    IF n + Strings.Length(source) + 1 >= LEN(path) THEN RETURN FALSE END;
    path[n] := ";"; INC(n);
    WHILE source[i] # 0X DO
      IF source[i] = ":" THEN path[n] := ";" ELSE path[n] := source[i] END;
      INC(i); INC(n)
    END;
    path[n] := 0X; RETURN TRUE
  END Directories;

  PROCEDURE ShowDef*;
    VAR reader: Texts.Scanner; value, file, path, extra: ARRAY 4096 OF CHAR;
      name: OPS.Name; detail: CHAR; i, start, n: INTEGER; valid: BOOLEAN;
      text: Texts.Text; output: Texts.Reader; ch: CHAR;
  BEGIN
    Texts.OpenScanner(reader, Oberon.Par.text, Oberon.Par.pos); detail := 0X;
    Texts.Scan(reader);
    IF (reader.class = Texts.Char) & (reader.c = "-") THEN
      Texts.Scan(reader);
      IF (reader.class # Texts.Name) OR (reader.s # "x") THEN
        Out.String("usage: browser.ShowDef [-x] module[.sym]"); Out.Ln; RETURN
      END;
      detail := "x"; Texts.Scan(reader)
    END;
    IF ((reader.class # Texts.Name) & (reader.class # Texts.String)) OR
        (reader.len >= LEN(reader.s) - 1) THEN
      Out.String("usage: browser.ShowDef [-x] module[.sym]"); Out.Ln; RETURN
    END;
    COPY(reader.s, value);
    start := 0; i := 0;
    WHILE value[i] # 0X DO IF value[i] = "/" THEN start := i + 1 END; INC(i) END;
    n := 0;
    WHILE (value[start + n] # 0X) & (value[start + n] # ".") DO
      IF n >= LEN(name) - 1 THEN Out.String("browser.ShowDef: module name too long"); Out.Ln; RETURN END;
      name[n] := value[start + n]; INC(n)
    END;
    name[n] := 0X;
    IF start > 0 THEN
      COPY(value, file)
    ELSE
      (* Locate the symbol without loading or initializing the requested module. *)
      IF ~SharedModules.SymbolFile(name, file) THEN
        Out.String(name); Out.String(" -- symbol file not found"); Out.Ln; RETURN
      END
    END;
    i := Strings.Length(file) - 1;
    WHILE (i >= 0) & (file[i] # "/") DO DEC(i) END;
    IF i >= 0 THEN COPY(file, path); path[i] := 0X ELSE path := "." END;
    IF path = "" THEN path := "/" END;
    valid := Directories(SharedModules.path, path);
    Platform.GetEnv("VOC_SYM_PATH", extra); valid := Directories(extra, path) & valid;
    Platform.GetEnv("OBERON", extra); valid := Directories(extra, path) & valid;
    valid := Directories(".", path) & valid;
    COPY(OPM.InstallDir, extra); Strings.Append("/modular/2/sym", extra);
    valid := Directories(extra, path) & valid;
    IF ~valid THEN Out.String("browser.ShowDef: symbol search path is too long"); Out.Ln; RETURN END;
    IF ~Files.GetSearchPath(previousPath) THEN
      Out.String("browser.ShowDef: existing file search path is too long"); Out.Ln; RETURN
    END;
    Oberon.OnStop(Stopped); pathSaved := TRUE;
    Files.SetSearchPath(path);
    NEW(text); Texts.Open(text, "");
    BrowserCmd.Definition(name, detail, text);
    Texts.OpenReader(output, text, 0); Texts.Read(output, ch);
    WHILE ~output.eot DO
      IF ch = 0DX THEN Out.Ln ELSE Out.Char(ch) END;
      Texts.Read(output, ch)
    END;
    Files.SetSearchPath(previousPath); pathSaved := FALSE
  END ShowDef;

END browser.
