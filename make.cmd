@echo off

:: mscmake.cmd - Build Oberon with Microsoft C compiler.

:: Expects the path to include cl.exe.

:: As of 10th Feb 2016 the miscrosoft c compiler and build tools
:: can be downloaded independently of  the full Visual Studio IDE
:: as the 'Visual C++ Build Tools 2015'.

:: See: https://blogs.msdn.microsoft.com/vcblog/2015/11/02/announcing-visual-c-build-tools-2015-standalone-c-tools-for-build-environments/

:: With this installed, from the start button select:
::   All Apps / Visual C++ Build Tools / Visual C++ x86 Native Build Tools Command Prompt


:: Create configuration and parameter files.

cl -nologo -Isrc\system src\tools\make\configure.c >nul
setlocal
configure.exe >nul
del configure.obj configure.exe 2>nul

:: Extract make variables into local environment

for /F "delims='=' tokens=1,2" %%a in (Configuration.make) do set %%a=%%b

set FLAVOUR=%OS%.%DATAMODEL%.%COMPILER%
set BUILDDIR=build\%FLAVOUR%
set VISHAP=%ONAME%%BINEXT%

for /F %%d in ('cd');do set ROOTDIR=%%d



:: Process target parameter

if "%1" equ "" (
  call :usage
) else (
  call :%1
)
endlocal
goto :eof




:usage
@echo.
@echo Usage:
@echo.
@echo.  make full          - Make and install compiler (from administrator prompt)
@echo.
@echo.  make clean         - Remove made files
@echo.  make compiler      - Build the compiler but not the library
@echo.  make library       - Build all library files and make library
@echo.  make install       - Install built compiler and library (from administrator prompt)
goto :eof




:full
call :clean      || exit /b
call :compiler   || exit /b
call :browsercmd || exit /b
call :library    || exit /b
call :install    || exit /b
goto :eof




:compiler
call :translate || exit /b
call :assemble  || exit /b
goto :eof




:library
call :v4            || exit /b
call :ooc2          || exit /b
call :ooc           || exit /b
call :ulm           || exit /b
call :pow32         || exit /b
call :misc          || exit /b
call :s3            || exit /b
call :librarybinary || exit /b
goto :eof




:clean
rd /s /q %BUILDDIR% 2>nul
del /q %VISHAP% 2>nul
goto :eof




:assemble
echo.
echo.make assemble - compiling Oberon compiler c source::
echo.  VERSION:   %VERSION%
echo.  Target characeristics:
echo.    PLATFORM:  %PLATFORM%
echo.    OS:        %OS%
echo.    BUILDDIR:  %BUILDDIR%
echo.  Oberon characteristics:
echo.    INTSIZE:   %INTSIZE%
echo.    ADRSIZE:   %ADRSIZE%
echo.    ALIGNMENT: %ALIGNMENT%
echo.  C compiler:
echo.    COMPILER:  %COMPILER%
echo.    COMPILE:   %COMPILE%
echo.    DATAMODEL: %DATAMODEL%

cd %BUILDDIR%

cl -nologo /Zi -c SYSTEM.c  Configuration.c Platform.c Heap.c   || exit /b
cl -nologo /Zi -c Console.c Strings.c       Modules.c  Files.c  || exit /b
cl -nologo /Zi -c Reals.c   Texts.c         vt100.c    errors.c || exit /b
cl -nologo /Zi -c OPM.c     extTools.c      OPS.c      OPT.c    || exit /b
cl -nologo /Zi -c OPC.c     OPV.c           OPB.c      OPP.c    || exit /b

cl -nologo /Zi Vishap.c /Fe%ROOTDIR%\%VISHAP% ^
SYSTEM.obj Configuration.obj Platform.obj Heap.obj ^
Console.obj Strings.obj Modules.obj Files.obj ^
Reals.obj Texts.obj vt100.obj errors.obj ^
OPM.obj extTools.obj OPS.obj OPT.obj ^
OPC.obj OPV.obj OPB.obj OPP.obj || exit /b

echo.%VISHAP% created.
cd %ROOTDIR%
goto :eof




