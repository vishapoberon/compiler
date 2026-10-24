@echo off

:: make.cmd - Build Oberon with Microsoft C compiler.

:: Expects the path to include cl.exe.

:: As of December 2016 the Microsoft C compiler and build tools
:: can be downloaded independently of  the full Visual Studio IDE
:: as the 'Visual C++ Build Tools 2015'.

:: See: http://landinghub.visualstudio.com/visual-cpp-build-tools

:: With this installed, from the start button select:
::    All Apps / Visual C++ Build Tools / Visual C++ 2015 x86 Native Build Tools Command Prompt
:: or All Apps / Visual C++ Build Tools / Visual C++ 2015 x64 Native Build Tools Command Prompt




:: Create configuration and parameter files.

cl -nologo -Isrc\runtime src\tools\make\configure.c >msc-listing || type msc-listing
setlocal
configure.exe
del configure.obj configure.exe 2>nul


:: Extract make variables into local environment

for /F "delims='=' tokens=1,2" %%a in (Configuration.make) do set %%a=%%b

set FLAVOUR=%OS%.%DATAMODEL%.%COMPILER%
set BUILDDIR=build\%FLAVOUR%
set OBECOMP=%ONAME%%BINEXT%
set MODEL=2

for /F %%d in ('cd');do set ROOTDIR=%%d


:: Process target parameter

if "%1" equ "" (
  call :all
) else (
  call :%1
)
endlocal
goto :eof




:usage
@echo.
@echo Usage:
@echo.
@echo.  make           - Make compiler to 'install' subdirectory
@echo.  make install  - Install 'install' subdir to OS. Requires administrator privileges
@echo.
@echo.  make clean    - Remove made files
@echo.  make compiler - Build the compiler but not the library
@echo.  make library  - Build all library files and make library
@echo.  make install  - Install built compiler and library (from administrator prompt)
goto :eof




:all
call :clean          || exit /b
echo.
echo.--- Compiler build started ---
echo.
call :compiler       || exit /b
echo.
echo.--- Compiler build successfull ---
echo.
call :browsercmd     || exit /b
echo.
echo.--- Library build started ---
echo.
call :library        || exit /b
echo.
echo.--- Library build successfull ---
echo.
call :makeinstalldir || exit /b
goto :eof




:makeinstalldir
rmdir /s /q "%ROOTDIR%\install"                        >nul 2>&1
mkdir "%ROOTDIR%\install"                              >nul 2>&1

mkdir "%ROOTDIR%\install\bin"                          >nul 2>&1
copy %OBECOMP%              "%ROOTDIR%\install\bin"    >nul
copy %BUILDDIR%\showdef.exe "%ROOTDIR%\install\bin"    >nul

mkdir "%ROOTDIR%\install\2"                            >nul 2>&1
mkdir "%ROOTDIR%\install\2\include"                    >nul 2>&1
mkdir "%ROOTDIR%\install\2\sym"                        >nul 2>&1
copy %BUILDDIR%\2\*.h    "%ROOTDIR%\install\2\include" >nul
copy %BUILDDIR%\2\*.sym  "%ROOTDIR%\install\2\sym"     >nul

mkdir "%ROOTDIR%\install\C"                            >nul 2>&1
mkdir "%ROOTDIR%\install\C\include"                    >nul 2>&1
mkdir "%ROOTDIR%\install\C\sym"                        >nul 2>&1
copy %BUILDDIR%\C\*.h    "%ROOTDIR%\install\C\include" >nul
copy %BUILDDIR%\C\*.sym  "%ROOTDIR%\install\C\sym"     >nul

mkdir "%ROOTDIR%\install\lib"                          >nul 2>&1
copy %BUILDDIR%\2\lib%ONAME%* "%ROOTDIR%\install\lib"  >nul
copy %BUILDDIR%\C\lib%ONAME%* "%ROOTDIR%\install\lib"  >nul

echo.
echo Now add %ROOTDIR%\install\bin to your path, for example with the command:
echo PATH %ROOTDIR%\install\bin;%%PATH%%
echo.
goto :eof



