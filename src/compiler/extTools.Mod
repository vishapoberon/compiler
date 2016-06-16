MODULE extTools;

IMPORT Strings, Console, Configuration, Platform, OPM;

VAR compilationOptions, CFLAGS: ARRAY 1023 OF CHAR;


PROCEDURE execute(title: ARRAY OF CHAR; cmd: ARRAY OF CHAR);
  VAR r, status, exitcode: INTEGER;
BEGIN
  IF OPM.Verbose THEN Console.String(title); Console.String(cmd); Console.Ln END;
  r := Platform.System(cmd);
  status := r MOD 128;
  exitcode := r DIV 256;
  IF exitcode > 127 THEN exitcode := exitcode - 256 END; (* Handle signed exit code *)

  IF r # 0 THEN
    Console.String(title); Console.String(cmd); Console.Ln;
    Console.String("-- failed: status "); Console.Int(status,1);
    Console.String(", exitcode ");        Console.Int(exitcode,1);
    Console.String("."); Console.Ln;
    IF (status = 0) & (exitcode = 127) THEN
      Console.String("Is the C compiler in the current command path?"); Console.Ln
    END;
    IF status # 0 THEN Platform.Halt(status) ELSE Platform.Halt(exitcode) END
  END;
END execute;


PROCEDURE Assemble*(moduleName: ARRAY OF CHAR);
  VAR
    cmd: ARRAY 1023 OF CHAR;
  BEGIN
    cmd := Configuration.compile;
    Strings.Append(compilationOptions, cmd);
    Strings.Append("-c ",              cmd);
    Strings.Append(moduleName,         cmd);
    Strings.Append(".c",               cmd);
    execute("Assemble: ", cmd);
  END Assemble;


PROCEDURE LinkMain*(VAR moduleName: ARRAY OF CHAR; statically: BOOLEAN; additionalopts: ARRAY OF CHAR);
  VAR
    cmd: ARRAY 1023 OF CHAR;
  BEGIN
    cmd := Configuration.compile;
    Strings.Append(" ",                        cmd);
    Strings.Append(compilationOptions,         cmd);
    Strings.Append(moduleName,                 cmd);
    Strings.Append(".c ",                      cmd);
    Strings.Append(additionalopts,             cmd);
    IF statically THEN
      Strings.Append(Configuration.staticLink, cmd)
    END;
    Strings.Append(Configuration.objflag,      cmd);
    Strings.Append(moduleName,                 cmd);
    Strings.Append(Configuration.linkflags,    cmd);
    Strings.Append(Configuration.installdir,   cmd);
    Strings.Append('/lib"',                    cmd);
    Strings.Append(Configuration.libspec,      cmd);

    execute("Assemble and link: ", cmd);
  END LinkMain;


BEGIN
  Strings.Append(' -I "',                  compilationOptions);
  Strings.Append(Configuration.installdir, compilationOptions);
  Strings.Append('/include" ',             compilationOptions);
  Platform.GetEnv("CFLAGS", CFLAGS);
  Strings.Append (CFLAGS,                  compilationOptions);
  Strings.Append (" ",                     compilationOptions);
END extTools.
