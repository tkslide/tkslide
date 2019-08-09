@echo off
:: Phil Budne 8/14/2013

setlocal
set "BINDIR=%~dp0"

echo timing.bat $Id: timing.bat,v 1.8 2014/12/28 00:07:30 phil Exp $
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
"%BINDIR%\cpuid"
echo:

cd /d "%BINDIR%\..\timing"
echo Ids:
find "Id:" bench.sno v311.sil timing.sno
echo:

echo running bench.sno:
"%BINDIR%\snobol4" -sx bench.sno v311.sil 2>stderr
echo:

echo running timing.sno:
"%BINDIR%\snobol4" -b timing.sno < stderr
echo:

echo END
