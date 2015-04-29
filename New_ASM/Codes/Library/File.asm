; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Sat, 14 Mar 2015 09:58:20
; 	Author   : Eyal Godovich
; 	File     : File.asm
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; ---------------------------------------------------------------------------
; | Error Code  |    Meaning
; ---------------------------------------------------------------------------
; |      1      |    Invalid function number
; |      2      |    File not found
; |      3      |    Path not found
; |      4      |    All available handles in use
; |      5      |    Access denied (file may already be open by another process)
; |      6      |    Invalid file handle
; |      C      |    Invalid access code
; |      F      |    Invalid drive specified
; |      10     |    Attempt to remove current directory
; |      11     |    Not the same device
; |      12     |    No more files to be found
; ---------------------------------------------------------------------------
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Open
;	Usage    : File_Open 'Input.txt', 2, variable_handler
;	Desc     : Opens the given file with the given permissions.
;			   Possible permissions: 0 - Read only, 1 - Write only, 2 - Read & write
;			   Extra: if error is detected, the handler will become -1.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro File_Open FileName, perm, handler
	local @@file_name, @@start, @@error, @@exit
	
	Base_PushRegisters <ax, dx, ds>
	
	; Explantation: The string is being stored in the code segment instead of
	;				of the data segment, so we can skip over it.
	jmp @@start
	
	; Store the string, followd by ascii zero
	@@file_name db FileName, 0
	
	@@start:    
		
		; Switch batween the code segment and the data segment
		mov  ax,cs 
		mov  ds,ax
		
		; Now we'll load the string that is actually stored in the code segment to dx, we tricked
		; the system, so it will take the string from the code segment instead of the data segment.
		lea  dx, [cs:@@file_name]
		
		; ah = 3Dh means open existing file
		mov ah, 3Dh
		
		; Set access and sharing modes
		mov al, 2
		
		; Open the file!
		int 21h
		mov [cs:handler], ax

		; Carry flag is set on error
		jc @@error
		
		; Finished!
		jmp @@exit
		
		; Self-explanatory
		@@error:
			mov [handler], -1
			Console_NewLine
			Console_Write 'Error: Cant open file! ( Code: '
			Console_PrintNumberByBase ax, 16
			Console_WriteLine ' )'
		
	@@exit:
		Base_PopRegisters <ds, dx, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Close
;	Usage    : File_Close file_handler
;	Desc     : Close the file 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro File_Close handle
	local @@error, @@exit
	
	; Save the current value of ax & bx
	Base_PushRegisters <ax, bx>
	
	; ah = 3Eh means close file
	mov ah,3Eh
	
	; bx needs to store the file handle
	mov bx, [handle]
	
	; Close the file
	int 21h
	jc @@error
	jnc @@exit
	
	@@error:
		mov [handle], -1
		Console_NewLine
		Console_Write 'Error: Cant close file! ( Code: '
		Console_PrintNumberByBase ax, 16
		Console_WriteLine ' )'
		
	@@exit:
	; Restore the original value of ax & bx
	Base_PopRegisters <bx, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Create
;	Usage    : File_Create '..\Input.txt'
;	Desc     : Creates a file
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro File_Create name, handle
	local @@file_name, @@start, @@error, @@exit
	
	Base_PushRegisters <cx, ax, dx, ds>
	
	; Explantation: The string is being stored in the code segment instead of
	;				of the data segment, so we can skip over it.
	jmp @@start
	
	; Store the string, followd by ascii zero
	@@file_name db &name, 0
	
	@@start:    
		
		; Switch batween the code segment and the data segment
		mov  ax,cs 
		mov  ds,ax
		
		; Now we'll load the string that is actually stored in the code segment to dx, we tricked
		; the system, so it will take the string from the code segment instead of the data segment.
		lea  dx, [cs:@@file_name]
		
		; ah = 3Ch means create file
		mov ah, 3Ch
		
		; Set file attributes
		xor cx, cx
		
		; Open the file!
		int 21h

		; Carry flag is set on error
		jc @@error



		mov [cs:handle], ax
		File_Close cs:handle
		
		; Finished!
		jmp @@exit
		
		; Self-explanatory
		@@error:
			Console_NewLine
			Console_Write 'Error: Cant create file! ( Code: '
			Console_PrintNumberByBase ax, 16
			Console_WriteLine ' )'
		
		
	@@exit:
	Base_PopRegisters <ds, dx, ax, cx>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : SetPointer
