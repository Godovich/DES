; =============================================================================
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 	Package  : DES Cipher system
; 	Created  : Tue, 17 Mar 2015 11:33:11
; 	Author   : Eyal Godovich 
; 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; =============================================================================

.386 			; Generate 32-bit code instead of 16.
IDEAL			; Syntax: IDEAL
MODEL small		; One DS and one CS Please.
STACK 100h		; Define the stack size
radix 10		; Our default radix will be decimal

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; *********************           Data Segment           ********************
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DATASEG

	; Boolean: Is encryption selected?
	encryption 		 	db 0
	
	; The key should contain 64 bits, or 8 characters.
	key 			 	db 8 dup (?)
	
	; Keys array
	Keys 				dd 32 dup (?)
	ShiftsArray 		db 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0
	
	; Permuted Choice 2 ( PC -2 )
	; http://en.wikipedia.org/wiki/DES_supplementary_material#Permuted_choice_2_.28PC-2.29
	PC2Bytes0  			dd 0h,4h,20000000h,20000004h,10000h,10004h,20010000h,20010004h,200h,204h,20000200h,20000204h,10200h,10204h,20010200h,20010204h
	PC2Bytes1  			dd 0h,1h,100000h,100001h,4000000h,4000001h,4100000h,4100001h,100h,101h,100100h,100101h,4000100h,4000101h,4100100h,4100101h
	PC2Bytes2  			dd 0h,8h,800h,808h,1000000h,1000008h,1000800h,1000808h,0h,8h,800h,808h,1000000h,1000008h,1000800h,1000808h
	PC2Bytes3  			dd 0h,200000h,8000000h,8200000h,2000h,202000h,8002000h,8202000h,20000h,220000h,8020000h,8220000h,22000h,222000h,8022000h,8222000h
	PC2Bytes4  			dd 0h,40000h,10h,40010h,0h,40000h,10h,40010h,1000h,41000h,1010h,41010h,1000h,41000h,1010h,41010h
	PC2Bytes5  			dd 0h,400h,20h,420h,0h,400h,20h,420h,2000000h,2000400h,2000020h,2000420h,2000000h,2000400h,2000020h,2000420h
	PC2Bytes6  			dd 0h,10000000h,80000h,10080000h,2h,10000002h,80002h,10080002h,0h,10000000h,80000h,10080000h,2h,10000002h,80002h,10080002h
	PC2Bytes7  			dd 0h,10000h,800h,10800h,20000000h,20010000h,20000800h,20010800h,20000h,30000h,20800h,30800h,20020000h,20030000h,20020800h,20030800h
	PC2Bytes8  			dd 0h,40000h,0h,40000h,2h,40002h,2h,40002h,2000000h,2040000h,2000000h,2040000h,2000002h,2040002h,2000002h,2040002h
	PC2Bytes9  			dd 0h,10000000h,8h,10000008h,0h,10000000h,8h,10000008h,400h,10000400h,408h,10000408h,400h,10000400h,408h,10000408h
	PC2Bytes10 			dd 0h,20h,0h,20h,100000h,100020h,100000h,100020h,2000h,2020h,2000h,2020h,102000h,102020h,102000h,102020h
	PC2Bytes11 			dd 0h,1000000h,200h,1000200h,200000h,1200000h,200200h,1200200h,4000000h,5000000h,4000200h,5000200h,4200000h,5200000h,4200200h,5200200h
	PC2Bytes12 			dd 0h,1000h,8000000h,8001000h,80000h,81000h,8080000h,8081000h,10h,1010h,8000010h,8001010h,80010h,81010h,8080010h,8081010h
	PC2Bytes13 			dd 0h,4h,100h,104h,0h,4h,100h,104h,1h,5h,101h,105h,1h,5h,101h,105h

	; Substitution box
	spfunction1 dd 16843776d ,0d ,65536d ,16843780d ,16842756d ,66564d ,4d ,65536d ,1024d ,16843776d ,16843780d ,1024d ,16778244d ,16842756d ,16777216d ,4d ,1028d ,16778240d ,16778240d ,66560d ,66560d ,16842752d ,16842752d ,16778244d ,65540d ,16777220d ,16777220d ,65540d ,0d ,1028d ,66564d ,16777216d ,65536d ,16843780d ,4d ,16842752d ,16843776d ,16777216d ,16777216d ,1024d ,16842756d ,65536d ,66560d ,16777220d ,1024d ,4d ,16778244d ,66564d ,16843780d ,65540d ,16842752d ,16778244d ,16777220d ,1028d ,66564d ,16843776d ,1028d ,16778240d ,16778240d ,0d ,65540d ,66560d ,0d ,16842756d
	spfunction2 dd -7fef7fe0h ,-7fff8000h ,8000h ,108020h ,100000h ,20h ,-7fefffe0h ,-7fff7fe0h ,-7fffffe0h ,-7fef7fe0h ,-7fef8000h ,-80000000h ,-7fff8000h ,100000h ,20h ,-7fefffe0h ,108000h ,100020h ,-7fff7fe0h ,0h ,-80000000h ,8000h ,108020h ,-7ff00000h ,100020h ,-7fffffe0h ,0h ,108000h ,8020h ,-7fef8000h ,-7ff00000h ,8020h ,0h ,108020h ,-7fefffe0h ,100000h ,-7fff7fe0h ,-7ff00000h ,-7fef8000h ,8000h ,-7ff00000h ,-7fff8000h ,20h ,-7fef7fe0h ,108020h ,20h ,8000h ,-80000000h ,8020h ,-7fef8000h ,100000h ,-7fffffe0h ,100020h ,-7fff7fe0h ,-7fffffe0h ,100020h ,108000h ,0h ,-7fff8000h ,8020h ,-80000000h ,-7fefffe0h ,-7fef7fe0h ,108000h
	spfunction3 dd 208h,8020200h,0h,8020008h,8000200h,0h,20208h,8000200h,20008h,8000008h,8000008h,20000h,8020208h,20008h,8020000h,208h,8000000h,8h,8020200h,200h,20200h,8020000h,8020008h,20208h,8000208h,20200h,20000h,8000208h,8h,8020208h,200h,8000000h,8020200h,8000000h,20008h,208h,20000h,8020200h,8000200h,0h,200h,20008h,8020208h,8000200h,8000008h,200h,0h,8020008h,8000208h,20000h,8000000h,8020208h,8h,20208h,20200h,8000008h,8020000h,8000208h,208h,8020000h,20208h,8h,8020008h,20200h
	spfunction4 dd 802001h,2081h,2081h,80h,802080h,800081h,800001h,2001h,0h,802000h,802000h,802081h,81h,0h,800080h,800001h,1h,2000h,800000h,802001h,80h,800000h,2001h,2080h,800081h,1h,2080h,800080h,2000h,802080h,802081h,81h,800080h,800001h,802000h,802081h,81h,0h,0h,802000h,2080h,800080h,800081h,1h,802001h,2081h,2081h,80h,802081h,81h,1h,2000h,800001h,2001h,802080h,800081h,2001h,2080h,800000h,802001h,80h,800000h,2000h,802080h
	spfunction5 dd 100h,2080100h,2080000h,42000100h,80000h,100h,40000000h,2080000h,40080100h,80000h,2000100h,40080100h,42000100h,42080000h,80100h,40000000h,2000000h,40080000h,40080000h,0h,40000100h,42080100h,42080100h,2000100h,42080000h,40000100h,0h,42000000h,2080100h,2000000h,42000000h,80100h,80000h,42000100h,100h,2000000h,40000000h,2080000h,42000100h,40080100h,2000100h,40000000h,42080000h,2080100h,40080100h,100h,2000000h,42080000h,42080100h,80100h,42000000h,42080100h,2080000h,0h,40080000h,42000000h,80100h,2000100h,40000100h,80000h,0h,40080000h,2080100h,40000100h
	spfunction6 dd 20000010h,20400000h,4000h,20404010h,20400000h,10h,20404010h,400000h,20004000h,404010h,400000h,20000010h,400010h,20004000h,20000000h,4010h,0h,400010h,20004010h,4000h,404000h,20004010h,10h,20400010h,20400010h,0h,404010h,20404000h,4010h,404000h,20404000h,20000000h,20004000h,10h,20400010h,404000h,20404010h,400000h,4010h,20000010h,400000h,20004000h,20000000h,4010h,20000010h,20404010h,404000h,20400000h,404010h,20404000h,0h,20400010h,10h,4000h,20400000h,404010h,4000h,400010h,20004010h,0h,20404000h,20000000h,400010h,20004010h
	spfunction7 dd 200000h,4200002h,4000802h,0h,800h,4000802h,200802h,4200800h,4200802h,200000h,0h,4000002h,2h,4000000h,4200002h,802h,4000800h,200802h,200002h,4000800h,4000002h,4200000h,4200800h,200002h,4200000h,800h,802h,4200802h,200800h,2h,4000000h,200800h,4000000h,200800h,200000h,4000802h,4000802h,4200002h,4200002h,2h,200002h,4000000h,4000800h,200000h,4200800h,802h,200802h,4200800h,802h,4000002h,4200802h,4200000h,200800h,0h,2h,4200802h,0h,200802h,4200000h,800h,4000002h,4000800h,800h,200002h
	spfunction8 dd 10001040h,1000h,40000h,10041040h,10000000h,10001040h,40h,10000000h,40040h,10040000h,10041040h,41000h,10041000h,41040h,1000h,40h,10040000h,10000040h,10001000h,1040h,41000h,40040h,10040040h,10041000h,1040h,0h,0h,10040040h,10000040h,10001000h,41040h,40000h,41040h,40000h,10041000h,1000h,40h,10040040h,1000h,41040h,10001000h,40h,10000040h,10040000h,10040040h,10000000h,40000h,10001040h,0h,10041040h,40040h,10000040h,10040000h,10001000h,10001040h,0h,10041040h,41000h,41000h,1040h,1040h,40040h,10000000h,10041000h

	; "Temp" variables, multi-use
	RightTemp 			dd 0h
	LeftTemp  			dd 0h
	KeyNum 				dw 0
	TempDW 				dd 0
	Left   				dd 0
	Right  				dd 0 
	i 					dw 0
	Right1				dd 0
	Left1				dd 0
	Right2				dd 0
	Left2				dd 0
	Key1 				dd 0h
	Key2 				dd 0h
	m 					dw 0


	output db 4096 dup (20h)
	outputc dw 0

	; Because we are creating a 16-bit code, our code segment have a mximum of 64k, and we pretty much used 37kb ( approximately ) already, so we have only 28kb free (2^16 - 37000 = 28536 bytes or 28.536 kb)
	; Maximum Input file string size: 29kb
	inputFileMaxSize	equ 28000
	inputFileHandle 	dw ?
	inputFileContent 	db inputFileMaxSize dup (20h) ; Fill up the empty spaces with spaces
	inputFileContentDec db inputFileMaxSize dup (20h) ; Fill up the empty spaces with spaces
	inputFileSize		dw ?
	
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; *********************           Code Segment           ********************
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CODESEG
	
	; Include all of my macros and procedures from the library folder
	include '..\Codes\Library\Base.asm'
	include '..\Codes\Library\Console.asm'
	include '..\Codes\Library\String.asm'
	include '..\Codes\Library\Debug.asm'
	include '..\Codes\Library\File.asm'
	
	; Include the program files ( the main code )
	include '..\Codes\Perm.asm'
	include '..\Codes\Key.asm'
	include '..\Codes\Encrypt.asm'
	
