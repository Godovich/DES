@echo off

rem Get Current Drive
SET Drive=%~d0

rem Write Dosbox Config File
@echo [autoexec]> dosbox.conf
@echo mount %Drive:~0,-1%: %Drive:~0,-1%:\ >> dosbox.conf
@echo %Drive:~0,-1%: >> dosbox.conf
@echo cd %CD%\Backst~1\Utils >> dosbox.conf
@echo cycles=max >> dosbox.conf
@echo cls>>dosbox.conf
@echo @echo  DOSBox, v0.74 >> dosbox.conf
@echo @echo  - Including Scripts Written by Eyal Godovich (18.01.2014) >> dosbox.conf
@echo @echo  - Commands: - Run   [name] >> dosbox.conf
@echo @echo              - Debug [name] >> dosbox.conf
@echo @echo              - New   [name] >> dosbox.conf

start Backstage\DOSBox-0.74\DOSBox.exe
exit