;	Usage    : File_SetPointer handle, 2
;	Desc     : Set's the file pointer position (0 start, 2 end)
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro File_SetPointer handle, pos
	local @@exit, @@error
	
	; Save the current value of ax, dx and cx
	Base_PushRegisters <ax, bx, cx, dx>
	
	; ah = 42h means move file pointer
	mov ah, 42h     
	
	; BX needs to contain the file handle
	mov bx, [handle]
	
	; Clear cx
	xor cx, cx
	
	; 0 Bytes to move
	xor dx, dx
	
	; Set pointer in the end of the file
	mov al, pos
	
	; Move pointer to the end of the file, AX = File size
	int 21h
	
	; CF=1 means error
	jc @@error
	
	; No error, exit!
	jmp @@exit
	
	@@error:
		Console_NewLine
		Console_Write 'Error: Cant read file size! ( Code: '
		Console_PrintNumberByBase ax, 16
		Console_WriteLine 'h )'
	
	@@exit:
	; Pop the registers back
	Base_PopRegisters <dx, cx, bx, ax>
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Size
;	Usage    : File_Size handle, cx
;	Desc     : Get's the file size
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro File_Size handle, dst
	local @@exit, @@error
	
	; Save the current value of ax, dx and cx
	Base_PushRegisters <ax, bx, cx, dx>
	
	; ah = 42h means move file pointer
	mov ah, 42h     
	
	; BX needs to contain the file handle
	mov bx, [handle]
	
	; Clear cx
	xor cx, cx
	
	; 0 Bytes to move
	xor dx, dx
	
	; Set pointer in the end of the file
	mov al, 2
	
	; Move pointer to the end of the file, AX = File size
	int 21h
	
	; CF=1 means error
	jc @@error
	
	; No error, exit!
	jmp @@exit
	
	@@error:
		Console_NewLine
		Console_Write 'Error: Cant read file size! ( Code: '
		Console_PrintNumberByBase ax, 16
		Console_WriteLine 'h )'
	
	@@exit:
	
	; Pop the registers back
	Base_PopRegisters <dx, cx, bx>
	; Set dst to file size
	mov dst, ax
	pop ax
	
	File_SetPointer handle, 0
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Read_All
;	Usage    : File_Read_All file_handle, Some_String_Variable
;	Desc     : Reads all file data into string variable
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro File_Read_All handle, string
	; Save current value of bx
	push bx
	
	; Get the file size because we need to know how much bytes we need to read from the file
	File_Size handle, bx
	
	; Now we can read the bytes from the file and store them in string
	File_Read handle, bx, string
	
	; Restore the original value
	pop bx
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Read
;	Usage    : File_Read file_handle, 16, Some_String_Variable
;	Desc     : Reads part of the file data into string variable
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro File_Read handle, bytes, string
	local @@error, @@exit
	
	; Save current values of ax, bx, cx, dx
	Base_PushRegisters <ax, bx, cx, dx>
	
	; How much bytes do you want to read?
	mov cx, bytes
	
	; ah=3Fh means read data from file
	mov ah,3Fh
	
	; BX will contain the file handle
	mov bx, [handle]
	
	; DX will contain the string output location
	mov dx,offset string
	
	; Read!
	int 21h
	
	; CF=1 in case of error
	jc @@error
	
	; No error, skip.
	jmp @@exit
	
	; Self-explanatory
	@@error:
		Console_NewLine
		Console_Write 'Error: Cant read file size! ( Code: '
		Console_PrintNumberByBase ax, 16
		Console_WriteLine 'h )'
	
	@@exit:
	Base_PopRegisters <dx, cx, bx, ax>
	
endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	Name     : Exists
;	Usage    : File_Exists 'Input.txt', handle
;	Desc     : Checks if the file exists, 
;			   handle == 0FFh means doesnt exists
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

macro File_Exists name, handle
	local @@file_name, @@start, @@error, @@exit
	
	Base_PushRegisters <bx, ax, dx, ds>
	
	; Explantation: The string is being stored in the code segment instead of
	;				of the data segment, so we can skip over it.
	jmp @@start
	
	; Store the string, followd by ascii zero
	@@file_name db &name, 0
	
	@@start:    
		
		; Switch batween the code segment and the data segment
		mov  ax,cs 
		mov  ds,ax
		
		; Now we'll load the string that is actually stored in the code segment to dx, we tricked
		; the system, so it will take the string from the code segment instead of the data segment.
		lea  dx, [cs:@@file_name]
		
		; ah = 3Dh means open existing file
		mov ah, 3Dh
		
		; Set access and sharing modes
		mov al, 0
		
		; Open the file!
		int 21h
		
		; Carry flag is set on error
		jc @@error
		
		; Everything went fine, we can store the file handler
		mov handle, ax ; File status

		; Close the file

		mov bx, ax
		mov ah, 3Eh
		int 21h
		
		; Finished!
		jmp @@exit
		
		; Self-explanatory
		@@error:
			mov handle, 2
		
		@@exit:
		Base_PopRegisters <ds, dx, ax, bx>

endm

macro File_CheckIfInputExists label

	File_exists '..\Input.txt', cx 	  ; File_Exists returns 2 if the file doesn't exist
	cmp cx, 2 						  ; Check if the return value equals to 2
	jne label 					  	  ; If <> than 2, the file exists, that means, jump to the next step.
	
	File_Create '..\Input.txt', inputFileHandle	  ; The file doesn't exist, let's create a new one.
	Console_ClearScreen
	Console_PrintHeader
	Console_WriteLine ' Attention: Input.txt have just been created!'
	Console_WriteLine

	jmp @@OPTIONS

endm
