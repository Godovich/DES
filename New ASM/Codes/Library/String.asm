; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Fri, 13 Mar 2015 15:37:43
; 	Author   : Eyal Godovich 
; 	File     : String.asm
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : GetSize
;	Usage    : String_GetSize ax
;	Desc     : Writes the length of the string that is stored in si to the chosen register.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro String_GetSize dst
	local @@CHAR_LOOP, @@EXIT
	
	; Save the current value of ax & si
	Base_PushRegisters <ax, si>

	; Reset the counter
	xor dst, dst
	
	@@CHAR_LOOP:
		lodsb 	  			 ; Load byte from the string in SI
		or al, al 			 ; Update the zero-flag
		jz   @@EXIT 		 ; The string ends in a zero, so, if found, exit
		inc dst				 ; Increase by one
		jmp  @@CHAR_LOOP	 ; And now to the next character

	@@EXIT:
		; Restore the original value of ax & si
		Base_PopRegisters <si, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Scan
;	Usage    : String_Scan SomeVariable, 10
;	Desc     : Receives input string from the user 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro String_Scan string, maxStringLength
	local @@READ_CHAR, @@HANDLE_BACKSPACE, @@DONE
	
	; Saves the current values of ax, bx, cx & si
	Base_PushRegisters <ax, bx, cx, si>
	
	; Reset counter
	mov bx, 0
	
	@@READ_CHAR:
		
		; Read letter from keyboard
		xor ax, ax
		int 16h
		
		; If new line character is received then end input
		cmp al, 13
		je @@DONE
		
		; Backspace
		cmp al, 8
		je @@HANDLE_BACKSPACE
		
		; Check if the input reached the maximum
		cmp bx, maxStringLength
		je @@READ_CHAR
		
		; Print the character
		Console_PrintChar al
		
		; Add the character to the string
		mov [string + bx], al
		
		; Increase the counter
		inc bx
		
		; And... to the next one!
		jmp @@READ_CHAR
		
	@@HANDLE_BACKSPACE:
	
		; If it's the first char just receive another one
		or bx, bx
		jz @@READ_CHAR
		
		; If it's not the first character, subtract one from the counter.
		dec bx
		
		; Print backspace, space, and backspace again (to hide the character)
		Console_PrintChar 8
		Console_PrintChar 32
		Console_PrintChar 8
		
		; Next character
		jmp @@READ_CHAR
	
	@@DONE:
		; Put ascii zero in the end
		mov [byte string + bx], 0
		Console_NewLine
		
		; Restore the original value of ax, bx, cx & si
		Base_PopRegisters <si, cx, bx, ax>
endm