proc RunEncryption

	cmp [encrypt], '1'
	JE whileLoop
	
	sub [EncDecLength], 8d
	
	; while(m < EncDecLen)
	
	lea si, [EncDecString]
	whileLoop:
		
		;------------------------------------------------------------
		; Create left
		;------------------------------------------------------------
		
		;lodsd   
		;xchg  ah, al
		;ror   eax, 16
		;xchg  ah, al
		;mov [Left], eax
		;add [m], 4
		
		xor edx, edx ; Reset edx
		mov bx , [m]
		mov dl, [byte ptr EncDecString + bx]
		shl edx, 24d
		mov [Left], edx
		inc [m]
		
		xor edx, edx ; Reset edx
		mov bx , [m]
		mov dl, [byte ptr EncDecString + bx]
		shl edx, 16d
		or [Left], edx
		inc [m]
		
		xor edx, edx ; Reset edx
		mov bx ,[m]
		mov dl, [byte ptr EncDecString + bx]
		shl edx, 8d
		or [Left], edx
		inc [m]
		
		xor edx, edx ; Reset edx
		mov bx ,[m]
		mov dl, [byte ptr EncDecString + bx]
		or [Left], edx
		inc [m]
		
		
		;------------------------------------------------------------
		; Create right
		;------------------------------------------------------------
		;lodsd 
		;xchg  ah, al
		;ror   eax, 16
		;xchg  ah, al
		;mov [Right], eax
		;add [m], 4
		
		xor edx, edx ; Reset edx
		mov bx, [m]
		mov dl, [byte ptr EncDecString + bx]
		shl edx, 24d
		mov [Right], edx
		inc [m]
		
		xor edx, edx ; Reset edx
		mov bx, [m]
		mov dl, [byte ptr EncDecString + bx]
		shl edx, 16d
		or [Right], edx
		inc [m]
		
		xor edx, edx ; Reset edx
		mov bx, [m]
		mov dl, [byte ptr EncDecString + bx]
		shl edx, 8d
		or [Right], edx
		inc [m]
		
		xor edx, edx ; Reset edx
		mov bx, [m]
		mov dl, [byte ptr EncDecString + bx]
		or [Right], edx
		inc [m]
		
		;------------------------------------------------------------
		; Debugging: Print Right
		;------------------------------------------------------------
		;call NEW_LINE
		;print 'Right: '
		;mov edx, [Right]
		;DEBUG_REG_32 edx
		
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
		forLoop:
		
			cmp [encrypt], '1'
			JE Reg
			
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
			
			jmp Next
			
			Reg:
			mov bx, [i]
			imul bx, 4d
			mov edx, [dword ptr Keys + bx]
			mov [Key1], edx
			
			mov bx, [i]
			inc bx
			imul bx, 4d
			mov edx, [dword ptr Keys + bx]
			mov [Key2], edx
			
			Next:
			
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
		JNE forLoop
		
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
		PERM_OP Left, Right, 1 , 55555555h
		PERM_OP Right, Left, 8 , 00ff00ffh
		PERM_OP Right, Left, 2 , 33333333h
		PERM_OP Left, Right, 16, 0000ffffh
		PERM_OP Left, Right, 4 , 0f0f0f0fh
		
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
		cmp [encrypt], '0'
		JE DecryptionOutput
		
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
		
		jmp AfterPrint
	
		DecryptionOutput:
		
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
		
	AfterPrint:	
	mov ax, [m]
	cmp ax, [EncDecLength]
	JLE whileLoop
	
	call OpenOutputFile
	call WriteOutput
	call CloseFile
	
	mov bx, [outputc]
	
	cmp bx, 100d
	JGE Continue
	
	mov [output + bx], 0h
	lea si, [output]
	call PRINT_STR
	
	jmp Finish

	Continue:
	print ' Sorry, your string is too big to display here!'
	call NEW_LINE
	print '  You can find the output in Output.txt!'
	
	Finish:
	
	ret
endp