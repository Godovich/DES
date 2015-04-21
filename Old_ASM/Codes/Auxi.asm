;--------------------------------------------------------------------------------------
; PRINT_NUM_HEX_WITHOUT_H
;    Prints a 16 bit register to the screen in base 16
;    IN:  ax
;    OUT: None
;--------------------------------------------------------------------------------------
proc PRINT_NUM_HEX_WITHOUT_H
   push bx
   cmp ax, 0Fh
   JG DontPrintZero
   
   putc '0'
   DontPrintZero:
   mov  bx, 16
   call PRINT_NUM_BY_BASE
   pop  bx
   ret
endp


; Takes hex string from DecString and puts in EncDecString
proc hexToString
	
	; cx, 1 ; foreach two characters
	; CX - Length
	mov bx, 0d
	mov dx, 0
	ForeachChar:
		mov ax, 0d
	
		mov ah, [DecString + bx] ; Contains current char	
		
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
		mov al, [DecString + bx] ; Contains current char	
		
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
		mov [EncDecString + bx], ah
		inc dx
		pop bx
		
	inc bx
	cmp bx, cx
	JNE ForeachChar
	
	mov [EncDecString + bx], 0
	mov [EncDecLength], cx
	shr [EncDecLength], 1
endp



proc OpenInputFile
	; Open file
	mov ah, 3Dh
	xor al, al
	lea dx, [InputFile]
	int 21h
	jc openerror
	
	mov [filehandle], ax
	ret
	
	openerror:
		print ' - Error! Open input file'
		DEBUG_REG ax
		ret
		
endp

proc OpenOutputFile
	; Open file
	mov ah, 3Dh
	mov al, 2h
	lea dx, [OutputFile]
	int 21h
	jc openerrorOutput
	mov [filehandle], ax
	
	ret
	
	openerrorOutput:
		print ' - Error! (OpenOutputFile) '
		ret
		
endp

proc ReadFile
	; Read file
	;call ReadSize
	mov cx, 4096
	
	mov ah,3Fh
	mov bx, [filehandle]
	mov dx,offset EncDecString
	int 21h
	ret
endp

proc ReadFileToDec
	; Read file
	; call ReadSize
	mov cx, 4096
	
	mov ah,3Fh
	mov bx, [filehandle]
	mov dx,offset DecString
	int 21h
	ret
endp

proc WriteOutput
	
	call ReplaceNullBytes

	mov ah,40h
	mov bx, [filehandle]

	mov cx, [outputc]
	
	
	mov dx,offset output
	int 21h
	ret
endp

proc ReplaceNullBytes

	mov cx, [outputc]
	
	CharLoop:
	mov bx, cx
	cmp [output + bx], 0
	JNE _End
	
	mov [output + bx], 20h
	
	
	_End:
		dec cl
		cmp cl, 0
		JNE CharLoop
		
	ret

endp

proc DeleteOutput
	
	mov ah, 41h
	mov dx, offset OutputFile
	int 21h

endp

proc CreateOutput

	mov cx, 0
	mov ah, 3Ch
	mov dx, offset OutputFile
	int 21h
endp

proc ReplaceNullBytesInEnc

	mov cx, [EncDecLength]
	
	CharLoop1:
	mov bx, cx
	cmp [EncDecString + bx], 0
	JNE _End2
	
	mov [EncDecString + bx], 20h
	
	
	_End2:
		dec cl
		cmp cl, 0
		JNE CharLoop1
		
	ret

endp

proc CloseFile
	mov ah,3Eh
	mov bx, [filehandle]
	int 21h
	ret
endp

proc AddChar

	mov bx, [outputc]
	
	mov [byte ptr output + bx], al
	inc [outputc]
	
	ret
endp

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