@echo off
..\Tasm\Bin\TASM.EXE /zi ..\..\Codes\%1
..\Tasm\Bin\TLINK.exe /v %1

cls
%1
echo.
