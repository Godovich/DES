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
;	Name     : PrintNumDebug
;	Usage    : Console_PrintNumDebug
;	Desc     : Prints a number to the screen
;	Source	 : Gvahim.asm
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_PrintNumDebug number
	local @@positive
	
	; Save bx
    Base_PushRegisters <bx, ax>
	
    mov ax, number
    Console_PrintNumberByBase ax, 16
    
	; Print "h ("
    Console_PrintChar 'h'
    Console_PrintChar ' '
    Console_PrintChar '('

	; Print the number
    Console_PrintNumberByBase ax, 10

	; Print ")"
    Console_PrintChar ')'
	
	; Check if is a negative number
	test ax, ax
	jns @@positive
	
	; Print ' -'
    Console_PrintChar ' '
    Console_PrintChar '-'
	
	; Turn to positive (Two's complement)
	neg ax
	
	; Print the number
    Console_PrintNumberByBase ax, 10
	
	@@positive:
		; Print new line
		Console_NewLine
		
		; Restore the original value of ax & bx
		Base_PopRegisters <ax, bx>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : ClearScreen
;	Usage    : Console_ClearScreen
;	Desc     : Clears the screen
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Console_ClearScreen
	mov ah, 0
	mov al, 3
	int 10h
endm

macro Console_Exit msg
	Console_ClearScreen
	Console_WriteLine ' ------------------------------------------------------------------------------' 
	Console_WriteLine '                                     Error!' 
	Console_WriteLine ' ------------------------------------------------------------------------------' 
	Console_NewLine
	Console_Write ' '
	Console_WriteLine msg
	Console_WriteLine ' ------------------------------------------------------------------------------' 
	
	mov ax, 4c00h
	int 21h
endm

macro Console_PrintHeader
	local @@skip, @@encryption, @@decryption
	
	Console_WriteLine ' ------------------------------------------------------------------------------' 
	Console_Write '  DES Cipher System by Eyal Godovich'
	
	cmp [encryption], 1
	je @@encryption
	
	cmp [encryption], 2
	je @@decryption
	
	jmp @@skip
	
	@@decryption:
	Console_Write '                           Mode: Decryption'
	jmp @@skip
	
	@@encryption:
	Console_Write '                           Mode: Encryption'
	
	@@skip:
	Console_NewLine
	Console_WriteLine ' ------------------------------------------------------------------------------' 
	Console_WriteLine
endm