; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Tue, 17 Mar 2015 13:05:24
; 	Author   : Eyal Godovich 
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Perform
;	Usage    : Base_PushRegisters <ax, bx, cx, dx>
;	Desc     : Pushes the registers to the stack 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Perm_Perform One, Two, By, AndWith
	local @@tmp, @@start
	
	push edx
    push ds 
	  
	jmp @@start
	@@tmp dd 0
	
	@@start:
		mov edx, [One]
		shr edx, By
		
		; Create the mask (2 ^ (intSize - x) - 1)
		mov [@@tmp], 2
		shl [@@tmp], 32-By
		dec [@@tmp]
		
		
		and edx, [@@tmp]	
		xor edx, [Two]
		mov [@@tmp], AndWith
		and edx, [@@tmp]
		xor [Two], edx
		shl edx, By
		xor [One], edx
			
	pop ds
    pop edx 
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : IP
;	Usage    : IP Left, Right
;	Desc     : Initial permutation
;   Extra    : http://en.wikipedia.org/wiki/Data_Encryption_Standard
; 	Original : 
; 		#define IP(l,r,t)					\
;			PERM_OP(r,l,t, 4,0x0f0f0f0f);	\
;			PERM_OP(l,r,t,16,0x0000ffff);	\
;			PERM_OP(r,l,t, 2,0x33333333);	\
;			PERM_OP(l,r,t, 8,0x00ff00ff);	\
;			PERM_OP(r,l,t, 1,0x55555555);	\
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
macro IP l, r 
	Perm_Perform l, r, 4 , 0f0f0f0fh
	Perm_Perform l, r, 16, 0000ffffh
	Perm_Perform r, l, 2 , 33333333h
	Perm_Perform r, l, 8 , 00ff00ffh
	Perm_Perform l, r, 1 , 55555555h
endm

;----------------------------------------------------------
; FP - Final Permutation
;----------------------------------------------------------
; #define FP(l,r,t) \
;	PERM_OP(l,r,t, 1,0x55555555); \
;	PERM_OP(r,l,t, 8,0x00ff00ff); \
;	PERM_OP(l,r,t, 2,0x33333333); \
;	PERM_OP(r,l,t,16,0x0000ffff); \
;	PERM_OP(l,r,t, 4,0x0f0f0f0f);

; Swap XOR Algorithm
macro Swap src, dst
	push edx
	mov edx, [dst]
	xor [src], edx
	xor edx, [src]
	xor [src], edx
	mov [dst], edx
	pop edx
endm

; Zero filled shift right
; >>> Operator in js
macro ZFShr dst, by

	push esi
  
	; Create the mask (2 ^ (intSize - x) - 1)
	mov esi, 2
	shl esi, 32-By
	dec esi
	
	shr dst, By
	and dst, esi
	
    pop esi

endm

macro Create_Long_Or from, by, array, dst, cmd
	Base_PushRegisters <ebx, eax, edx>

	mov ebx, [from]
	ZFShr ebx, by
	and ebx, 0Fh
	mov ax, 4d
	mul bx
	mov bx, ax
	mov edx, [dword ptr array + bx]
	cmd dst, edx

	Base_PopRegisters <edx, eax, ebx>
endm

; Credit: http://www.geeksforgeeks.org/rotate-bits-of-an-integer/
macro Rotate_Left src, by, t
	Base_PushRegisters <edx>

	mov edx, [src]
	shl edx, by
	mov [TempDW], edx
	mov edx, [src]
	ZFShr edx, t
	or [TempDW], edx
	mov edx, [TempDW]
	mov [src], edx

	Base_PopRegisters <edx>
endm
