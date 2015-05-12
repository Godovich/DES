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