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

MACRO Base_PushRegisters registers
	IRP reg, <registers>
		push reg
	ENDM  
ENDM

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PopRegisters
;	Usage    : Base_PopRegisters <ax, bx, cx, dx>
;	Desc     : Pops the registers to the stack  
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MACRO Base_PopRegisters registers
	IRP reg, <registers>
		pop reg
	ENDM 
ENDM

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Load
;	Usage    : Base_Load '..\Codes\Test.asm'
;	Desc     : Load's a file content to the program memory
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MACRO Base_Load fileList
	IRP File, <fileList>
		include File
	ENDM
ENDM
