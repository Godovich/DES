@echo off
cycles = max
TASM.EXE /z /zi ..\Codes\%1
TLINK.exe /v %1

cls
%1
cycles = auto
echo.
echo.