:compilefromsavedsource
echo.Populating clean build directory from bootstrap C sources.
mkdir %BUILDDIR% >nul 2>nul
copy bootstrap\%PLATFORM%-%ADRSIZE%%ALIGNMENT%\*.* %BUILDDIR% >nul
call :assemble || exit /b
goto :eof




:translate
:: Make sure we have an oberon compiler binary: if we built one earlier we'll use it,
:: otherwise use one of the saved sets of C sources in the bootstrap directory.
if not exist %VISHAP% call :compilefromsavedsource

echo.
echo.make translate - translating compiler source:
echo.  PLATFORM:  %PLATFORM%
echo.  INTSIZE:   %INTSIZE%
echo.  ADRSIZE:   %ADRSIZE%
echo.  ALIGNMENT: %ALIGNMENT%

md %BUILDDIR% 2>nul
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../Configuration.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/Platform%PLATFORM%.Mod || exit /b
%ROOTDIR%\%VISHAP% -SFsapx -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/Heap.Mod               || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/Console.Mod            || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/v4/Strings.Mod        || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/v4/Modules.Mod        || exit /b
%ROOTDIR%\%VISHAP% -SFsx   -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/system/Files.Mod              || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/v4/Reals.Mod          || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/v4/Texts.Mod          || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/library/misc/vt100.Mod        || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/errors.Mod           || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPM.cmdln.Mod        || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/extTools.Mod         || exit /b
%ROOTDIR%\%VISHAP% -SFsx   -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPS.Mod              || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPT.Mod              || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPC.Mod              || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPV.Mod              || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPB.Mod              || exit /b
%ROOTDIR%\%VISHAP% -SFs    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/OPP.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Ssm    -B%INTSIZE%%ADRSIZE%%ALIGNMENT%  ../../src/compiler/Vishap.Mod           || exit /b
cd %ROOTDIR%
copy src\system\*.c %BUILDDIR% >nul
copy src\system\*.h %BUILDDIR% >nul
echo.%BUILDDIR% filled with compiler C source.
goto :eof




:browsercmd
echo.
echo.Making symbol browser
cd %BUILDDIR%
%ROOTDIR%/%VISHAP% -Sm ../../src/tools/browser/BrowserCmd.Mod
cl -nologo BrowserCmd.c /Feshowdef.exe ^
  Platform.obj Texts.obj OPT.obj Heap.obj Console.obj SYSTEM.obj OPM.obj OPS.obj OPV.obj ^
  Files.obj Reals.obj Modules.obj vt100.obj errors.obj Configuration.obj Strings.obj ^
  OPC.obj
cd %ROOTDIR%
goto :eof




:install
whoami /groups | find "12288" >nul
if errorlevel 1 (
echo make install - administrator rights required. Please run under an administrator command prompt.
goto :eof
)
rmdir /s /q "%INSTALLDIR%"                            >nul 2>&1
mkdir "%INSTALLDIR%"                                  >nul 2>&1
mkdir "%INSTALLDIR%\bin"                              >nul 2>&1
mkdir "%INSTALLDIR%\include"                          >nul 2>&1
mkdir "%INSTALLDIR%\sym"                              >nul 2>&1
mkdir "%INSTALLDIR%\lib"                              >nul 2>&1
copy %BUILDDIR%\*.h            "%INSTALLDIR%\include" >nul
copy %BUILDDIR%\*.sym          "%INSTALLDIR%\sym"     >nul
copy %VISHAP%                  "%INSTALLDIR%\bin"     >nul
copy %BUILDDIR%\showdef.exe    "%INSTALLDIR%\bin"     >nul
copy %BUILDDIR%\lib%ONAME%.lib "%INSTALLDIR%\lib"     >nul
echo.
echo.Now add "%INSTALLDIR%\bin" to your path.
goto :eof


:uninstall
whoami /groups | find "12288" >nul
if errorlevel 1 (
echo make uninstall - administrator rights required. Please run under an administrator command prompt.
goto :eof
)
rmdir /s /q "%INSTALLDIR%" >nul 2>&1
goto :eof




:v4
echo.
echo.Making V4 library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/v4/Args.Mod                      || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/v4/Printer.Mod                   || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/v4/Sets.Mod                      || exit /b
cd %ROOTDIR%
goto :eof

