; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Tue, 17 Mar 2015 13:05:24
; 	Author   : Eyal Godovich 
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Perform
;	Usage    : Perm_Perform Left, Right, 4 , 0f0f0f0fh
;	Desc     : Rotate's blocks of bits 
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
;	Name     : Swap
;	Usage    : Swap Left, Right
;	Desc     : Swap's two values
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Swap src, dst
	push edx
	mov edx, [dst]
	xor [src], edx
	xor edx, [src]
	xor [src], edx
	mov [dst], edx
	pop edx
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : ZFShr
;	Usage    : ZFShr [Left], 14
;	Desc     : Zero-filled shift right
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Rotate_Left
;	Usage    : Rotate_Left Left, 2, 27
;	Desc     : Rotates a sequence of bits x times to the left
; 	Credit   : http://www.geeksforgeeks.org/rotate-bits-of-an-integer/
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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