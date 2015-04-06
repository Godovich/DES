; I need to generate 32-bit code
.386

VERSION M520 
IDEAL
MODEL small		; Defines a 16-bit assembly model
STACK 100h		; Sets the stack size
NOWARN ; I DONT WANT ANY FUCKING WARNINGS ANY MORE! PLEASE STOP IT!	  
RADIX 10 ; Default radix ( decimal )


DATASEG ; Start the data segment

	include '..\..\Codes\Vars.ASM' ; Import all of our variables

CODESEG

	include '..\..\Codes\Macros\Macros.mac'    ; Import project macros
	include '..\..\Codes\Macros\Gvahim.mac'    ; Import auxiliary macros
	
	include '..\..\Codes\Gvahim.asm'    	   ; Import auxiliary procedures
	include '..\..\Codes\Auxi.asm'             ; Import project auxiliary procedures

	include '..\..\Codes\Keys.asm'             ; -> All methods assosiated with keys creation.
	include '..\..\Codes\Encrypt.asm'          ; -> The actual encryption/decryption procedure.
	
	start:
		mov ax, @data
		mov ds, ax
		
		call DeleteOutput
		call CreateOutput
		
		;------------------------------------------------------------
		; Check if the user wants encryption or decryption
		;------------------------------------------------------------
		
		print ' ------------------------------------------------------------------------------' 
		CALL NEW_LINE
		print '                       DES Cipher System by Eyal Godovich' 
		CALL NEW_LINE
		print ' ------------------------------------------------------------------------------' 
		
		CALL NEW_LINE
		CALL NEW_LINE
		print ' Encryption or Decryption ? (1/0): '
		
		;------------------------------------------------------------
		; Receive input
		;------------------------------------------------------------
		mov si, offset encrypt
		mov cx, 2
		call SCAN_STR
		mov al, [encrypt]
		
		; We only want 1/0
		cmp al, '1'
		JE @@IS_0_OR_1
		
		cmp al, '0'
		JE @@IS_0_OR_1
		
		; Oops!
		print ' Oops, only 0 or 1 is allowed!'
		jmp exit
		
		; Everything's alright, continue as usual!
		@@IS_0_OR_1:
		
		;------------------------------------------------------------
		; Receive Key from user
		;------------------------------------------------------------
		print ' Please enter your 8-byte key: '
		mov si, offset key
		mov cx, 9
		call SCAN_STR
		
		cmp cx, 8
		JE @@RECEIVE_STRING
	
		call NEW_LINE
		call NEW_LINE
		print ' Error: The key must be 8-byte long!'
		jmp exit
			
		;------------------------------------------------------------
		; From file ?
		;------------------------------------------------------------
		
		@@RECEIVE_STRING:
		
		;call NEW_LINE
		;print ' Did you used Input.txt? (0/1): '
		;mov si, offset input
		;mov cx, 2
		;call SCAN_STR

		;cmp [input], '1'
		JE FromFile
		;JNE TakeInput
		print ' Attention: The maximum input from file is 4096 bytes.'
		
		;------------------------------------------------------------
		; Receive String from user
		;------------------------------------------------------------
		
		FromFile:
		
		cmp [encrypt], '1'
		JE EncryptionFile
		JNE DecryptionFile
		
		EncryptionFile:
			call OpenInputFile
			call ReadFile
			
			mov [EncDecLength], ax
			mov bx, [EncDecLength]
			mov [EncDecString + bx], 0
		
			call CloseFile
			
			call ReplaceNullBytesInEnc
			
			jmp Output_Data

		DecryptionFile:
			call OpenInputFile
			call ReadFileToDec
			
			mov cx, ax
			; cx already contains the length
			call hexToString
			
			call CloseFile
		
			jmp Output_Data
		
		TakeInput:
			
			cmp [encrypt], '1'
			JE @@EncryptionString
			JNE @@DecryptionString
			
			
			@@DecryptionString:
				print ' Please enter your string (Base: 16 | Max: 64): '
				call NEW_LINE
				putc ' '
				
				mov si, offset DecString
				mov cx, 128d ; 32 + '0'
				call SCAN_STR
				
				; cx already contains the length
				call hexToString
			jmp Output_Data
			
			
			@@EncryptionString:
				print ' Please enter your string (Max: 64): '
				call NEW_LINE
				putc ' '
				
				mov si, offset EncDecString
				mov cx, 129d ; 128 + '0'
				call SCAN_STR
				
				; Add 8 spaces on the right of the message
				
				mov [EncDecLength], cx
				mov bx, [EncDecLength]	
				
				REPT 64
					mov [EncDecString + bx], ' '
					inc bl
				ENDM
				
				mov [EncDecString + bx], 0 ; ASCII zero in the end ( if I want to print the string )
				
		Output_Data:
		;------------------------------------------------------------
		; Output data
		;------------------------------------------------------------
		call NEW_LINE
		

		print ' ------------------------------------------------------------------------------' 
		CALL NEW_LINE
		print '                                      Data' 
		CALL NEW_LINE
		print ' ------------------------------------------------------------------------------' 
		CALL NEW_LINE
		
		CALL NEW_LINE
		
		print ' Process: '
		mov al,[encrypt]
		sub al, '0'
		CMP al, 1d
		JE SkipData
		JNE IS_0
		
		SkipData:
		print 'Encryption'
		jmp SKIP_DATA
		
		IS_0:
			print 'Decryption'
			
		SKIP_DATA:
		
		call NEW_LINE
		print ' Length : '
		mov ax, [EncDecLength]
		call PRINT_NUM_DEC
		call NEW_LINE
		
		;------------------------------------------------------------
		; Create Keys
		;------------------------------------------------------------
		call ExpandKeys
		
		;------------------------------------------------------------
		; Encrypt/Decrypt
		;------------------------------------------------------------
		call NEW_LINE
		print ' Output: '
		call NEW_LINE
		print ' '
		
		call RunEncryption
		
		;------------------------------------------------------------
		; End of main code
		;------------------------------------------------------------
		jmp exit

		;------------------------------------------------------------
		; Exit
		;------------------------------------------------------------
		exit:
		
		call NEW_LINE
		mov ax, 4C00h
		int 21h

	END start