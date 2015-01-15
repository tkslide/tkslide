@echo off
rem $Id: snopea.bat,v 1.1 2014/12/28 04:51:50 phil Exp $
rem SNOBOL4 tiny "POD" formatter
rem Phil Budne 12/27/2014

setlocal
set "BINDIR=%~dp0"
set "LIBDIR=%BINDIR%\..\lib"

"%BINDIR%\snobol4" "%LIBDIR%\snopeacmd.sno" %*
