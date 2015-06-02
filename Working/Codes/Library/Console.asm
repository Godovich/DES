; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Fri, 13 Mar 2015 13:43:34
; 	Author   : Eyal Godovich 
; 	File     : Console.asm
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : WriteLine
;	Usage    : Console_WriteLine 'Hello world!'
;	Desc     : Writes the string, followed by the current line terminator, to the console
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_WriteLine string
	Console_Write string
	Console_NewLine
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Write
;	Usage    : Console_Write 'Hello world!'
;	Desc     : Writes the string to the console
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_Write string
	local @@start,@@msg ; Declare the local variable and the local label because we don't want any duplicates.

	; Save the current value of the registers
	Base_PushRegisters <ax, dx, ds>
	
	; Explantation: The string is being stored in the code segment instead of
	;				of the data segment, so we can skip over it.
	jmp @@start
	
	; Store the string, followd by a dollar sign.
	@@msg db string, '$'
	
	@@start:    
		
		; Switch batween the code segment and the data segment
		mov  ax,cs 
		mov  ds,ax
		
		; Now we'll print the string that is actually stored in the code segment, we tricked
		; the system, so it will take the string from the code segment instead of the data segment.
		mov  ah, 09h
		lea  dx, [cs:@@msg] 
		int  21h
	
	; Restore the previous value of the registers
	Base_PopRegisters <ds, dx, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : NewLine
;	Usage    : Console_NewLine
;	Desc     : Writes the current line terminator to the console
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_NewLine
	Console_PrintChar 10 ; New line ("\n")
	Console_PrintChar 13 ; Carriage return ("\r")
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintChar
;	Usage    : Console_PrintChar 'a'
;	Desc     : Prints the character to the screen 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_PrintChar char
    Base_PushRegisters <ax, dx>
    mov  dl, char
    mov  ah, 02h
    int  21h
    Base_PopRegisters <dx, ax>  
endm   

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintString
;	Usage    : Console_PrintString
;	Desc     : Prints a string ending with ascii 0
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_PrintString
	local @@CHAR_LOOP, @@EXIT
	
	Base_PushRegisters <ax, si>
    
	@@CHAR_LOOP:
		lodsb 	  			 ; Load byte from the string in SI
		or al, al 			 ; Update the zero-flag
		jz   @@EXIT 		 ; The string ends in a zero, so, if found, exit
		Console_PrintChar al ; Else, print the current character.
		jmp  @@CHAR_LOOP	 ; And now to the next character

	@@EXIT:
		Base_PopRegisters <si, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintNumberByBase
;	Usage    : Console_PrintNumberByBase
;	Desc     : Prints a number in base 2-16
;	Source	 : Gvahim.asm
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_PrintNumberByBase Number, Base
	local @@DIGIT_LOOP, @@PRINT
	
	Base_PushRegisters <ax, bx, cx, dx>
	
	mov ax, Number
	mov bx, Base
	mov cx, 0

	@@DIGIT_LOOP:
		xor dx, dx
		div bx  ; DX:AX / BX = AX and Remainder: DX
		push dx
		inc  cx
		cmp  ax, 0
		jne  @@DIGIT_LOOP

	@@PRINT:
	    pop  dx
		Console_PrintNibble dl
		loop @@PRINT

	Base_PopRegisters <dx, cx, bx, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintNubble
;	Usage    : Console_PrintNibble
;	Desc     : Prints a single number to the screen
;	Source	 : Gvahim.asm
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_PrintNibble nibble
	local @@DECIMAL
	
    Base_PushRegisters <ax, dx>
	mov dl, nibble
    cmp dl,9h
    jbe  @@DECIMAL

    add  dl,'A'-'0'-10

@@DECIMAL:
    add  dl,'0'
    mov  ah,02h
    int  21h
	
    Base_PopRegisters <dx, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : ClearScreen
;	Usage    : Console_ClearScreen
;	Desc     : Clears the screen
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_ClearScreen
	mov ax, 3
	int 10h
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintHeader
;	Usage    : Console_PrintHeader
;	Desc     : Print's the default program header
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
macro Console_PrintHeader
	local @@skip, @@encryption, @@decryption
	
	Console_PrintColoredString ' ------------------------------------------------------------------------------', 0Ch
	
	; I have no clue why, but it fixed the problem of the double new line
	Console_Write ' '
	
	Console_PrintColoredString '  DES Cipher System by Eyal Godovich', 0Ch
	
	cmp [encryption], '1'
	je @@encryption
	
	cmp [encryption], '2'
	je @@decryption
	
	jmp @@skip
	
	@@decryption:
	Console_PrintColoredString '                           Mode: Decryption', 0Ch
	jmp @@skip
	
	@@encryption:
	Console_PrintColoredString '                           Mode: Encryption',0Ch
	
	@@skip:
	Console_NewLine
	Console_PrintColoredString ' ------------------------------------------------------------------------------', 0Ch
	Console_WriteLine
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintColoredChar
;	Usage    : Console_PrintColoredChar 'a', 0Ch
;	Desc     : Prints the selected character in the selected color
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
macro Console_PrintColoredChar char, color
	Base_PushRegisters<ax, bx, cx, dx>

	mov ah, 09h
	mov al, char
	mov bh, 0
	mov bl, color
	mov cx, 1
	int 10h

	Console_CursorBack inc
	Base_PopRegisters <dx, cx, bx, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintColoredString
;	Usage    : Console_PrintColoredString 'abc', 0Ch
;	Desc     : Prints the string in color
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
macro Console_PrintColoredString string, color
	local @@START,@@MSG, @@CHAR_LOOP, @@EXIT ; Declare the local variable and the local label because we don't want any duplicates.

	; Save the current value of the registers
	Base_PushRegisters <ax, dx, ds>
	
	; Explantation: The string is being stored in the code segment instead of
	;				of the data segment, so we can skip over it.
	jmp @@START
	
	; Store the string, followd by a dollar sign.
	@@MSG db string, 0
	
	@@START:    
		
		; Switch batween the code segment and the data segment
		mov  ax,cs 
		mov  ds,ax

		lea si, [cs:@@MSG]
		
		@@CHAR_LOOP:
			lodsb 	  			 ; Load byte from the string in SI
			or al, al 			 ; Update the zero-flag
			jz   @@EXIT 		 ; The string ends in a zero, so, if found, exit
			mov bl, al
			Console_PrintColoredChar bl, color
			jmp  @@CHAR_LOOP	 ; And now to the next character

	@@EXIT:

	
	; Restore the previous value of the registers
	Base_PopRegisters <ds, dx, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Console_CursorBack
;	Usage    : Console_CursorBack inc | Console_CursorBack dec
;	Desc     : Move's the cursor back a step
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
macro Console_CursorBack mod
	Base_PushRegisters <ax, bx, dx>
	mov ah, 3
	int 10h

	mov ah, 2
	mov bh, 0
	mod dl
	int 10h

	Base_PopRegisters <dx, bx, ax>
endm
