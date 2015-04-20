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
		sub [inputFileSize], 8
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
	IP Left, Right

	;------------------------------------------------------------
	; Shift left and right by 1
	;------------------------------------------------------------
	
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

	mov [i], 0
	@@ForLoop:
	
		IFE Mode-1
			jmp @@Reg
		ENDIF


		mov bx, 30d
		sub bx, [i]
		imul bx, 4d
		mov edx, [dword ptr Keys + bx]
		mov [Key1], edx
		
		mov bx, 31d
		sub bx, [i]
		imul bx, 4d
		mov edx, [dword ptr Keys + bx]
		mov [Key2], edx
		
		jmp @@Next
		
		@@Reg:
		mov bx, [i]
		imul bx, 4d
		mov edx, [dword ptr Keys + bx]
		mov [Key1], edx
		
		mov bx, [i]
		inc bx
		imul bx, 4d
		mov edx, [dword ptr Keys + bx]
		mov [Key2], edx
		
		@@Next:

		mov edx, [Right]
		mov eax, [Key1]
		xor edx, eax
		mov [Right1], edx
		
		mov edx, [Right]
		shr edx, 4d
		and edx, 268435455d
		mov eax, [Right]
		shl eax, 28d
		and eax, 0ffffffffh
		or edx, eax ; | is like + in this case
		xor edx, [Key2]
		mov [Right2], edx
		
		Swap Left, Right
		
		mov ebx, [Right1]
		shr ebx, 24d
		and ebx, 255d
		and ebx, 3Fh
		imul bx, 4d
		mov edx, [dword ptr spfunction2 + bx]

		mov ebx, [Right1]
		shr ebx, 16d
		and ebx, 65535d
		and ebx, 3Fh
		imul bx, 4d		
		mov eax, [dword ptr spfunction4 + bx]
		or edx, eax
		
		mov ebx, [Right1]
		shr ebx, 8d
		and ebx, 16777215d
		and ebx, 3Fh
		imul bx, 4d
		mov eax, [dword ptr spfunction6 + bx]
		or edx, eax
		
		mov ebx, [Right1]
		and ebx, 3Fh
		imul bx, 4d
		mov eax, [dword ptr spfunction8 + bx]
		or edx, eax
		
		mov ebx, [Right2]
		shr ebx, 24d
		and ebx, 255d
		and ebx, 3Fh
		imul bx, 4d
		mov eax, [dword ptr spfunction1 + bx]
		or edx, eax
		
		mov ebx, [Right2]
		shr ebx, 16d
		and ebx, 65535d
		and ebx, 3Fh
		imul bx, 4d
		mov eax, [dword ptr spfunction3 + bx]
		or edx, eax
		
		mov ebx, [Right2]
		shr ebx, 8d
		and ebx, 16777215d
		and ebx, 3Fh
		imul bx, 4d
		mov eax, [dword ptr spfunction5 + bx]
		or edx, eax
		
		mov ebx, [Right2]
		and ebx, 3Fh
		imul bx, 4d
		mov eax, [dword ptr spfunction7 + bx]
		or edx, eax
		
		xor [Right], edx
	
	add [i], 2
	cmp [i], 32
	JNE @@ForLoop


	Swap Left, Right
	
	mov edx, [Left]
	shr edx, 1
	and edx, 2147483647d
	mov eax, [Left]
	shl eax, 31
	xor edx, eax
	mov [Left], edx
	
	mov edx, [Right]
	shr edx, 1
	and edx, 2147483647d
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
			mov eax, [Left]
			ZFShr eax, 24
			and eax, 255d
		 	call AddAxHexChar
		
			mov eax, [Left]
			ZFShr eax, 16
			and eax, 255d
		 	call AddAxHexChar
		
			
			mov eax, [Left]
			ZFShr eax, 8
			and eax, 255d
		 	call AddAxHexChar
			
			mov eax, [Left]
			and eax, 255d
		 	call AddAxHexChar
		
			mov eax, [Right]
			ZFShr eax, 24
			call AddAxHexChar
			
			mov eax, [Right]
			ZFShr eax, 16
			and eax, 255d
		 	call AddAxHexChar
			
			mov eax, [Right]
			ZFShr eax, 8
			and eax, 255d
		 	call AddAxHexChar
		
			mov eax, [Right]
			and eax, 255d
			call AddAxHexChar
		ELSE
			mov eax, [Left]
			shr eax, 24d
			and eax, 255d
			call AddChar
		
			mov eax, [Left]
			shr eax, 16d
			and eax, 65535d
			and eax, 255d
			call AddChar
			
			mov eax, [Left]
			shr eax, 8d
			and eax, 16777215d
			and eax, 255d
			call AddChar
			
			mov eax, [Left]
			and eax, 255d
			call AddChar
			
			mov eax, [Right]
			shr eax, 24d
			and eax, 255d
			call AddChar
			
			mov eax, [Right]
			shr eax, 16d
			and eax, 65535d
			and eax, 255d
			call AddChar
			
			mov eax, [Right]
			shr eax, 8d
			and eax, 16777215d
			and eax, 255d
			call AddChar
		
			mov eax, [Right]
			and eax, 255d
			call AddChar
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

		mov al, ah
		call isHexCharacter
		cmp si, 0
		JE @@ERROR_NOT_HEX
		
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
		
		call isHexCharacter
		cmp si, 0
		JE @@ERROR_NOT_HEX

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

	ret



	@@ERROR_NOT_HEX:
		Console_Exit ' Sorry, the string must contain only hex characters!'
	ret
endp

;  0 = FALSE, 1 = TRUE
proc isAlDigit
	cmp al, '0'
	JB @@RETURN_NO

	cmp al, '9'
	JG @@RETURN_NO

	mov si, 1
	ret

	@@RETURN_NO:
	mov si, 0
	@@EXIT:
	ret 
endp

proc isALaTOf
	cmp al, 'a'
	JB @@RETURN_NO

	cmp al, 'f'
	JG @@RETURN_NO

	mov si, 1
	ret 

	@@RETURN_NO:
	mov si, 0
	@@EXIT:
	ret 
endp

proc isCaptialATOF
	cmp al, 'A'
	JB @@RETURN_ZERO

	cmp al, 'F'
	JG @@RETURN_ZERO

	mov si, 1
	ret 

	@@RETURN_ZERO:
	mov si, 0
	@@EXIT:
	ret 
endp

proc isHexCharacter
	
	mov si, 0

	call isAlDigit
	cmp si, 1
	JE @@RETURN_TRUE

	call isCaptialATOF
	cmp si, 1
	JE @@RETURN_TRUE

	call isALaTOf
	cmp si, 1
	JE @@RETURN_TRUE
	
	; Return false
	mov si, 0
	ret

	@@RETURN_TRUE:
	mov si, 1
	ret
endp