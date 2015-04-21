; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Fri, 13 Mar 2015 14:01:19
; 	Author   : Unknown (Gvahim.mac)
; 	File     : Base.asm
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PushRegisters
;	Usage    : Base_PushRegisters <ax, bx, cx, dx>
;	Desc     : Pushes the registers to the stack 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Base_PushRegisters registers
	; Loop through each one of the registers in the list.
	irp reg, <registers>
		; Push the register
		push reg
	endm  
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PopRegisters
;	Usage    : Base_PopRegisters <ax, bx, cx, dx>
;	Desc     : Pops the registers to the stack  
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Base_PopRegisters registers
	; Loop through each one of the registers in the list.
	irp reg, <registers>
		; Pop the register
		pop reg
	endm 
endm