start:
	mov ax, @data
	mov ds, ax
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Header	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	Console_ClearScreen
	Console_PrintHeader
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Check if input.txt exists!
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	File_exists '..\Input.txt', cx 	  ; File_Exists returns 2 if the file doesn't exist
	cmp cx, 2 						  ; Check if the return value equals to 2
	jne @@OPTIONS 					  ; If <> than 2, the file exists, that means, jump to the next step.
	
	File_Create '..\Input.txt', inputFileHandle	  ; The file doesn't exist, let's create a new one.
	Console_WriteLine ' Attention: Input.txt have just been created!'
	Console_WriteLine

	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Encryption/Decryption selection
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	@@OPTIONS:
	Console_WriteLine ' Please enter your string into the "input.txt" file and then continue'
	Console_WriteLine
	Console_WriteLine ' Please select your option: (1) Encryption'
	Console_WriteLine '                            (2) Decryption'
	Console_WriteLine '                            (3) Exit      '
	Console_NewLine
	Console_Write ' What is your selection? : '
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Receive Encryption/Decryption selection input
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	String_Scan encryption, 1	; Get one character input from user

	cmp [encryption], '3'
	je exit
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Filter the selection input, only allow 1 or 2
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	mov al, [encryption]		; Move the selected mode to the lower part of ax
	sub al, 1 					; Turn 2 -> 1, 1 -> 0
	xor al, 00110000b 			; Xor the ascii value with ascii '0'
	shr al, 1 					; Only 00000001b and 00000000b will turn on the zero-flag
	jz @@SKIP_OPTIONS_ERROR  	; OK, we can continue.

	; Well, I really need the user to choose between encryption and decryption.
	; I know it's a hard choice, but please!
	; So.. let's try again!
	
	Console_ClearScreen
	Console_PrintHeader
	Console_WriteLine ' Invalid selection! '
	Console_NewLine

	; Loop over and over again until the user selects a valid mode
	jmp @@OPTIONS

	; Great! continue...
	@@SKIP_OPTIONS_ERROR:
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Read Input.txt size!
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	File_Open '..\Input.txt', 2, inputFileHandle
	File_Size inputFileHandle, bx					; Get size of the file and put it in bx

	; Move the size to the inputFileSize variable
	mov [inputFileSize], bx

	; Check to see if the file size is bigger than zero
	cmp [inputFileSize], 0
	JNE @@CHECK_MAXIMUM

	Console_ClearScreen
	Console_PrintHeader
	Console_WriteLine ' Attention: Please enter your string to input.txt!'
	Console_WriteLine
	File_Close inputFileHandle						; Now we can close the file.
	jmp @@OPTIONS

	@@CHECK_MAXIMUM:
	
	; Ok, so now we have the file size stored in bx, we need to check that the
	; file size is smaller than the maximum size we selected.
	cmp bx, inputFileMaxSize						; Compare with the maximum defined.
	jb @@READ_INPUT								    ; If smaller, skip the error message.
	
	; This file size is bigger than the maximum.
	Console_ClearScreen
	Console_PrintHeader
	Console_WriteLine ' Attention: Input.txt is too big!'
	Console_WriteLine '            Maximum size: 29kb'
	Console_WriteLine
	File_Close inputFileHandle						; Now we can close the file.

	; Great! continue...
	@@READ_INPUT:
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Read Input.txt content!
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	File_Read_All inputFileHandle, inputFileContent	; Read everything!
	File_Close inputFileHandle						; Now we can close the file.


	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Format the received hex (if at all)
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	; Skip this part if the user selected encryption
	cmp [encryption], '2'
	jne @@SKIP_HEX_FORMATTING

	mov ax, [inputFileSize]
	or ax, 1
	cmp ax, 1
	je @@ERROR_NOT_HEX

	; Clear the counter variable
	xor cx, cx

	; Load the string to the memory
	lea si, [inputFileContent]
	
	@@CHAR_LOOP:
		lodsb 	  			 ; Load byte from the string in SI
		mov ah, al           ; Move the byte to ah
		lodsb				 ; Load byte from the string in SI
		
		; Check if the characters are both hex characters

		; Check if the first character is an actual hex character
		String_IsHex al
		cmp dx, 1
		JNE @@ERROR_NOT_HEX

		; Check if the second character is an actual hex character
		String_IsHex ah
		cmp dx, 1
		JNE @@ERROR_NOT_HEX

		; Get the acsii value of both characters
		String_CharToASCII al
		String_CharToASCII ah

		; Set the first character as the higher-nibble
		shl ah, 4
		add ah, al

		; Set the next character in the string
		mov bx, cx
		shr bx, 1 ; Divide by two
		mov [inputFileContentDec + bx], ah

		; We used 2 bytes, so let's add them to our count
		add cx, 2

		; if( BytesChecked < BytesTotal )
		cmp cx, [inputFileSize]
		jne  @@CHAR_LOOP	 ; And now to the next character

	jmp @@SKIP_HEX_FORMATTING

	@@ERROR_NOT_HEX:
		Console_ClearScreen
		Console_PrintHeader	
		Console_WriteLine " Attention: The program can only accept hex string for decryption!"
		Console_WriteLine
		jmp @@OPTIONS

	@@SKIP_HEX_FORMATTING:
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Receive key from user
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	Console_ClearScreen
	Console_PrintHeader

	@@RECEIVE_KEY:
	
	Console_WriteLine ' Details: '
	Console_WriteLine '  - Input  : Input.txt'
	Console_Write '  - Mode   : '

	cmp [encryption], '1'
	JE @@MODE_ENCRYPTION
	JNE @@MODE_DECRYPTION

	@@MODE_ENCRYPTION:
		Console_WriteLine 'Encryption '
		jmp @@SKIP_MODE
	@@MODE_DECRYPTION:
		Console_WriteLine 'Decryption '

	@@SKIP_MODE:
	Console_WriteLine
	Console_Write ' Please enter your 64-bit key (8 characters) : '

	String_Scan key, 8 ; Get the key string from the user
	
	; Check if the key is indeed 64 bytes
	lea si, [key]
	String_GetSize cx
	cmp cx, 8
	je @@EXPAND_KEYS
	
	; The key isn't 64 bytes!
	Console_ClearScreen
	Console_PrintHeader
	Console_WriteLine ' Error: The key should be 8 characters long!'
	Console_WriteLine
	jmp @@RECEIVE_KEY

	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Expand the key!
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	@@EXPAND_KEYS:

		; Expand the key to additional 16 keys ( Each key has left and right, so actually I stored it as 32 different keys)
		; You can read more about the key schedule in the official wikipedia page.
		; http://en.wikipedia.org/wiki/Data_Encryption_Standard#Key_schedule
		Key_Expand
		
		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		;	Results!
		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		; Print the Header
		Console_ClearScreen
		Console_PrintHeader

		Console_WriteLine ' Details: '
		Console_WriteLine '  - Input  : Input.txt'
		Console_Write '  - Mode   : '

		cmp [encryption], '1'
		JE @@PRINT_ENCRYPTION
		JNE @@PRINT_DECRYPTION

		@@PRINT_ENCRYPTION:
			Console_WriteLine 'Encryption '
			jmp @@SKIP_PRINT
		@@PRINT_DECRYPTION:
			Console_WriteLine 'Decryption '

		@@SKIP_PRINT:

		; Print the key, nothing special here
		Console_Write '  - Key    : "'
		mov al, [key + 8]
		mov [key + 8], '$'
		lea dx, [key]
		mov ah, 9
		int 21h
		mov [key + 8], al

		Console_WriteLine '"'
		Console_Write '  - Length : '
		mov ax, [inputFileSize]
    	Console_PrintNumberByBase ax, 10
		
		Console_WriteLine
		Console_WriteLine

		cmp [encryption], '1'
		je @@encryption
		jne @@decryption
			
		@@encryption:

			Console_Write '  - Hex    : '

			; Run the encryption
			Encrypt_Run 1
	
			jmp @@finish
		
		@@decryption:

			Console_Write '  - Text   : '

			; Run the decryption
			Encrypt_Run 0		
			
			jmp @@finish
			
		@@finish:
		
exit:
	Console_NewLine

	Console_WriteLine ' ------------------------------------------------------------------------------' 
	
	mov ax, 4c00h
	int 21h
END start
