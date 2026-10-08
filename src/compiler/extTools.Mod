MODULE extTools;

IMPORT Strings, Out, Configuration, Platform, Modules, Heap, Files, OPM;

TYPE CommandString = ARRAY 8192 OF CHAR;
     Path = ARRAY 4096 OF CHAR;

VAR CFLAGS, LDFLAGS, LDLIBS: CommandString;


PROCEDURE execute(title: ARRAY OF CHAR; cmd: ARRAY OF CHAR);
  VAR r, status, exitcode: INTEGER; fullcmd: CommandString;
BEGIN
  IF OPM.verbose IN OPM.Options THEN
    Out.String("  "); Out.String(cmd); Out.Ln
  END;

  (* Hack to suppress unwanted filename display by Microsoft C compiler on successful compilations. *)
  IF Configuration.compiler = "MSC" THEN
    fullcmd := "cmd /c ";
    Strings.Append(cmd, fullcmd);
    Strings.Append(" >msc-listing || type msc-listing", fullcmd)
  ELSE
    COPY(cmd, fullcmd);
  END;

  (* Get GC to run file finalizers closing generated C files as otherwise Microsoft C cannot open them. *)
  Heap.GC(FALSE);

  r := Platform.System(fullcmd);

  status := r MOD 128; exitcode := r DIV 256;
  IF exitcode > 127 THEN exitcode := exitcode - 256 END; (* Handle signed exit code *)

  IF r # 0 THEN
    Out.String(title); Out.String(cmd); Out.Ln;
    Out.String("-- failed: status "); Out.Int(status,1);
    Out.String(", exitcode ");        Out.Int(exitcode,1);
    Out.String("."); Out.Ln;
    IF (status = 0) & (exitcode = 127) THEN
      Out.String("Is the C compiler in the current command path?"); Out.Ln
    END;
    IF status # 0 THEN Modules.Halt(status) ELSE Modules.Halt(exitcode) END
  END;
END execute;


PROCEDURE InitialiseCompilerCommand(VAR s: ARRAY OF CHAR; additionalopts: ARRAY OF CHAR);
BEGIN
  COPY(Configuration.compile, s);
  Strings.Append(' -I "', s);
  Strings.Append(OPM.ResourceDir, s);
  Strings.Append('/include" ', s);
  Strings.Append(additionalopts, s);
  Strings.Append(" ", s);
  Platform.GetEnv("CFLAGS", CFLAGS);
  Strings.Append (CFLAGS, s);
  Strings.Append (" ", s);
END InitialiseCompilerCommand;


(* ELF modular linking. Libraries deliberately do not DT_NEEDED the core:
   -md/-mP supply it as a shared library; -mD exports it from the executable.
   Thus both hosts can use the same module without ever loading two heaps. *)

PROCEDURE Fail(message: ARRAY OF CHAR);
BEGIN OPM.LogWStr(message); OPM.LogWLn; Platform.Exit(1) END Fail;

PROCEDURE Add(text: ARRAY OF CHAR; VAR target: ARRAY OF CHAR);
BEGIN
  IF Strings.Length(target) + Strings.Length(text) >= LEN(target) THEN
    Fail("Compiler/linker command or library path is too long.")
  END;
  Strings.Append(text, target)
END Add;

PROCEDURE Quote(text: ARRAY OF CHAR; VAR target: ARRAY OF CHAR);
  VAR i: INTEGER; ch: ARRAY 2 OF CHAR;
BEGIN
  Add("'", target); ch[1] := 0X; i := 0;
  WHILE text[i] # 0X DO
    IF text[i] = "'" THEN
      Add("'", target); Add('"', target); Add("'", target);
      Add('"', target); Add("'", target)
    ELSE ch[0] := text[i]; Add(ch, target)
    END;
    INC(i)
  END;
  Add("'", target)
END Quote;

