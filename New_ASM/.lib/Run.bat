@echo off
TASM.EXE /zi ..\Codes\%1
TLINK.exe /v %1

del %1.map
del %1.obj
del %1.tr

cls
%1
echo.
echo.
del %1.exe