; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Thu, 19 Mar 2015 16:58:22
; 	Author   : Eyal Godovich 
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

macro Encrypt_Run MODE
	local @@ForLoop, @@whileLoop, @@Reg, @@Next


	; if(Mode-1 == 0) / if the mode is encryption
	IFE MODE-1

		; Encryption content
		lea si, [inputFileContent]

	ELSE 

		; Fix the block problem, we need an input of atleast 8 characters.
		sub [inputFileSize], 16
		lea si, [inputFileContentDec]
	ENDIF

	@@whileLoop:
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Create Left
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	; Load double-word from the string in SI into eax
	lodsd		
	
	; Reverse bit order
	xchg  ah, al
	ror   eax, 16
	xchg  ah, al
	
	; Set left
	mov [Left], eax
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Create right
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	; Load double-word from the string in SI into eax
	lodsd		
	
	; Reverse bit order
	xchg  ah, al
	ror   eax, 16
	xchg  ah, al
	
	; Set right
	mov [Right], eax

	;------------------------------------------------------------
	; Permute each 64 byte chunk by IP
	;------------------------------------------------------------
	Perm_Perform Left, Right, 4 , 0f0f0f0fh
	Perm_Perform Left, Right, 16, 0000ffffh
	Perm_Perform Right, Left, 2 , 33333333h
	Perm_Perform Right, Left, 8 , 00ff00ffh
	Perm_Perform Left, Right, 1 , 55555555h

	;------------------------------------------------------------
	; Shift left and right by 1
	;------------------------------------------------------------
	; http://stackoverflow.com/a/812039

	mov edx, [Left]
	shr edx, 31
	and edx, 1
	shl [Left], 1
	or [Left], edx
	
	mov edx, [Right]
	shr edx, 31
	and edx, 1
	shl [Right], 1
	or [Right], edx

	;------------------------------------------------------------
	; Now go through and perform the encryption or decryption  
	;------------------------------------------------------------
	
	num = 0
	REPT 16

		iteration = 0
		REPT 2
			IF Mode eq 0
				mov bx, 30 - num
			ELSE
				mov bx, num
			ENDIF

			IF iteration eq 1
				inc bx
			ENDIF

			imul bx, 4d
			mov edx, [dword ptr Keys + bx]
			
			IF iteration eq 0
				mov [Key1], edx
			ELSE
				mov [Key2], edx
			ENDIF

			iteration = 1
		endm

		mov edx, [Right]
		mov eax, [Key1]
		xor edx, eax
		mov [Right1], edx
		
		mov edx, [Right]
		ZFShr edx, 4
		mov eax, [Right]
		shl eax, 28d
		and eax, 0ffffffffh
		or edx, eax ; | is like + in this case
		xor edx, [Key2]
		mov [Right2], edx
		
		Swap Left, Right
		
		count = 24
		half = 0
		IRP Array, <spfunction2, spfunction4, spfunction6, spfunction8, spfunction1, spfunction3, spfunction5, spfunction7>

			IF half eq 0 
				mov ebx, [Right1]
			ELSE
				mov ebx, [Right2]
			ENDIF

			shr ebx, count
			and ebx, 255d
			and ebx, 3Fh
			imul bx, 4d
			
			; if it's the first time of the first half
			IF count eq 24
				IF half eq 0
					mov edx, [dword ptr Array + bx]
				ENDIF
			ENDIF

			or edx, [dword ptr Array + bx]

			count = count - 8

			IF count eq -8
				half = 1
				count = 24
			ENDIF
		endm
		
		xor [Right], edx

		num = num + 2
	endm

	Swap Left, Right
	
	mov edx, [Left]
	ZFShr edx, 1
	mov eax, [Left]
	shl eax, 31
	xor edx, eax
	mov [Left], edx
	
	mov edx, [Right]
	ZFShr edx, 1
	mov eax, [Right]
	shl eax, 31
	xor edx, eax
	mov [Right], edx
	
	;------------------------------------------------------------
	; Perform IP-1, which is IP in the opposite direction
	;------------------------------------------------------------
	Perm_Perform Left, Right, 1 , 55555555h
	Perm_Perform Right, Left, 8 , 00ff00ffh
	Perm_Perform Right, Left, 2 , 33333333h
	Perm_Perform Left, Right, 16, 0000ffffh
	Perm_Perform Left, Right, 4 , 0f0f0f0fh
	
	;------------------------------------------------------------
	; Debugging: Print Right
	;------------------------------------------------------------
	; call NEW_LINE
	; print 'Right: '
	; mov edx, [Right]
	; DEBUG_REG_32 edx
	
	
	;------------------------------------------------------------
	; Print the final string!
	;------------------------------------------------------------

		; encryption

		IFE Mode-1

			BY = 24
			IS_RIGHT = 0

			REPT 8
				
				IF IS_RIGHT EQ 0
					mov eax, [Left]
				ELSE 
					mov eax, [Right]
				ENDIF

				IFE BY EQ 0 
					ZFShr eax, BY
				ENDIF

				and eax, 0FFh
			 	call AddAxHexChar

				BY = BY - 8

				IF BY EQ 0
					IS_RIGHT = 1
					BY = 24
				ENDIF
			endm

		ELSE

			SHR_BY = 24
			CURRENT_PART = Left
			REPT 8
				mov eax, [CURRENT_PART]
				
				; We dont want to shift by zero!
				IFE SHR_BY EQ 0
					ZFShr eax, SHR_BY
				ENDIF

				; We only need the rightest part of the integer
				and eax, 0FFh

				; Add the character
				call AddChar

				; Substract 8 from the count, next part.
				SHR_BY = SHR_BY - 8

				; If the left part is done, move to the right part
				IF SHR_BY EQ -8
					CURRENT_PART = Right
					SHR_BY = 24
				ENDIF
			endm
		ENDIF
		
	add [m], 8d
	mov ax, [m]
	cmp ax, [inputFileSize]
	JLE @@whileLoop

	mov bx, [outputc]
	mov [output + bx], 0h
	lea si, [output]
	call PRINT_STR

