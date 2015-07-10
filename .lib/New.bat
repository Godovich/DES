@echo off

if exist ..\..\Codes\%1.asm echo File Exists
if exist ..\..\Codes\%1.asm goto exit

echo IDEAL >> ..\..\Codes\%1.asm
echo MODEL small >> ..\..\Codes\%1.asm
echo STACK 100h >> ..\..\Codes\%1.asm

echo. >> ..\..\Codes\%1.asm
echo DATASEG >> ..\..\Codes\%1.asm

echo. >> ..\..\Codes\%1.asm
echo ;------------------------ >> ..\..\Codes\%1.asm
echo ; Your Variables Here     >> ..\..\Codes\%1.asm
echo ;------------------------ >> ..\..\Codes\%1.asm

echo. >> ..\..\Codes\%1.asm
echo CODESEG >> ..\..\Codes\%1.asm
echo start: >> ..\..\Codes\%1.asm
echo 	mov ax, @data >> ..\..\Codes\%1.asm
echo 	mov ds, ax >> ..\..\Codes\%1.asm
echo. >> ..\..\Codes\%1.asm
echo. >> ..\..\Codes\%1.asm
echo ;------------------------ >> ..\..\Codes\%1.asm
echo ; Your Code Here >> ..\..\Codes\%1.asm
echo ;------------------------ >> ..\..\Codes\%1.asm

echo. >> ..\..\Codes\%1.asm
echo exit: >> ..\..\Codes\%1.asm
echo 	mov ax, 4c00h >> ..\..\Codes\%1.asm
echo 	int 21h>> ..\..\Codes\%1.asm
echo END start>> ..\..\Codes\%1.asm

echo Created!
:exit