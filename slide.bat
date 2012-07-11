@echo off
rem set TEMP=C:\temp
set SNOLIB="%CD\snobol4-1.2\lib"
"%CD%\runtime\tclkit.exe" "%CD%\tkslide.tcl" %1 %2 %3 %4 %5 %6 %7 %8 %9
