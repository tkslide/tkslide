@echo off
:: $Id: timing.bat,v 1.10 2020-07-03 00:31:02 phil Exp $
:: Phil Budne 8/14/2013
:: Updated 7/2/2020

setlocal
set "BINDIR=%~dp0"
set "OLD=%CD%"

set "TMPDIR=%TMP%\sno-timing-%RANDOM%-%TIME:~6,5%"

if exist "%TMPDIR%" rmdir "%TMPDIR%" /Q /S
mkdir "%TMPDIR%"

copy "%BINDIR%..\timing\*.*" "%TMPDIR%" >"%TMPDIR%\copy.out"
cd /d "%TMPDIR%"

rem output progress to stderr:
"%BINDIR%snobol4" -sx bench.sno v311.sil 2>stderr
set STATUS=%ERRORLEVEL%
if %STATUS% GEQ 1 (
   echo bench.sno failed with status %STATUS% 1>&2
   type stderr 1>&2
   cd "%OLD%"
   rmdir "%TMPDIR%" /Q /S
   exit /B %STATUS
)
rem ================
rem now create output file

rem must be first:
echo timing.bat $Id: timing.bat,v 1.10 2020-07-03 00:31:02 phil Exp $
echo:


echo Date:
echo %date% %time%
echo:

echo ver:
ver
echo:

echo PROCESSOR_ARCHITECTURE:
echo %PROCESSOR_ARCHITECTURE%
echo:

echo PROCESSOR_IDENTIFIER:
echo %PROCESSOR_IDENTIFIER%
echo:

echo hostname:
hostname
echo:

echo cpuid:
"%BINDIR%cpuid"
echo:

echo Ids:
find "Id:" bench.sno v311.sil timing.sno
echo:

echo getting system info 1>&2
systeminfo > sysinfo.out

echo systeminfo:
:: OS info; gets BIOS Version too!
findstr /C:"OS " sysinfo.out
:: Manufacturer & Model
findstr /C:"System M" sysinfo.out
findstr /C:Memory sysinfo.out
echo:

echo running timing.sno:
"%BINDIR%snobol4" -b timing.sno < stderr
echo:

echo END

cd "%OLD%"
rmdir "%TMPDIR%" /Q /S
