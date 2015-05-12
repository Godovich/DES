; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Tue, 17 Mar 2015 13:05:24
; 	Author   : Eyal Godovich 
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

macro Key_Expand

	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Create Left and right
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; In the current phase the key should be turned into two integers, left and right.

	; Load the key string to the memory
	lea si, [key]

	; ~ Create Left~
	lodsd
	xchg  ah, al		; Reverse the order of bits (Step 1)
	ror   eax, 16		; Reverse the order of bits (Step 2)
	xchg  ah, al		; Reverse the order of bits (Step 3)
	mov [Left], eax 	; Save the result to left
	
	; ~ Create Right ~
	lodsd				; Load double-word from the string in SI into eax
	xchg  ah, al		; Reverse the order of bits (Step 1)
	ror   eax, 16		; Reverse the order of bits (Step 2)
	xchg  ah, al		; Reverse the order of bits (Step 3)
	mov [Right], eax 	; Save the result to left
	
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Permuting
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; After the creation of left and right, the bits of these two integers are then organised according to permuted choice 1 (PC-1).
	; The bits will end up in the following places:
	;
	;		--------------------------
    ; 		57	49	41	33	25	17	9	 \
	;		1	58	50	42	34	26	18    \ Left 
	; 		10	2	59	51	43	35	27    /
	; 		19	11	3	60	52	44	36   /
	;		--------------------------
	;		63	55	47	39	31	23	15   \
	;		7	62	54	46	38	30	22	  \ Right
	;		14	6	61	53	45	37	29    / 
	;		21	13	5	28	20	12	4    / 
	;		--------------------------
	;
	; This permutation is done using a permutation sequence, a smart way of switching bits batween 2 integers. 
	; The function was originlly created by Eric Young in C.
	; The 8086 assembly implementation has been written by Eyal Godovich.
	; 
	; Example for rotating 4x4 blocks of bits,
	; The original block layout:
	;		------------------------------   
	;		1	2	3	4  | 5	6	7	8    \ 
	;		9	10	11	12 | 13	14	15	16    \ This is the 
	;		17	18	19	20 | 21	22	23	24    / Left variable
	;		25	26	27	28 | 29	30	31	32   /
	; 		------------------------------
	;		33	34	35	36 | 37	38	39	40	\
	;		41	42	43	44 | 45	46	47	48	 \ This is the
	;		49	50	51	52 | 53	54	55	56   / Right variable
	;		57	58	59	60 | 61	62	63	64  /
	;		------------------------------
	; The new layout after using Eric Young's method: (  temp = ((left >>> 4) ^ right) & 0x0f0f0f0f; right ^= temp; left ^= (temp << 4) )
	;		------------------------------
	;		33	34	35	36 | 1	2	3	4 	\
	;		41	42	43	44 | 9	10	11	12	 \ This is the
	;		49	50	51	52 | 17	18	19	20   / Left variable
	;		57	58	59	60 | 25	26	27	28  /
	;		------------------------------
	;		37	38	39	40 | 5	6	7	8   \
	;		45	46	47	48 | 13	14	15	16   \ This is the 
	;		53	54	55	56 | 21	22	23	24   / Right variable
	;		61	62	63	64 | 29	30	31	32  /
	;		------------------------------

	; Perform the permutation as described by Eric Young in order to achieve PC-1
	Perm_Perform Left, Right, 4 , 0F0F0F0Fh
	Perm_Perform Right, Left, 16, 0000FFFFh
	Perm_Perform Left, Right, 2 , 33333333h
	Perm_Perform Right, Left, 16, 0000FFFFh
	Perm_Perform Left, Right, 1 , 55555555h
	Perm_Perform Right, Left, 8 , 00FF00FFh
	Perm_Perform Left, Right, 1 , 55555555h
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	 Right side needs to be shifted and to get the last four bits of the left side
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; temp = (left << 8) | (right >>> 20)
	mov edx, [Left]
	mov [TempDW], edx
	shl [TempDW], 8d
	mov edx, [Right]
	ZFShr edx, 20
	and edx, 00F0h
	or [TempDW], edx
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	 Left needs to be put upside down
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; left = (right << 24) | (right << 8) | (right >>> 8) | (right >>> 24)
	mov edx, [Right]
	shl edx, 24d
	mov [Left], edx
	mov edx, [Right]
	shl edx, 8d
	and edx, 0FF0000h
	or [Left], edx
	mov edx, [Right]
	ZFShr edx, 8
	and edx, 0FF00h
	or [Left], edx
	mov edx, [Right]
	ZFShr edx, 24
	and edx, 0F0h
	or [Left], edx
	mov edx, [TempDW]
	mov [Right], edx
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	 Now go through and perform these shifts on the left and right keys
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	; Clear the bx register
	xor bx, bx
	
	KeyIndex = 0
	REPT 16
		local @@DONE_SHIFTING, @@SHIFT_BY_ONE
		
		; Save BX
		push bx
		
		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		; Rotate the keys either one or two bits to the left
		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		; For each of the 16 needed subkeys, perform a bit
        ; rotation on each 28-bit keystuff half, then join
        ; the halves together and permute to generate the

		mov al, [ShiftsArray + bx] 
		cmp al, 0
		je @@SHIFT_BY_ONE
		
		; Default: Rotate by two
		Rotate_Left Left, 2, 26
		Rotate_Left Right,2, 26
		
		; Ok, now go to the next step
		jmp @@DONE_SHIFTING
		
		; Shift by one
		@@SHIFT_BY_ONE:

		Rotate_Left Left, 1, 27
		Rotate_Left Right,1, 27
		
		@@DONE_SHIFTING:

			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			;	 Perform the PC2 Permutation
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			; lefttemp = pc2bytes0[(left >>> 28) & 0xf] | pc2bytes1[(left >>> 24) & 0xf]
            ;          | pc2bytes2[(left >>> 20) & 0xf] | pc2bytes3[(left >>> 16) & 0xf]
            ;          | pc2bytes4[(left >>> 12) & 0xf] | pc2bytes5[(left >>> 8) & 0xf]
            ;          | pc2bytes6[(left >>> 4) & 0xf];
			
			CURRENT_BY = 28
			IRP CURRENT_ARRAY, <PC2Bytes0, PC2Bytes1, PC2Bytes2, PC2Bytes3, PC2Bytes4, PC2Bytes5, PC2Bytes6>

				mov ebx, [Left]
				
				IFE CURRENT_BY EQ 0
					ZFShr ebx, CURRENT_BY
				ENDIF

				and ebx, 0Fh
				mov ax, 4d
				mul bx
				mov bx, ax
				mov edx, [dword ptr CURRENT_ARRAY + bx]

				IF CURRENT_BY EQ 28
					mov ebp, edx
				ELSE
					or ebp, edx
				ENDIF

				CURRENT_BY = CURRENT_BY - 4
			endm

			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			;	 Perform the PC2 Permutation
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			; righttemp = pc2bytes7[(right >>> 28) & 0xf] | pc2bytes8[(right >>> 24) & 0xf]
            ;           | pc2bytes9[(right >>> 20) & 0xf] | pc2bytes10[(right >>> 16) & 0xf]
            ;           | pc2bytes11[(right >>> 12) & 0xf] | pc2bytes12[(right >>> 8) & 0xf]
            ;           | pc2bytes13[(right >>> 4) & 0xf];
			
			CURRENT_BY = 28
			IRP CURRENT_ARRAY, <PC2Bytes7, PC2Bytes8, PC2Bytes9, PC2Bytes10, PC2Bytes11, PC2Bytes12, PC2Bytes13>

				mov ebx, [Right]
				
				; Shift right if the shift value isn't zero
				IFE CURRENT_BY EQ 0
					ZFShr ebx, CURRENT_BY
				ENDIF

				; Each element in the array is equal to 4 bytes
				; So we need to multiply the index of our element by 4
				and ebx, 0Fh
				mov ax, 4d
				mul bx
				mov bx, ax
				mov edx, [dword ptr CURRENT_ARRAY + bx]

				IF CURRENT_BY EQ 28
					mov ecx, edx
				ELSE
					or ecx, edx
				ENDIF

				CURRENT_BY = CURRENT_BY - 4
			endm

			; temp = ((righttemp >>> 16) ^ lefttemp) & 0x0000ffff; 
			mov [TempDW], ecx
			ZFShr [TempDW], 16
			xor [TempDW], ebp
			and [TempDW], 0FFFFh
			
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			;	 Add the keys to the keys array!
			; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			
			; Add the first key to the subkeys array!
			xor ebp, [TempDW]
			mov bx, 4
			imul bx, KeyIndex
			mov [dword ptr Keys + bx],  ebp
			KeyIndex = KeyIndex + 1
			
			; Add the second key to the subkeys array!
			mov edx, [TempDW]
			shl [TempDW], 10h
			mov edx, [TempDW]
			xor edx, ecx
			mov bx, 4d
			imul bx, KeyIndex
			mov [dword ptr Keys + bx], edx
			KeyIndex = KeyIndex + 1
			
		; Restore and increase bx
		pop bx
		inc bx
	endm
endm
