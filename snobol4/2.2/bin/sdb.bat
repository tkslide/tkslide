@echo off
rem $Id: sdb.bat,v 1.9 2020-07-03 00:31:02 phil Exp $
rem Snobol4 DeBugger batch file for Windows
rem Phil Budne 8/14/2013
rem Updated 7/2/2020 for "run"

setlocal
set "BINDIR=%~dp0"
set "LIBDIR=%BINDIR%..\lib"

set SUFF=%RANDOM%-%TIME:~6,5%

rem environment variables used by sdb.sno:
set "SDB_LISTFILE=%TMP%\sdb-listing-%SUFF%"
set "SDB_BREAKPOINTS=%TMP%\sdb-bkpts-%RANDOM%-%TIME:~6,5%"

rem use "start" to start in a new window
:Loop
"%BINDIR%\snobol4" -l "%SDB_LISTFILE%" -L "%LIBDIR%\sdb.sno" %*
set SAVED=%ERRORLEVEL%
if exist %SDB_BREAKPOINTS% goto Loop

exit /B %SAVED%