:install
whoami /groups | find "12288" >nul
if errorlevel 1 (
echo make install - administrator rights required. Please run under an administrator command prompt.
goto :eof
)
echo Installing to %INSTALLDIR%
rmdir /s /q "%INSTALLDIR%"                     >nul 2>&1
xcopy /E /I /Y "%ROOTDIR%\install" "%INSTALLDIR%" >nul
echo.
echo Now add %INSTALLDIR%\bin to your path, for example with the command:
echo PATH %INSTALLDIR%\bin;%%PATH%%
echo.
goto :eof



:uninstall
whoami /groups | find "12288" >nul
if errorlevel 1 (
echo make uninstall - administrator rights required. Please run under an administrator command prompt.
goto :eof
)
echo Uninstalling %INSTALLDIR%
rmdir /s /q "%INSTALLDIR%" >nul 2>&1
goto :eof




:compiler
call :translate || exit /b
call :assemble  || exit /b
goto :eof




:clean
echo.--- Cleaning branch ... %OS% %COMPILER% %DATAMODEL% ---
rd /s /q %BUILDDIR% 2>nul
del /q %OBECOMP% 2>nul
goto :eof




:assemble
echo.
echo.make assemble - compiling Oberon compiler c source::
echo.  VERSION:   %VERSION%
echo.  Target characeristics:
echo.    PLATFORM:   %PLATFORM%
echo.    OS:         %OS%
echo.    BUILDDIR:   %BUILDDIR%
echo.    INSTALLDIR: %INSTALLDIR%
echo.  Oberon characteristics:
echo.    MODEL:      %MODEL%
echo.    ADRSIZE:    %ADRSIZE%
echo.    ALIGNMENT:  %ALIGNMENT%
echo.  C compiler:
echo.    COMPILER:   %COMPILER%
echo.    COMPILE:    %COMPILE%
echo.    DATAMODEL:  %DATAMODEL%

cd %BUILDDIR%

cl -nologo /Zi -c SYSTEM.c Configuration.c PlatformNative.c Platform.c Heap.c || exit /b
cl -nologo /Zi -c Out.c    Reals.c         Strings.c  Modules.c || exit /b
cl -nologo /Zi -c Files.c  Texts.c         VT100.c              || exit /b
cl -nologo /Zi -c OPM.c    extTools.c      OPS.c      OPT.c     || exit /b
cl -nologo /Zi -c OPC.c    OPV.c           OPB.c      OPP.c     || exit /b

cl -nologo /Zi Compiler.c /Fe%ROOTDIR%\%OBECOMP% /link /INCREMENTAL:NO ^
SYSTEM.obj  Configuration.obj PlatformNative.obj Platform.obj Heap.obj Out.obj Reals.obj ^
Modules.obj Files.obj         Strings.obj  Texts.obj VT100.obj extTools.obj ^
OPM.obj     OPS.obj           OPT.obj      OPC.obj   OPV.obj   OPB.obj    OPP.obj || exit /b

cd %ROOTDIR%
copy src\runtime\*.c %BUILDDIR% >nul
copy src\runtime\*.h %BUILDDIR% >nul
copy src\runtime\*.Txt %BUILDDIR% >nul
copy src\runtime\*.Txt %ROOTDIR% >nul
echo.%OBECOMP% created.
goto :eof




:compilefromsavedsource
echo.Populating clean build directory from bootstrap C sources.
mkdir %BUILDDIR% >nul 2>nul
copy bootstrap\%PLATFORM%-%ADRSIZE%%ALIGNMENT%\*.* %BUILDDIR% >nul
copy bootstrap\*.c %BUILDDIR% >nul
copy bootstrap\*.h %BUILDDIR% >nul
call :assemble || exit /b
copy bootstrap\*.c %BUILDDIR% >nul
copy bootstrap\*.h %BUILDDIR% >nul
goto :eof




:translate
:: Make sure we have an oberon compiler binary: if we built one earlier we'll use it,
:: otherwise use one of the saved sets of C sources in the bootstrap directory.
if not exist %OBECOMP% call :compilefromsavedsource

echo.
echo.make translate - translating compiler source:
echo.  PLATFORM:  %PLATFORM%
echo.  MODEL:     %MODEL%
echo.  ADRSIZE:   %ADRSIZE%
echo.  ALIGNMENT: %ALIGNMENT%

