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

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : IsHex
;	Usage    : String_IsHex 'a'
;	Desc     : Get's a character and tests to see if its a hex character ( A-F\a-f\0-9 ).
;              The result will be stored in dx.
;	ASCII    : http://www.asciitable.com/index/asciifull.gif
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro String_IsHex char
	local @@RETURN_NO, @@RETURN_YES, @@EXIT

	; 0-9
	cmp char, '0'
	JB @@RETURN_NO
	cmp char, ':'
	JB @@RETURN_YES

	; a-f
	cmp char, 'f'
	JG @@RETURN_NO
	cmp char, 96
	JG @@RETURN_YES

	; A-F
	cmp char, 'F'
	JG @@RETURN_NO
	cmp char, '@'
	JG @@RETURN_YES

	jmp @@RETURN_NO

	@@RETURN_YES:
		mov dx, 1
		jmp @@EXIT


	@@RETURN_NO:
		mov dx, 0

	@@EXIT:
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : CharToASCII
;	Usage    : String_CharToASCII 'a'
;	Desc     : Get's the ascii value of a character
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro String_CharToASCII char
	local @@CHAR_VALUE, @@RETURN_YES, @@EXIT
	
	cmp char, 'A'
	JGE @@CHAR_VALUE
	sub char, '0'
	JMP @@EXIT

	@@CHAR_VALUE:
		and char, '_' ; To upper case 
		sub char, 'A'
		add char, 10

	@@EXIT:
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintUpTo
;	Usage    : String_PrintUpTo 1
;	Desc     : Print a limited number of characters from the string that is stored in memory
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro String_PrintUpTo xChars
	local @@CHAR_LOOP, @@EXIT

	push cx
	push ax

	mov cx, 0

	@@CHAR_LOOP:
		lodsb
		or al, al
		jz @@EXIT
		
		; Print the character
		mov  dl, al
		mov  ah, 02h
		int  21h

		; if (++cx < x) goto @@CHAR_LOOP
		inc cx
		cmp cx, xChars
		JNE @@CHAR_LOOP

	; If the string is bigger than x chars print "..."
	Console_Write '...'

	@@EXIT:
	
	pop ax
	pop cx

endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : AddHexToResult
;	Usage    : String_AddHexToResult 1
;	Desc     : Print a limited number of characters from the string that is stored in memory
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro String_AddHexToResult char
	local @@skip, @@add

	cmp char, 10d
	jge @@add
	jmp @@skip

	@@add:
	add char, 7d

	@@skip:
	
	add char, '0'
	mov bx, [outputc]
	mov [output + bx], char
	inc [outputc]
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : TrimNonsense
;	Usage    : String_TrimNonsense output
;	Desc     : Return's the true length of the string
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro String_TrimNonsense string
	local @@CHAR_LOOP, @@EXIT, @@REMOVE
	
	; Save the current value of ax & si
	Base_PushRegisters <ax, si>
	
	lea si, [string]
	mov bx, 0

	@@CHAR_LOOP:
		lodsb 	  			 ; Load byte from the string in SI
		or al, al 			 ; Update the zero-flag
		jz   @@EXIT 		 ; The string ends in a zero, so, if found, exit

		cmp al, 0E6h
		je @@EXIT

		inc bx
		jmp @@CHAR_LOOP


	@@EXIT:
		; Restore the original value of ax & si
		Base_PopRegisters <si, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : JmpNotHex
;	Usage    : String_JmpNotHex @@LABEL_ERRROR
;	Desc     : Translates the hex and jumps to a specified label incase of error
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro String_JmpNotHex label
	local @@CHAR_LOOP

	Base_PushRegisters <ax, bx, cx, dx, si>

	; Clear the counter variable
	xor cx, cx

	; Load the string to the memory
	lea si, [inputFileContent]
	
	@@CHAR_LOOP:
		lodsb 	  			 ; Load byte from the string in SI
		mov ah, al           ; Move the byte to ah
		lodsb				 ; Load byte from the string in SI
		
		; Check if the first character is a hex character
		String_IsHex al
		cmp dx, 1
		JNE label

		; Check if the second character is a hex character
		String_IsHex ah
		cmp dx, 1
		JNE label

		; Get the acsii value of both characters
		String_CharToASCII al
		String_CharToASCII ah

		; Set the first character as the higher-nibble
		shl ah, 4
		add ah, al

		; Set the next character in the string
		mov bx, cx
		shr bx, 1 ; Divide by two
		mov [inputFileContentDec + bx], ah

		; We used 2 bytes, so let's add them to our count
		add cx, 2

		; if( BytesChecked < BytesTotal )
		cmp cx, [inputFileSize]
		jne  @@CHAR_LOOP	 ; And now to the next character

	Base_PopRegisters <si, dx, cx, bx, ax>
endm
