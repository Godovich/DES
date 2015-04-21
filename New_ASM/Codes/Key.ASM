; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Tue, 17 Mar 2015 13:05:24
; 	Author   : Eyal Godovich 
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

macro Key_Expand

	lea si, [key]	

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
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Permuting
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	Perm_Perform Left, Right, 4 , 0F0F0F0Fh
	Perm_Perform Right, Left, 16, 0000FFFFh
	Perm_Perform Left, Right, 2 , 33333333h
	Perm_Perform Right, Left, 16, 0000FFFFh
	Perm_Perform Left, Right, 1 , 55555555h
	Perm_Perform Right, Left, 8 , 00FF00FFh
	Perm_Perform Left, Right, 1 , 55555555h
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	 Right side needs to be shifted and to get the last four bits of the left side!
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	mov edx, [Left]
	mov [TempDW], edx
	shl [TempDW], 8d
	mov edx, [Right]
	shr edx, 20d
	and edx, 0FFFh
	and edx, 00F0h
	or [TempDW], edx
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	 Left needs to be put upside down
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	mov edx, [Right]
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
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	 Now go through and perform these shifts on the left and right keys
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	xor bx, bx
	
	REPT 16
		local @@DONE_SHIFTING, @@SHIFT_BY_ONE
		
		; Save BX
		push bx
		
		; Shift by 1 or 2?
		mov al, [ShiftsArray + bx] 
		
		cmp al, 0
		je @@SHIFT_BY_ONE
		
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
		
		jmp @@DONE_SHIFTING
		
		@@SHIFT_BY_ONE:
		
			xor edx, edx
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
			or [TempDW], edx
			mov edx, [TempDW]
			mov [Right], edx
			
			jmp @@DONE_SHIFTING
			
			
		@@DONE_SHIFTING:
			and [Left], -0Fh
			and [Right], -0Fh
			
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			;	 Create left-temp
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			
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
			
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			;	 Create right-temp
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			
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

			; temp = ((righttemp >>> 16) ^ lefttemp) & 0x0000ffff; 
			shr [TempDW], 16d
			and [TempDW], 0FFFFh
			mov edx, [LeftTemp]
			xor [TempDW], edx
			and [TempDW], 0FFFFh
			
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			;	 Create keys!
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			
			; First key
			mov edx, [LeftTemp]
			xor edx, [TempDW]
			mov bx, 4d
			imul bx, [KeyNum] ; I swear to god, when I found out about imul, i smiled.
			mov [dword ptr Keys + bx], edx
			inc [KeyNum]
			
			; Second key
			mov edx, [TempDW]
			shl [TempDW], 10h
			mov edx, [TempDW]
			xor edx, [RightTemp]
			mov bx, 4d
			imul bx, [KeyNum] ; I swear to god, when I found out about imul, i smiled.
			mov [dword ptr Keys + bx], edx
			inc [KeyNum]
			
		; Restore BX
		pop bx
		
		; Add 1 to bx
		inc bx
	endm
	
		
	
endm