endm

proc AddAxHexChar
	
	;call PRINT_NUM_HEX_WITHOUT_H ; al is what we want
	mov ah, al
	shr ah, 4
	call AddAH
	
	mov ah, al
	and ah, 0Fh
	call AddAH
	
	ret
endp

proc AddAH

	push ax
	
	mov al, ah
	cmp al, 10
	JGE CharValue11
	JL NumValue
	
	CharValue11:
		sub al, 10d
		add al, 'A'

		jmp Finish11
	
	NumValue:
		add al, '0'
	
	
	Finish11:
	
	call AddChar

	pop ax
	ret
endp

proc AddChar

	mov bx, [outputc]
	
	mov [byte ptr output + bx], al

	inc [outputc]
	
	ret
endp

macro PUTC char
   push ax
   push dx


    mov  dl, char
    mov  ah, 02h
    int  21h

    pop ax
    pop dx

endm  

proc PRINT_STR
    push ax
    push si
    
@@CHAR_LOOP:
    lodsb
	or al, al ; we need to check if al is equal to zero
    jz   @@EXIT
    PUTC al
jmp  @@CHAR_LOOP

@@EXIT:
    pop  si
    pop  ax
    ret 
endp 

; Takes hex string from DecString and puts in EncDecString
proc hexToString
	
	; cx, 1 ; foreach two characters
	; CX - Length
	mov bx, 0
	mov dx, 0

	ForeachChar:
		mov ax, 0d
	
		mov ah, [inputFileContent + bx] ; Contains current char	

		; Check if al is a hex character
		String_IsHex ah
		cmp si, 1
		JNE @@ERROR_NOT_HEX
		
		cmp ah, 'A'
		JGE CharValue
		sub ah, '0'
		JMP After
		CharValue:
			and ah, '_' ; To upper case 
			sub ah, 'A'
			add ah, 10

		After: 
		inc bx
		mov al, [inputFileContent + bx] ; Contains current char	
		
		; Check if al is a hex character
		String_IsHex al
		cmp si, 1
		JNE @@ERROR_NOT_HEX

		cmp al, 'A'
		JGE CharValue1
		sub al, '0'
		JMP After1
		CharValue1:
			and al, '_'
			sub al, 'A'
			add al, 10

		After1: 
		shl ah, 4
		add ah, al
		
		push bx
		mov bx, dx
		mov [inputFileContentDec + bx], ah
		inc dx
		pop bx
		
	inc bx
	cmp bx, cx
	JNE ForeachChar

	mov [inputFileContentDec + bx], 0
	mov [inputFileSize], cx
	shr [inputFileSize], 1

	mov al, 2
	ret



	@@ERROR_NOT_HEX:
		Console_ClearScreen
		Console_PrintHeader	
		Console_WriteLine " Sorry, the program can only accept hex code for decryption."
		Console_WriteLine
		mov al, 1
	ret
endp