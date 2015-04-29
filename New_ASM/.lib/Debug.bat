@echo off
cycles=max
cls
echo.
echo =                             Runnning TASM                                    =

TASM.EXE /zi ..\Codes\%1
CHOICE /C Do you wish to continue

IF errorlevel 2 goto end
IF errorlevel 1 goto tlink


:tlink
cls
echo.
echo =                             Runnning TLINK                                   =

TLINK.exe /v %1

CHOICE /C Do you wish to continue

IF errorlevel 2 goto end
IF errorlevel 1 goto td

goto end

:td
cls
echo.
echo =                             Runnning TD                                      =

TD.EXE %1
goto end


:end
cls
echo.
cycles=auto
