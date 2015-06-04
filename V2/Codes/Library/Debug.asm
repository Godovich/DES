; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Fri, 13 Mar 2015 14:36:46
; 	Author   : Eyal Godovich
; 	File     : Debug.asm
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : PrintRegister
;	Usage    : Debug_PrintRegister ax
;	Desc     : Will print the name of the register followd by =
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Debug_PrintRegister register
	local @@msg, @@start
	
	; Save the current value of the registers
	Base_PushRegisters <ax, ds, si>

	; Explantation: The string is being stored in the code segment instead of
	;				of the data segment, so we can skip over it.
	jmp @@start
	
	; Store the string, followd by ascii zero.
	@@msg db "&register = ", 0
	
	@@start:    
		
		; Switch batween the code segment and the data segment
		mov  ax,cs 
		mov  ds,ax
		
		; Now we'll print the string that is actually stored in the code segment, we tricked
		; the system, so it will take the string from the code segment instead of the data segment.
		lea  si, [cs:@@msg] 
		Console_PrintString
	
	; Restore the original values
	Base_PopRegisters <si, ds, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Register_8
;	Usage    : Debug_Register_8 al
;	Desc     : Will print the hex value of 8-bit register
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Debug_Register_8 reg

	; Print the name of the register followd by =
	Debug_PrintRegister reg
	
	; Save the current value of ax
	Base_PushRegisters ax
	
	; Zero-extend reg into ax, same as: (mov ax, 0) & (mov al, reg)
	movzx ax, reg
	
	; Print the hexdecimal value of the register followd by "h"
	Console_PrintNumberByBase ax, 16
	Console_Write 'h ( '
	
	; Print the decimal value of the register followd by "d"
	Console_PrintNumberByBase ax, 10
	Console_Write 'd )'
	
	; Restore the original value of ax
	Base_PopRegisters ax
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Register_16
;	Usage    : Debug_Register_16 ax
;	Desc     : Will print the hex value of 16-bit register
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Debug_Register_16 reg
	
	; Print the name of the register followd by =
	Debug_PrintRegister reg
	
	; Print the hexdecimal value of the register followd by "h"
	Console_PrintNumberByBase reg, 16
	Console_Write 'h ( '
	
	; Print the decimal value of the register followd by "d"
	Console_PrintNumberByBase reg, 10
	Console_Write 'd )'
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Register_32
;	Usage    : Debug_Register_32 eax
;	Desc     : Will print the hex value of 32-bit register
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro Debug_Register_32 reg, x
	; Print the name of the register followd by =
	; Debug_PrintRegister reg
	
	; Save the current value of eax
    push ebx
    
	; Print the left side of the register
    mov ebx, reg
    shr ebx, 16d
    Console_PrintNumberByBase bx, x
    
	; Print the right side of the register
    mov ebx, reg
    Console_PrintNumberByBase bx, x
	
	; Print "h"
	; Console_Write 'h'
    
	; Restore the original value of eax
    pop ebx
endm 