md %BUILDDIR% 2>nul
cd %BUILDDIR%
del *.sym >nul 2>nul
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../Configuration.Mod                  || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/runtime/PlatformNative%PLATFORM%.Mod || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/runtime/Platform%PLATFORM%.Mod || exit /b
%ROOTDIR%\%OBECOMP% -SsfFapx -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/runtime/Heap.Mod               || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/library/Reals.Mod              || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/library/Strings.Mod            || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/library/Out.Mod                || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/runtime/Modules.Mod            || exit /b
%ROOTDIR%\%OBECOMP% -SsfFx   -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/library/Files.Mod              || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/runtime/Texts.Mod              || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/runtime/VT100.Mod              || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/OPM.Mod               || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/extTools.Mod          || exit /b
%ROOTDIR%\%OBECOMP% -SsfFx   -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/OPS.Mod               || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/OPT.Mod               || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/OPC.Mod               || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/OPV.Mod               || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/OPB.Mod               || exit /b
%ROOTDIR%\%OBECOMP% -SsfF    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/OPP.Mod               || exit /b
%ROOTDIR%\%OBECOMP% -Ssfm    -A%ADRSIZE%%ALIGNMENT% -O%MODEL% ../../src/compiler/Compiler.Mod          || exit /b

cd %ROOTDIR%
copy src\runtime\*.c %BUILDDIR% >nul
copy src\runtime\*.h %BUILDDIR% >nul
copy src\runtime\*.Txt %BUILDDIR% >nul

echo.%BUILDDIR% filled with compiler C source.
goto :eof




:browsercmd
echo.
echo.Making symbol browser
cd %BUILDDIR%
%ROOTDIR%/%OBECOMP% -fSs ../../src/library/Oberon.Mod
%ROOTDIR%/%OBECOMP% -fSm ../../src/tools/browser/BrowserCmd.Mod
cl -nologo BrowserCmd.c Oberon.c /Feshowdef.exe ^
  PlatformNative.obj Platform.obj Texts.obj OPT.obj Heap.obj Out.obj SYSTEM.obj OPM.obj OPS.obj OPV.obj ^
  Files.obj Reals.obj Modules.obj VT100.obj Configuration.obj Strings.obj ^
  OPC.obj
cd %ROOTDIR%
goto :eof




:runtime
echo.
echo.Making runtime library for -O%MODEL%
cd %BUILDDIR%\%MODEL%
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/runtime/PlatformNative%PLATFORM%.Mod || exit /b
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/runtime/Platform%PLATFORM%.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/runtime/Heap.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/runtime/Modules.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/Reals.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/Strings.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/Out.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/In.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/runtime/VT100.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/Files.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/Math.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/MathL.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/runtime/Texts.Mod
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/Oberon.Mod
cd %ROOTDIR%
goto :eof


:cli
echo.
echo.Making command-line library for -O%MODEL%
cd %BUILDDIR%\%MODEL%
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/Args.Mod                       || exit /b
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/Console.Mod                    || exit /b
cd %ROOTDIR%
goto :eof

:v4
echo.
echo.Making V4 library for -O%MODEL%
cd %BUILDDIR%\%MODEL%
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/ports/v4/Printer.Mod                   || exit /b
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/ports/v4/Sets.Mod                      || exit /b
cd %ROOTDIR%
goto :eof

:ooc
echo.Making ooc library for -O%MODEL%
cd %BUILDDIR%\%MODEL%
for %%N in (LowReal LowLReal RealMath OakMath LRealMath LongInts ComplexMath LComplexMath Ascii CharClass oocStrings ConvTypes LRealConv LRealStr RealConv RealStr IntConv IntStr oocUnicode LongStrings Msg SysClock Time Channel IOMemory ProgramArgsHost ProgramArgs Strings2 Rts Filenames TextRider BinaryRider JulianDay FilesHost oocFiles wrapperlibc OakStrings oocRandomNumbers Real0 oo2c2LRealConv URICharClass URIString URIError URI URIAuthorityUnparsed URIAuthorityRegistryBased URIAuthorityServerBased URIQueryUnparsed URIFragmentUnparsed URISchemeHierarchical URISchemeOpaque URISchemeCurrentDoc URIParser URISchemeFile URISchemeMemory URISchemeMailTo) do (
  %ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/ports/ooc/%%N.Mod || exit /b
)
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/ports/ooc/C%DATAMODEL%.Mod || exit /b
cd %ROOTDIR%
goto :eof