PROCEDURE IsCore(name: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN (name = "SYSTEM") OR (name = "Heap") OR (name = "Platform") OR (name = "Modules") END IsCore;

PROCEDURE SearchPath(VAR path: Path);
  VAR extra: Path;
BEGIN
  path := ".:"; Platform.GetEnv("VOC_MODULE_PATH", extra);
  IF extra # "" THEN Add(extra, path); Add(":", path) END;
  Add(OPM.LibraryDir, path)
END SearchPath;

PROCEDURE NextDirectory(path: ARRAY OF CHAR; VAR pos: INTEGER; VAR dir: Path): BOOLEAN;
  VAR i: INTEGER;
BEGIN
  IF pos < 0 THEN RETURN FALSE END;
  i := 0;
  WHILE (path[pos] # 0X) & (path[pos] # ":") DO dir[i] := path[pos]; INC(i); INC(pos) END;
  dir[i] := 0X;
  IF path[pos] = 0X THEN pos := -1 ELSE INC(pos) END;
  IF dir = "" THEN dir := "." END;
  RETURN TRUE
END NextDirectory;

PROCEDURE LibraryName(name, extension: ARRAY OF CHAR; VAR file: ARRAY OF CHAR);
BEGIN
  COPY("lib", file); Add(Configuration.name, file); Add("-", file); Add(name, file);
  Add("-O", file); Add(OPM.Model, file); Add(extension, file)
END LibraryName;

PROCEDURE FindLibrary(name, extension: ARRAY OF CHAR; VAR full: Path);
  VAR path, dir: Path; file: ARRAY 128 OF CHAR; pos: INTEGER; id: Platform.FileIdentity;
BEGIN
  LibraryName(name, extension, file); SearchPath(path); pos := 0;
  WHILE NextDirectory(path, pos, dir) DO
    full := dir; Add("/", full); Add(file, full);
    IF Platform.IdentifyByName(full, id) = 0 THEN RETURN END
  END;
  OPM.LogWStr("Shared-module link: missing "); OPM.LogWStr(file); OPM.LogWLn;
  Fail("Build the dependency first; set VOC_MODULE_PATH/VOCLIBDIR for library directories.")
END FindLibrary;

PROCEDURE ModularCommand(VAR cmd: CommandString);
  VAR compiler, path, dir: Path; pos: INTEGER;
BEGIN
  IF (Configuration.compiler = "MSC") OR (Configuration.os = "windows") OR
      (Configuration.os = "cygwin") OR (Configuration.os = "darwin") THEN
    Fail("-l/-P currently require an ELF target with a GCC-compatible linker.")
  END;
  Platform.GetEnv("CC", compiler);
  IF compiler = "" THEN COPY(Configuration.compile, cmd) ELSE COPY(compiler, cmd) END;
  Add(" ", cmd); Platform.GetEnv("CFLAGS", CFLAGS); Add(CFLAGS, cmd);
  (* Generated code uses GNU C and SYSTEM.VAL type punning. Keep both valid
     even when CC/CFLAGS override the installation's compiler defaults. *)
  Add(" -std=gnu11 -fno-strict-aliasing -fPIC ", cmd); SearchPath(path); pos := 0;
  WHILE NextDirectory(path, pos, dir) DO
    Add(" -iquote", cmd); Quote(dir, cmd)
  END;
  dir := OPM.ResourceDir; Add("/include", dir); Add(" -iquote", cmd); Quote(dir, cmd);
  Add(" ", cmd)
END ModularCommand;

PROCEDURE ModularLinkFlags(VAR cmd: CommandString);
  VAR path: Path;
BEGIN
  Platform.GetEnv("LDFLAGS", LDFLAGS); Add(" ", cmd); Add(LDFLAGS, cmd);
  (* No as-needed dropping: even type-only imports have Oberon initializers. *)
  Add(" -Wl,--no-as-needed ", cmd);
  Platform.GetEnv("VOC_RUNPATH", path);
  IF path = "" THEN path := "$ORIGIN:"; Add(OPM.LibraryDir, path) END;
  Add(" -Wl,-rpath,", cmd); Quote(path, cmd); Add(" ", cmd)
END ModularLinkFlags;

PROCEDURE Dependencies(VAR cmd: CommandString);
  VAR i: INTEGER; full: Path;
BEGIN
  i := 0;
  WHILE i < OPM.SharedImportCount DO
    IF ~IsCore(OPM.SharedImports[i]) THEN
      FindLibrary(OPM.SharedImports[i], ".so", full); Quote(full, cmd); Add(" ", cmd)
    END;
    INC(i)
  END
END Dependencies;

PROCEDURE ExtraLibraries(VAR cmd: CommandString);
BEGIN Platform.GetEnv("LDLIBS", LDLIBS); Add(" ", cmd); Add(LDLIBS, cmd) END ExtraLibraries;

PROCEDURE Assemble*(moduleName: ARRAY OF CHAR);
  VAR cmd: CommandString;
BEGIN
  IF OPM.permodules IN OPM.Options THEN ModularCommand(cmd)
  ELSE InitialiseCompilerCommand(cmd, "")
  END;
  Strings.Append("-c ", cmd); Strings.Append(moduleName, cmd);
  Strings.Append(".c", cmd); execute("C compile: ", cmd)
END Assemble;

PROCEDURE LinkModule*(moduleName: ARRAY OF CHAR);
  VAR cmd: CommandString; file: ARRAY 128 OF CHAR; full: Path;
BEGIN
  IF IsCore(moduleName) THEN Fail("SYSTEM, Platform, Heap and Modules belong to the minimal core, not separate modules.") END;
  FindLibrary("core", ".a", full); (* Require the matching core development installation. *)
  ModularCommand(cmd); Add(" -shared ", cmd); Add(moduleName, cmd); Add(".c ", cmd);
  LibraryName(moduleName, ".so", file);
  Add(" -Wl,-soname,", cmd); Quote(file, cmd); Add(" -o ", cmd); Quote(file, cmd);
  ModularLinkFlags(cmd); Dependencies(cmd); ExtraLibraries(cmd);
  execute("Shared-module link: ", cmd)
END LinkModule;

PROCEDURE LinkModularMain(moduleName: ARRAY OF CHAR);
  VAR cmd: CommandString; full: Path;
BEGIN
  ModularCommand(cmd); Add(moduleName, cmd); Add(".c -o ", cmd); Quote(moduleName, cmd);
  ModularLinkFlags(cmd); Dependencies(cmd);
  FindLibrary("core", ".so", full); Quote(full, cmd);
  ExtraLibraries(cmd); execute("Modular program link: ", cmd)
END LinkModularMain;


PROCEDURE HostLine(VAR rider: Files.Rider; text: ARRAY OF CHAR);
BEGIN
  Files.WriteBytes(rider, text, Strings.Length(text)); Files.Write(rider, 0AX)
END HostLine;

PROCEDURE GenerateLauncher*(moduleName: ARRAY OF CHAR);
  VAR file: Files.File; rider: Files.Rider; name: ARRAY 128 OF CHAR; line: ARRAY 256 OF CHAR;
BEGIN
  COPY(moduleName, name); Add("__host.c", name);
  file := Files.New(name);
  IF file = NIL THEN Fail("Cannot create application launcher source.") END;
  Files.Set(rider, file, 0);
  HostLine(rider, "/* Generated VOC module host. The application is loaded, not linked. */");
  HostLine(rider, '#include "SYSTEM.h"');
  HostLine(rider, '#include "ModuleLoader.h"');
  HostLine(rider, "int main(int argc, char **argv) {");
  HostLine(rider, "  __INIT(argc, argv);");
  HostLine(rider, "  __MODULE_IMPORT(ModuleLoader);");
  (* This name cannot collide with an Oberon source module. In particular, do
     not register the application's name before its initializer is loaded. *)
  HostLine(rider, '  __REGMAIN("_VOCModuleHost", 0);');
  (* Use sizeof on the string, not a model-dependent integer conversion. *)
  line := '  ModuleLoader_Run((CHAR*)"'; Add(moduleName, line);
  Add('", sizeof "', line); Add(moduleName, line); Add('");', line);
  HostLine(rider, line);
  HostLine(rider, "  __FINI;"); HostLine(rider, "}");
  IF rider.res # 0 THEN Fail("Cannot write application launcher source.") END;
  Files.Register(file)
END GenerateLauncher;

PROCEDURE LinkLauncher*(moduleName: ARRAY OF CHAR; embedded: BOOLEAN);
  VAR cmd: CommandString; full: Path;
BEGIN
  ModularCommand(cmd); Add(moduleName, cmd); Add("__host.c -o ", cmd); Quote(moduleName, cmd);
  ModularLinkFlags(cmd);
  (* The executable knows only its loader and core, never the application or
     its imports. Rebuilding an application library cannot change this graph. *)
  FindLibrary("ModuleLoader", ".so", full); Quote(full, cmd); Add(" ", cmd);
  IF embedded THEN
    FindLibrary("core", ".a", full);
    Add(" -Wl,--export-dynamic -Wl,--whole-archive ", cmd); Quote(full, cmd);
    Add(" -Wl,--no-whole-archive ", cmd)
  ELSE
    FindLibrary("core", ".so", full); Quote(full, cmd)
  END;
  (* LDLIBS applies to the application library, not its fixed launcher. *)
  execute("Module-host link: ", cmd)
END LinkLauncher;


PROCEDURE LinkMain*(VAR moduleName: ARRAY OF CHAR; statically: BOOLEAN; additionalopts: ARRAY OF CHAR);
  VAR
    cmd: CommandString;
  BEGIN
    IF OPM.permodules IN OPM.Options THEN
      IF statically THEN Fail("Static system linking cannot be combined with modular program linking; use -mP.") END;
      LinkModularMain(moduleName); RETURN
    END;
    InitialiseCompilerCommand(cmd, additionalopts);
    Strings.Append(moduleName,                   cmd);
    Strings.Append(".c ",                        cmd);

    Platform.GetEnv("LDFLAGS", LDFLAGS);
    Strings.Append(LDFLAGS, cmd);
    Strings.Append(" ", cmd);

    IF statically THEN
      IF Configuration.os = "darwin" THEN
        Strings.Append(OPM.LibraryDir,           cmd);
        Strings.Append('/lib',                   cmd);
        Strings.Append(Configuration.name,       cmd);
        Strings.Append('-O',                     cmd);
        Strings.Append(OPM.Model,                cmd);
        Strings.Append('.a',                     cmd);
      ELSE
        Strings.Append(Configuration.staticLink, cmd)
      END
    END;
    Strings.Append(Configuration.objflag,        cmd);
    Strings.Append(moduleName,                   cmd);
    Strings.Append(" ", cmd);

    Platform.GetEnv("LDLIBS", LDLIBS);
    Strings.Append(LDLIBS, cmd);
    Strings.Append(" ", cmd);


    IF (~statically) OR ~(Configuration.os = "darwin") THEN
      Strings.Append(Configuration.linkflags,      cmd);
      Strings.Append(OPM.LibraryDir,               cmd);
      Strings.Append('"',                          cmd);
      Strings.Append(Configuration.libspec,        cmd);
      Strings.Append('-O',                         cmd);
      Strings.Append(OPM.Model,                    cmd);
      Strings.Append(Configuration.libext,         cmd)
    END;
    execute("C compile and link: ", cmd);

    IF (Configuration.os = "darwin") & ~statically THEN
      (* Darwin requires an extra command to set the library directory into the binary *)
      cmd := "install_name_tool -change lib";
      Strings.Append(Configuration.name,   cmd);
      Strings.Append('-O',                 cmd);
      Strings.Append(OPM.Model,            cmd);
      Strings.Append('.dylib "',           cmd);
      Strings.Append(OPM.LibraryDir,       cmd);
      Strings.Append('/lib',               cmd);
      Strings.Append(Configuration.name,   cmd);
      Strings.Append('-O',                 cmd);
      Strings.Append(OPM.Model,            cmd);
      Strings.Append('.dylib" ',           cmd);
      Strings.Append(moduleName,           cmd);
      execute("Set library directory: ",   cmd)
    END
  END LinkMain;


END extTools.
