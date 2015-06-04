; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Tue, 17 Mar 2015 11:33:11
; 	Author   : Eyal Godovich 
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

.386 			; Generate 32-bit code instead of 16.

IDEAL			; Syntax: IDEAL
MODEL small		; One DS and one CS Please.
STACK 100h		; Define the stack size
radix 10		; Our default radix will be decimal

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; *********************           Data Segment           ********************
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DATASEG
inputHandle dw 0
outputHandle dw 0

inputSize   dd 0
outputSize  dd 0
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; *********************           Code Segment           ********************
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CODESEG
	
	; include all of our necessary files
	include '..\Codes\Library\Base.asm'
	Base_Load <'..\Codes\Library\Console.asm', '..\Codes\Library\String.asm', '..\Codes\Library\File.asm', '..\Codes\Library\Debug.asm', '..\Codes\Perm.asm', '..\Codes\Key.asm', '..\Codes\Encrypt.asm'>
	

start:
	mov ax, @data
	mov ds, ax

	; Get input file size
	File_Open '..\INPUT.txt', 2,  inputHandle
	mov al, 2d ; Move to the end
	mov bx, [inputHandle]
	xor cx, cx ; Move 0 bytes
	xor dx, dx ; Move 0 bytes
	mov edx, 0
	mov ah, 42h
	int 21h
	shl edx, 6d ; * 65535 / 1024
	shr eax, 10 ; / 1024
	mov ecx, edx
	add ecx, eax
	inc ecx
	mov [inputSize], ecx
	shl [inputSize], 1d
	Console_WriteLine 'Input size: '
	Debug_Register_32 ecx, 16d
	File_Close inputHandle
	
	Console_WriteLine 
	
	File_Open '..\OUTPUT.txt', 2,  outputHandle
	mov al, 2d ; Move to the end
	mov bx, [outputHandle]
	xor cx, cx ; Move 0 bytes
	xor dx, dx ; Move 0 bytes
	mov edx, 0
	mov ah, 42h
	int 21h
	shl edx, 6d ; * 65535 / 1024
	shr eax, 10 ; / 1024
	mov ecx, edx
	add ecx, eax
	inc ecx
	mov [outputSize], ecx
	File_Close outputHandle
	
	
	; EAX = (output*100)/input
	mov eax, [outputSize]
	mov ebx, 100d
	mul ebx
	mov ebx, [inputSize]
	div ebx
	Console_WriteLine ' Precent: '
	Debug_Register_32 eax, 10d
	Console_Write '%'
	
exit:

	mov ax, 4c00h
	int 21h
END start