:oocX11
echo No X11 support on plain Windows - use cygwin and build with cygwin make.
goto :eof

:ulm
echo.Making ulm library for -O%MODEL%
cd %BUILDDIR%\%MODEL%
for %%M in (Types Objects Priorities Disciplines Services Sys ulmSYSTEM Events Process Resources Forwarders RelatedEvents StreamsHost Streams Terminals ulmStrings SysTypes ulmTexts SysConversions Errors SysErrors SysStat ulmASCII ulmSets IO Assertions IndirectDisciplines StreamDisciplines IEEE MC68881 ulmReals Print Write ConstStrings Plotters SysIO Loader NetIO PersistentObjects PersistentDisciplines Operations Scales Times Clocks Timers Conditions StreamConditions TimeConditions Ciphers CipherOps BlockCiphers AsymmetricCiphers Conclusions RandomGenerators TCrypt IntOperations) do (
  %ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/ports/ulm/%%M.Mod || exit /b
)
cd %ROOTDIR%
goto :eof

:pow32
echo.Making pow32 library for -O%MODEL%
cd %BUILDDIR%\%MODEL%
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/ports/pow/powStrings.Mod               || exit /b
cd %ROOTDIR%
goto :eof

:misc
echo.Making misc library for -O%MODEL%
cd %BUILDDIR%\%MODEL%
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/misc/crt.Mod                     || exit /b
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/misc/Listen.Mod                  || exit /b
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/misc/MersenneTwister.Mod         || exit /b
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/misc/MultiArrays.Mod             || exit /b
%ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/library/misc/MultiArrayRiders.Mod        || exit /b
cd %ROOTDIR%
goto :eof

:s3
echo.Making s3 library for -O%MODEL%
cd %BUILDDIR%\%MODEL%
for %%M in (BTrees MD5 ethSets Zlib ZlibBuffers ZlibInflate ZlibDeflate ZlibReaders ZlibWriters Zip RandomNumbers GZReaders GZWriters Unicode Dates ethReals ethStrings Base64 BIT TwoComplement DES) do (
  %ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/ports/s3/%%M.Mod || exit /b
)
cd %ROOTDIR%
goto :eof




:ports
echo.Making portable ports for -O%MODEL%
cd %BUILDDIR%\%MODEL%
for %%M in (norayr/base64/StringBase64 norayr/bdStrings/bdStrings norayr/strutils/strTypes norayr/strutils/strUtils norayr/lists/List norayr/lists/StringList norayr/opts/optsosv norayr/opts/opts norayr/toml/TOML sts-q/ssqJson/Json) do (
  %ROOTDIR%\%OBECOMP% -Ffs -O%MODEL% ../../../src/ports/%%M.Mod || exit /b
)
cd %ROOTDIR%
goto :eof

:initlibrary
rd /s /q %BUILDDIR%\%MODEL% >nul 2>nul
mkdir %BUILDDIR%             >nul 2>nul
mkdir %BUILDDIR%\%MODEL%     >nul 2>nul
copy src\runtime\*.c %BUILDDIR%\%MODEL% >nul
copy src\runtime\*.h %BUILDDIR%\%MODEL% >nul
cd %BUILDDIR%\%MODEL%
cl -nologo -c SYSTEM.c
cd %ROOTDIR%
goto :eof


:library
SET MODEL=2
call :initlibrary   || exit /b
call :runtime       || exit /b
call :cli           || exit /b
call :v4            || exit /b
call :ooc           || exit /b
call :ulm           || exit /b
call :pow32         || exit /b
call :misc          || exit /b
call :s3            || exit /b
call :ports         || exit /b
lib -nologo %BUILDDIR%\%MODEL%\*.obj -out:%BUILDDIR%\%MODEL%\lib%ONAME%-O%MODEL%.lib || exit /b

SET MODEL=C
call :initlibrary   || exit /b
call :runtime       || exit /b
lib -nologo %BUILDDIR%\%MODEL%\*.obj -out:%BUILDDIR%\%MODEL%\lib%ONAME%-O%MODEL%.lib || exit /b
goto :eof








