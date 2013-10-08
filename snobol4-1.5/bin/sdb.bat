@echo off
rem $Id: sdb.bat,v 1.6 2013/09/24 00:18:39 phil Exp $
rem Snobol4 DeBugger batch file for Windows
rem Phil Budne 8/14/2013

setlocal
set BINDIR=%~dp0
set LIBDIR=%BINDIR%\..\lib

rem NOTE!! This environment variable is used by sdb.sno!!
set SDB_LISTFILE=%TMP%\sdb-%RANDOM%-%TIME:~6,5%.lst

rem start in new window -- less interference with ^C trapping???
start %BINDIR%\snobol4 -l %SDB_LISTFILE% -L %LIBDIR%\sdb.sno %*