:ooc2
echo.Making ooc2 library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2Strings.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2Ascii.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2CharClass.Mod           || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2ConvTypes.Mod           || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2IntConv.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2IntStr.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc2/ooc2Real0.Mod               || exit /b
cd %ROOTDIR%
goto :eof

:ooc
echo.Making ooc library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLowReal.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLowLReal.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocRealMath.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocOakMath.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLRealMath.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLongInts.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocComplexMath.Mod           || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLComplexMath.Mod          || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocAscii.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocCharClass.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocStrings.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocConvTypes.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLRealConv.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocLRealStr.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocRealConv.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocRealStr.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocIntConv.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocIntStr.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocMsg.Mod                   || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocSysClock.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocTime.Mod                  || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocChannel.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocStrings2.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocRts.Mod                   || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocFilenames.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocTextRider.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocBinaryRider.Mod           || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocJulianDay.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocFilenames.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocwrapperlibc.Mod           || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ooc/oocC%DATAMODEL%.Mod          || exit /b
cd %ROOTDIR%
goto :eof

:oocX11
echo No X11 support on plain Windows - use cygwin and build with cygwin make.
goto :eof

:ulm
echo.Making ulm library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmObjects.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPriorities.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmDisciplines.Mod           || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmServices.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSys.Mod                   || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSYSTEM.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmEvents.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmProcess.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmResources.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmForwarders.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmRelatedEvents.Mod         || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTypes.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmStreams.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmStrings.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysTypes.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTexts.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysConversions.Mod        || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmErrors.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysErrors.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysStat.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmASCII.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSets.Mod                  || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmIO.Mod                    || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmAssertions.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmIndirectDisciplines.Mod   || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmStreamDisciplines.Mod     || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmIEEE.Mod                  || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmMC68881.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmReals.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPrint.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmWrite.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmConstStrings.Mod          || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPlotters.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmSysIO.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmLoader.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmNetIO.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPersistentObjects.Mod     || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmPersistentDisciplines.Mod || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmOperations.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmScales.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTimes.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmClocks.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTimers.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmConditions.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmStreamConditions.Mod      || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTimeConditions.Mod        || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmCiphers.Mod               || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmCipherOps.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmBlockCiphers.Mod          || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmAsymmetricCiphers.Mod     || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmConclusions.Mod           || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmRandomGenerators.Mod      || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmTCrypt.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/ulm/ulmIntOperations.Mod         || exit /b
cd %ROOTDIR%
goto :eof

:pow32
echo.Making pow32 library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/pow/powStrings.Mod               || exit /b
cd %ROOTDIR%
goto :eof

:misc
echo.Making misc library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/system/Oberon.Mod                        || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/crt.Mod                     || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/Listen.Mod                  || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/MersenneTwister.Mod         || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/MultiArrays.Mod             || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/misc/MultiArrayRiders.Mod        || exit /b
cd %ROOTDIR%
goto :eof

:s3
echo.Making s3 library
cd %BUILDDIR%
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethBTrees.Mod                 || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethMD5.Mod                    || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethSets.Mod                   || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlib.Mod                   || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibBuffers.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibInflate.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibDeflate.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibReaders.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZlibWriters.Mod            || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethZip.Mod                    || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethRandomNumbers.Mod          || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethGZReaders.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethGZWriters.Mod              || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethUnicode.Mod                || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethDates.Mod                  || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethReals.Mod                  || exit /b
%ROOTDIR%\%VISHAP% -Fs ../../src/library/s3/ethStrings.Mod                || exit /b
cd %ROOTDIR%
goto :eof




:librarybinary
echo.
echo.Making lib%ONAME%
:: Remove objects that should not be part of the library
del /q %BUILDDIR%\Vishap.obj
:: Make static library
lib -nologo %BUILDDIR%\*.obj -out:%BUILDDIR%\lib%ONAME%.lib || exit /b
goto :eof







