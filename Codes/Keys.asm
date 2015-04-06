	; Some extra data:
	;	In this code i used something called arithmetic shift, SAR (Right) & SAL (Left).
	;	You may know it as "Zero-filled right-shift" or "sticky right-shift"
	;	
	;	More info: http://en.wikipedia.org/wiki/Arithmetic_shift

	proc ExpandKeys
	
		;------------------------------------------------------------
		; Create left
		; left = (key.charCodeAt(m++) << 24) | (key.charCodeAt(m++) << 16) | (key.charCodeAt(m++) << 8) | key.charCodeAt(m++);
		;------------------------------------------------------------
		xor edx, edx
		mov dl, [byte ptr key]
		shl edx, 24d
		mov [Left], edx
		
		mov bx, 1	; Will be our char index
		mov cl, 16d ; We want to add them by order to the left variable
		
		REPT 3d
			xor edx, edx
			mov dl, [byte ptr key + bx]
			shl edx, cl
			or [Left], edx
		
			sub cx, 8d
			inc bx
		ENDM
		
		;------------------------------------------------------------
		; Debugging: Print left using EDX
		;------------------------------------------------------------
		; mov edx, [Left]
		; CALL NEW_LINE
		; DEBUG_REG_32 edx
		
		
		;------------------------------------------------------------
		; Create right
		;   right = (key.charCodeAt(m++) << 24) | (key.charCodeAt(m++) << 16) | (key.charCodeAt(m++) << 8) | key.charCodeAt(m++);
		;------------------------------------------------------------
		xor edx, edx
		mov dl, [byte ptr key + 4]
		shl edx, 24d
		mov [Right], edx
		
		mov bx, 1	; Will be our char index
		mov cl, 16d ; We want to add them by order to the left variable
		
		REPT 3d
			xor edx, edx
			mov dl, [byte ptr key + bx + 4]
			shl edx, cl
			or [Right], edx
		
			sub cx, 8d
			inc bx
		ENDM
		
		;------------------------------------------------------------
		; Debugging: Print right using EDX
		;------------------------------------------------------------
		;mov edx, [Right]
		;CALL NEW_LINE
		;DEBUG_REG_32 edx
		
		
		;------------------------------------------------------------
		; Permuting
		;------------------------------------------------------------
		mov edx, [Left]
		mov [TempDW], edx
		shr [TempDW], 4d
		and [TempDW], 0FFFFFFFh
		mov edx, [Right]
		xor [TempDW], edx
		and [TempDW], 0F0F0F0Fh
		mov edx, [TempDW]
		xor [Right], edx
		shl edx, 4
		xor [Left], edx
		
		mov edx, [Right]
		mov [TempDW], edx
		shr [TempDW], 16d
		and [TempDW], 0FFFFh
		mov edx, [Left]
		xor [TempDW], edx
		and [TempDW], 0FFFFh
		mov edx, [TempDW]
		xor [Left], edx
		shl edx, 16
		xor [Right], edx
		
		mov edx, [Left]
		mov [TempDW], edx
		shr [TempDW], 2d
		and [TempDW], 3FFFFFFFh
		mov edx, [Right]
		xor [TempDW], edx
		and [TempDW], 33333333h
		mov edx, [TempDW]
		xor [Right], edx
		shl edx, 2d
		xor [Left], edx
		
		mov edx, [Right]
		mov [TempDW], edx
		shr [TempDW], 16d
		and [TempDW], 0FFFFh
		mov edx, [Left]
		xor [TempDW], edx
		and [TempDW], 0FFFFh
		mov edx, [TempDW]
		xor [Left], edx
		shl edx, 16d
		xor [Right], edx
		
		mov edx, [Left]
		mov [TempDW], edx
		shr [TempDW], 1d
		and [TempDW], 7FFFFFFFh
		mov edx, [Right]
		xor [TempDW], edx
		and [TempDW], 55555555h
		mov edx, [TempDW]
		xor [Right], edx
		shl edx, 1d
		xor [Left], edx
		
		mov edx, [Right]
		mov [TempDW], edx
		shr [TempDW], 8d
		and [TempDW], 0FFFFFFh
		mov edx, [Left]
		xor [TempDW], edx
		and [TempDW], 00FF00FFh
		mov edx, [TempDW]
		xor [Left], edx
		shl edx, 8d
		xor [Right], edx
		
		mov edx, [Left]
		mov [TempDW], edx
		shr [TempDW], 1d
		and [TempDW], 7FFFFFFFh
		mov edx, [Right]
		xor [TempDW], edx
		and [TempDW], 55555555h
		mov edx, [TempDW]
		xor [Right], edx
		shl edx, 1d
		xor [Left], edx
		
		;------------------------------------------------------------
		; Debugging: Print right and left using EDX
		;------------------------------------------------------------
		;mov edx, [Right]
		;CALL NEW_LINE
		;print 'Right: '
		;DEBUG_REG_32 edx
		;mov edx, [Left]
		;CALL NEW_LINE
		;print 'Left: '
		;DEBUG_REG_32 edx

		
		;------------------------------------------------------------
		; Right side needs to be shifted and to get the last four bits of the left side!
		;------------------------------------------------------------
		
		mov edx, [Left]
		mov [TempDW], edx
		shl [TempDW], 8d
		mov edx, [Right]
		shr edx, 20d
		and edx, 0FFFh
		and edx, 00F0h
		or [TempDW], edx
		
		;------------------------------------------------------------
		; Debugging: Print TempDW using EDX
		;------------------------------------------------------------
		; mov edx, [TempDW]
		; CALL NEW_LINE
		; print 'TempDW: '
		; DEBUG_REG_32 edx
		
		
		;------------------------------------------------------------
		; Left needs to be put upside down
		;------------------------------------------------------------
		mov edx, [Right]
		shl edx, 24d
		mov [Left], edx
		mov edx, [Right]
		shl edx, 8d
		and edx, 0FF0000h
		or [Left], edx
		mov edx, [Right]
		shr edx, 8d
		and edx, 0FFFFFFh
		and edx, 0FF00h
		or [Left], edx
		mov edx, [Right]
		shr edx, 24d
		and edx, 0FFh
		and edx, 0F0h
		or [Left], edx
		
		mov edx, [TempDW]
		mov [Right], edx
		
		;------------------------------------------------------------
		; Debugging: Print left using EDX
		;------------------------------------------------------------
		; mov edx, [Left]
		; CALL NEW_LINE
		; DEBUG_REG_32 edx
		
		;------------------------------------------------------------
		; Now go through and perform these shifts on the left and right keys
		;------------------------------------------------------------
		
		mov bx, 0 ; Our index
		mov cx, 16d
		
		REPT_16_TIMES:
			push ecx
			push ebx
			
			mov al, [ShiftsArray + bx] ; 1 / 0 - by two or by one
			
			cmp al, 0d
			JE SHIFT_BY_ONE
			
			;------------------------------------------------------------
			; Shift by two!
			;------------------------------------------------------------
			mov edx, [Left]
			shl edx, 2d
			mov [TempDW], edx
			mov edx, [Left]
			shr edx, 26d
			and edx, 3Fh
			or [TempDW], edx
			mov edx, [TempDW]
			mov [Left], edx
			
			mov edx, [Right]
			shl edx, 2d
			mov [TempDW], edx
			mov edx, [Right]
			shr edx, 26d
			and edx, 3Fh
			or [TempDW], edx	
			mov edx, [TempDW]
			mov [Right], edx
			
			jmp DONE_SHIFTING
			
			;------------------------------------------------------------
			; Shift by one!
			;------------------------------------------------------------
			SHIFT_BY_ONE:
			mov edx, [Left]
			shl edx, 1d
			mov [TempDW], edx
			mov edx, [Left]
			shr edx, 27d
			and edx, 1Fh
			or [TempDW], edx
			mov edx, [TempDW]
			mov [Left], edx
			
			mov edx, [Right]
			shl edx, 1d
			mov [TempDW], edx
			mov edx, [Right]
			shr edx, 27d
			and edx, 1Fh
			or [TempDW], edx
			mov edx, [TempDW]
			mov [Right], edx
			
			DONE_SHIFTING: 
			
			;------------------------------------------------------------
			; Debugging: Print Left using EDX 
			;------------------------------------------------------------
			; mov EDX, [Right]
			; DEBUG_REG_32 edx
			; call NEW_LINE
			
			and [Left], -0Fh
			and [Right], -0Fh
			
			;------------------------------------------------------------
			; Now apply Permuted Choice 2 (PC-2)
			;------------------------------------------------------------
						
			;---------------------------------------
			; Create LeftTemp
			;---------------------------------------
			mov ebx, [Left]
			shr ebx, 28d
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes0 + bx]
			mov [TempDW], edx
			
			mov ebx, [Left]
			shr ebx, 24d
			and ebx, 0FFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes1 + bx]
			or [TempDW], edx
			
			mov ebx, [Left]
			shr ebx, 20d
			and ebx, 0FFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes2 + bx]
			or [TempDW], edx
			
			mov ebx, [Left]
			shr ebx, 16d
			and ebx, 0FFFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes3 + bx]
			or [TempDW], edx
			
			mov ebx, [Left]
			shr ebx, 12d
			and ebx, 0FFFFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes4 + bx]
			or [TempDW], edx
			
			mov ebx, [Left]
			shr ebx, 8d
			and ebx, 0FFFFFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes5 + bx]
			or [TempDW], edx
			
			mov ebx, [Left]
			shr ebx, 4d
			and ebx, 0FFFFFFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes6 + bx]
			or [TempDW], edx
			
			mov edx, [TempDW]
			mov [LeftTemp], edx
			
			;---------------------------------------
			; Create RightTemp
			;---------------------------------------
			mov ebx, [Right]
			shr ebx, 28d
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes7 + bx]
			mov [TempDW], edx
			
			mov ebx, [Right]
			shr ebx, 24d
			and ebx, 0FFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes8 + bx]
			or [TempDW], edx
			
			mov ebx, [Right]
			shr ebx, 20d
			and ebx, 0FFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes9 + bx]
			or [TempDW], edx
			
			mov ebx, [Right]
			shr ebx, 16d
			and ebx, 0FFFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes10 + bx]
			or [TempDW], edx
			
			mov ebx, [Right]
			shr ebx, 12d
			and ebx, 0FFFFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes11 + bx]
			or [TempDW], edx
			
			mov ebx, [Right]
			shr ebx, 8d
			and ebx, 0FFFFFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes12 + bx]
			or [TempDW], edx
			
			mov ebx, [Right]
			shr ebx, 4d
			and ebx, 0FFFFFFFh
			and ebx, 0Fh
			mov ax, 4d
			mul bx
			mov bx, ax
			mov edx, [dword ptr PC2Bytes13 + bx]
			or [TempDW], edx
			
			mov edx, [TempDW]
			mov [RightTemp], edx
			
			
			; mov [TempDW], edx -> Useless, TempDW is RightTemp anyway, LOL
			shr [TempDW], 16d
			and [TempDW], 0FFFFh
			mov edx, [LeftTemp]
			xor [TempDW], edx
			and [TempDW], 0FFFFh
			
			;------------------------------------------------------------
			; Creating Keys! Wow!
			;------------------------------------------------------------
			
			;---------------------------------------
			; Create the first key
			;---------------------------------------
			mov edx, [LeftTemp]
			xor edx, [TempDW]
						
			;---------------------------------------
			; Store the first key
			;---------------------------------------
			mov bx, 4d
			imul bx, [KeyNum] ; I swear to god, when I found out about imul, i smiled.
			mov [dword ptr Keys + bx], edx
			inc [KeyNum]
			
			;---------------------------------------
			; Create the second key
			;---------------------------------------
			mov edx, [TempDW]
			shl [TempDW], 10h
			mov edx, [TempDW]
			xor edx, [RightTemp]
			
			;---------------------------------------
			; Store the second key
			;---------------------------------------
			mov bx, 4d
			imul bx, [KeyNum] ; I swear to god, when I found out about imul, i smiled.
			mov [dword ptr Keys + bx], edx
			inc [KeyNum]
			
			pop ebx
			inc bx
		
		; loop REPT_16_TIMES -> Doesn't work for some reason
		pop ecx
		dec cx
		cmp cx, 0
		JNE REPT_16_TIMES
		
		;------------------------------------------------------------
		; Debugging: Print all keys!
		; WARNING: I don't know why, but it makes des slow.
		;------------------------------------------------------------
		; mov cx, 0d
		; REPT 32
		; 	mov bx, 4d
		;  	imul bx, cx
		;  	mov edx, [Keys + bx]
		;  	CALL NEW_LINE
		;  	print 'Key: '
		;  	DEBUG_REG_32 edx
		;  	inc cx
		;  ENDM
			
		ret
	endp