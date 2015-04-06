@echo off

cls

echo =========================================
echo =      Runnning Turbo Assembler         =
echo =========================================

..\Tasm\Bin\TASM.EXE /zi ..\..\Codes\%1
CHOICE /C Do you wish to continue

IF errorlevel 2 goto end
IF errorlevel 1 goto tlink


:tlink
cls
echo.
echo =========================================
echo =           Runnning TLINK              =
echo =========================================

..\Tasm\Bin\TLINK.exe /v %1

CHOICE /C Do you wish to continue

IF errorlevel 2 goto end
IF errorlevel 1 goto td

goto end

:td
cls
echo.
echo =========================================
echo =             Runnning TD               =  
echo =========================================

..\Tasm\Bin\TD.EXE %1
goto end


:end
cls
echo.
