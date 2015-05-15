; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Thu, 19 Mar 2015 16:58:22
; 	Author   : Eyal Godovich 
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

macro Encrypt_Run MODE
	local @@ForLoop, @@whileLoop, @@Reg, @@Next

	; If the mode is encryption
	IF Mode eq 1
		lea si, [inputFileContent]
	ELSE 
		lea si, [inputFileContentDec]
	ENDIF

	mov [outputc], 0

	@@whileLoop:
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Create Left
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	; Load double-word from the string in SI into eax
	lodsd		
	
	; Reverse bit order
	; I have no clue why i'm getting the bits in reverse order
	xchg  ah, al
	ror   eax, 16
	xchg  ah, al
	
	; Set as left
	mov [Left], eax
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Create right
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	; Load double-word from the string in SI into eax
	lodsd		
	
	; Reverse bit order
	; I have no clue why i'm getting the bits in reverse order
	xchg  ah, al
	ror   eax, 16
	xchg  ah, al
	
	; Set as right
	mov [Right], eax

	;------------------------------------------------------------
	; Permute each 64 byte chunk by IP
	;------------------------------------------------------------
	; This code has been written by Eric Young, the creator of SSLeay ( Today called OpenSSL ).
	; The Original Code:
	; 	
	;	#define IP(l,r)
    ;   { 
    ;   	register DES_LONG tt; 
    ;   	PERM_OP(r,l,tt, 4,0x0f0f0f0fL); 
    ;   	PERM_OP(l,r,tt,16,0x0000ffffL); 
    ;   	PERM_OP(r,l,tt, 2,0x33333333L); 
    ;   	PERM_OP(l,r,tt, 8,0x00ff00ffL); 
    ;   	PERM_OP(r,l,tt, 1,0x55555555L); 
    ;   }
    ;
    ; Source URL: https://github.com/openssl/openssl/blob/master/crypto/des/des_locl.h#L415

	Perm_Perform Left, Right, 4 , 0f0f0f0fh
	Perm_Perform Left, Right, 16, 0000ffffh
	Perm_Perform Right, Left, 2 , 33333333h
	Perm_Perform Right, Left, 8 , 00ff00ffh
	Perm_Perform Left, Right, 1 , 55555555h

	;------------------------------------------------------------
	; Rotate left & right 1 bit to the left
	;------------------------------------------------------------
	rol [Right], 1
	rol [Left] , 1

	;------------------------------------------------------------
	; Now go through and perform the encryption or decryption  
	;------------------------------------------------------------

	Index = 0
	REPT 16

		iteration = 0
		REPT 2

			; In decryption, we want the keys in reverse order
			; So let's subtract the key index from 30.
			IF Mode eq 0
				mov bx, 30 - Index
			ELSE
				mov bx, Index
			ENDIF

			; If it's the second iteration, add 1 to bx.
			IF iteration eq 1
				inc bx
			ENDIF

			; Multiply the index by 4 ( Each element in the array is dword ( 4 Bytes ) )
			imul bx, 4d

			; Get the element
			mov edx, [dword ptr Keys + bx]
			
			; If it's the first iteration, it's the first key.
			; If it's the second iteration, it's the second key.
			IF iteration eq 0
				mov [Key1], edx
			ELSE
				mov [Key2], edx
			ENDIF

			; Add 1 to the iteration count.
			; Technically, we can change this to "iteration = 1", because the loop will only run twice. 
			iteration = iteration + 1
		endm

		;------------------------------------------------------------
		; Now apply the feistel function 
		;------------------------------------------------------------
		; right1 = right ^ keys[0]; 
		mov edx, [Right]
		mov eax, [Key1]
		xor edx, eax
		mov [Right1], edx
		
		; right2 = ((right >>> 4) | (right << 28)) ^ keys[1];
		mov edx, [Right]
		ZFShr edx, 4
		mov eax, [Right]
		shl eax, 28d
		and eax, 0ffffffffh
		or edx, eax
		xor edx, [Key2]
		mov [Right2], edx
		Swap Left, Right
		
		; Clear the edx register
		xor edx, edx

		; The result is attained by passing these bytes through the S selection functions.
		; The next part is a self-generating code, that means that in the compilation proccess, it will change to the actual code.
		; It will create 8 blocks, that will look something like that:
		;	mov ebx, [Right2]
		;	shr ebx, 16d
		;	and ebx, 65535d
		;	and ebx, 3Fh
		;	imul bx, 4d
		;	mov eax, [dword ptr spfunction3 + bx]
		;	or edx, eax
		Count = 24
		Part = Right1
		IRP Array, <spfunction2, spfunction4, spfunction6, spfunction8, spfunction1, spfunction3, spfunction5, spfunction7>

			; The first half is right1, and the second half is right2
			mov ebx, [Part]

			; Shift by the current count
			shr ebx, count

			; There are only 64 options
			and ebx, 3Fh

			; Each element in the array is a double-word ( 4 Bytes )
			imul bx, 4d

			; Or with the current value
			or edx, [dword ptr Array + bx]

			; Subtract 8 from the count
			Count = Count - 8

			; If we finished with Right1, move to Right2
			IF Count eq -8
				Part = Right2
				Count = 24
			ENDIF
		endm
		
		; Xor the right variable with the result of the S selection result.
		xor [Right], edx

		; Used two keys, move to the next ones.
		Index = Index + 2
	endm

	;------------------------------------------------------------
	; Perform IP-1 (Final Permutation / FP)
	;------------------------------------------------------------
	; This code has been written by Eric Young, the creator of SSLeay ( Today called OpenSSL ).
	; The Original Code:
	; 	
    ;	#define FP(l,r) 
    ;   { 
    ;   	register DES_LONG tt;
    ;   	PERM_OP(l,r,tt, 1,0x55555555L);
    ;   	PERM_OP(r,l,tt, 8,0x00ff00ffL);
    ;   	PERM_OP(l,r,tt, 2,0x33333333L);
    ;   	PERM_OP(r,l,tt,16,0x0000ffffL);
    ;   	PERM_OP(l,r,tt, 4,0x0f0f0f0fL);
    ;   }
    ;
    ;
    ; Github URL: https://github.com/openssl/openssl/blob/master/crypto/des/des_locl.h#L425

	; The encryption is complete.
    ; Now reverse-permute the ciphertext to produce the final result.
	Swap Left, Right
	ror [Left], 1
	ror [Right], 1
	Perm_Perform Left, Right, 1 , 55555555h
	Perm_Perform Right, Left, 8 , 00ff00ffh
	Perm_Perform Right, Left, 2 , 33333333h
	Perm_Perform Left, Right, 16, 0000ffffh
	Perm_Perform Left, Right, 4 , 0f0f0f0fh

	;------------------------------------------------------------
	; Print the final string!
	;------------------------------------------------------------

	; The next part is a self-generating code, that means that this code will compile once and will change itself to the actual code.
	; The original code was about 500 lines of code and I managed to replace it with 39 lines of self-generating code.

	; After compilation, each block looks something like that:
	; For encryption:
	; 	mov eax, [Left]
	;	mov eax, [Left]
	;	ZFShr eax, 8
	;	and eax, 255d
	;	call AddAxHexChar
	;
	; For decryption:
	;	mov eax, [Left]
	;	shr eax, 16d
	;	and eax, 65535d
	;	and eax, 255d
	;	call AddChar

	CURRENT_HALF = Left
	CURRENT_BY   = 24

	REPT 8
		mov eax, [CURRENT_HALF]

		; If the current shift value is diffrent than zero, then shift.
		IFE CURRENT_BY EQ 0 
			ZFShr eax, CURRENT_BY
			and eax, 255
		ENDIF

		; For encryption we want to print the result in hex, and for decryption in plain text
		IF Mode eq 1

			; First char
			mov ah, al
			shr ah, 4
			String_AddHexToResult ah
		
			; Second char
			mov ah, al
			and ah, 0Fh
			String_AddHexToResult ah

		ELSE

			; Add the character
			mov bx, [outputc]
			mov [output + bx], al
			inc [outputc]

		ENDIF

		CURRENT_BY = CURRENT_BY - 8

		; If the left part is done, move to the right part
		IF CURRENT_BY EQ -8
			CURRENT_BY    = 24
			CURRENT_HALF  = Right
		ENDIF
	endm

	; Check if the loop is over, if not, loop again.
	add [m], 8d
	mov ax, [m]
	cmp ax, [inputFileSize]
	JLE @@whileLoop

	; Create the output.txt file if necessary
	File_Create '..\Output.txt', inputFileHandle
	File_Close inputFileHandle
	
	; Open the file and save the handle 
	File_Open '..\Output.txt', 2, inputFileHandle

	; End the string with ascii zero
	mov bx, [outputc]
	mov [output + bx], 0

	; Print up to 62 characters from the string
	lea si, [output]
	String_PrintUpTo 62

	; Get the real string length
	String_TrimNonsense output	
	mov cx, bx

	; Write the output to Output.txt
	mov ah, 40h
	mov bx, [inputFileHandle]
	lea dx, [output]
	int 21h

endm