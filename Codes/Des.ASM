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
	encryption 		 	db ?
	
	; The key should contain 64 bits, or 8 characters.
	key 			 	db 8 dup (?)
	
	; Keys array
	Keys 				dd 32 dup (?)

	; Subkey Rotations.  Part of the subkey generation process
    ; involves rotating certain bit-sections of the keystuff by either
    ; one or two bits to the left.  This table specifies how many bits
    ; to rotate left for each of the 16 steps.
	ShiftsArray 		db 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0
	
	; PC2 Permutation.  The subkey generation process applies this
    ; permutation to transform its running 56-bit keystuff value into
    ; the final set of 16 48-bit subkeys.
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

    ; Substitution Boxes.  A crucial step in the Feistel function is
    ; to perform bit substitutions according to this table.  A 48-bit
    ; value is split into 6-bit sections, and each section is permuted
    ; into a different 6-bit value according to these eight tables.
    ; (One table for each section.)
    ; 
    ;  According to Wikipedia:
    ;  "The S-boxes provide the core of the security of DES - without
    ;  them, the cipher would be linear, and trivially breakable."
    ;
    ; The original Substitution boxes
    ; S1:
    ;    14, 4,  13, 1,  2,  15, 11, 8,  3,  10, 6,  12, 5,  9,  0,  7,
    ;    0,  15, 7,  4,  14, 2,  13, 1,  10, 6,  12, 11, 9,  5,  3,  8,
    ;    4,  1,  14, 8,  13, 6,  2,  11, 15, 12, 9,  7,  3,  10, 5,  0,
    ;    15, 12, 8,  2,  4,  9,  1,  7,  5,  11, 3,  14, 10, 0,  6,  13
    ; S2:
    ;    15, 1,  8,  14, 6,  11, 3,  4,  9,  7,  2,  13, 12, 0,  5,  10,
    ;    3,  13, 4,  7,  15, 2,  8,  14, 12, 0,  1,  10, 6,  9,  11, 5,
    ;    0,  14, 7,  11, 10, 4,  13, 1,  5,  8,  12, 6,  9,  3,  2,  15,
    ;    13, 8,  10, 1,  3,  15, 4,  2,  11, 6,  7,  12, 0,  5,  14, 9
    ; S3:
    ;    10, 0,  9,  14, 6,  3,  15, 5,  1,  13, 12, 7,  11, 4,  2,  8,
    ;    13, 7,  0,  9,  3,  4,  6,  10, 2,  8,  5,  14, 12, 11, 15, 1,
    ;    13, 6,  4,  9,  8,  15, 3,  0,  11, 1,  2,  12, 5,  10, 14, 7,
    ;    1,  10, 13, 0,  6,  9,  8,  7,  4,  15, 14, 3,  11, 5,  2,  12
    ; S4:
    ;    7,  13, 14, 3,  0,  6,  9,  10, 1,  2,  8,  5,  11, 12, 4,  15,
    ;    13, 8,  11, 5,  6,  15, 0,  3,  4,  7,  2,  12, 1,  10, 14, 9,
    ;    10, 6,  9,  0,  12, 11, 7,  13, 15, 1,  3,  14, 5,  2,  8,  4,
    ;    3,  15, 0,  6,  10, 1,  13, 8,  9,  4,  5,  11, 12, 7,  2,  14
    ; S5:
    ;    2,  12, 4,  1,  7,  10, 11, 6,  8,  5,  3,  15, 13, 0,  14, 9,
    ;    14, 11, 2,  12, 4,  7,  13, 1,  5,  0,  15, 10, 3,  9,  8,  6,
    ;    4,  2,  1,  11, 10, 13, 7,  8,  15, 9,  12, 5,  6,  3,  0,  14,
    ;    11, 8,  12, 7,  1,  14, 2,  13, 6,  15, 0,  9,  10, 4,  5,  3
    ; S6:
    ;    12, 1,  10, 15, 9,  2,  6,  8,  0,  13, 3,  4,  14, 7,  5,  11,
    ;    10, 15, 4,  2,  7,  12, 9,  5,  6,  1,  13, 14, 0,  11, 3,  8,
    ;    9,  14, 15, 5,  2,  8,  12, 3,  7,  0,  4,  10, 1,  13, 11, 6,
    ;    4,  3,  2,  12, 9,  5,  15, 10, 11, 14, 1,  7,  6,  0,  8,  13
    ; S7:
    ;    4,  11, 2,  14, 15, 0,  8,  13, 3,  12, 9,  7,  5,  10, 6,  1,
    ;    13, 0,  11, 7,  4,  9,  1,  10, 14, 3,  5,  12, 2,  15, 8,  6,
    ;    1,  4,  11, 13, 12, 3,  7,  14, 10, 15, 6,  8,  0,  5,  9,  2,
    ;    6,  11, 13, 8,  1,  4,  10, 7,  9,  5,  0,  15, 14, 2,  3,  12
    ; S8:
    ;    13, 2,  8,  4,  6,  15, 11, 1,  10, 9,  3,  14, 5,  0,  12, 7,
    ;    1,  15, 13, 8,  10, 3,  7,  4,  12, 5,  6,  11, 0,  14, 9,  2,
    ;    7,  11, 4,  1,  9,  12, 14, 2,  0,  6,  10, 13, 15, 3,  5,  8,
    ;    2,  1,  14, 7,  4,  10, 8,  13, 15, 12, 9,  0,  3,  5,  6,  11

	spfunction1 dd 16843776d ,0d ,65536d ,16843780d ,16842756d ,66564d ,4d ,65536d ,1024d ,16843776d ,16843780d ,1024d ,16778244d ,16842756d ,16777216d ,4d ,1028d ,16778240d ,16778240d ,66560d ,66560d ,16842752d ,16842752d ,16778244d ,65540d ,16777220d ,16777220d ,65540d ,0d ,1028d ,66564d ,16777216d ,65536d ,16843780d ,4d ,16842752d ,16843776d ,16777216d ,16777216d ,1024d ,16842756d ,65536d ,66560d ,16777220d ,1024d ,4d ,16778244d ,66564d ,16843780d ,65540d ,16842752d ,16778244d ,16777220d ,1028d ,66564d ,16843776d ,1028d ,16778240d ,16778240d ,0d ,65540d ,66560d ,0d ,16842756d
	spfunction2 dd -7fef7fe0h ,-7fff8000h ,8000h ,108020h ,100000h ,20h ,-7fefffe0h ,-7fff7fe0h ,-7fffffe0h ,-7fef7fe0h ,-7fef8000h ,-80000000h ,-7fff8000h ,100000h ,20h ,-7fefffe0h ,108000h ,100020h ,-7fff7fe0h ,0h ,-80000000h ,8000h ,108020h ,-7ff00000h ,100020h ,-7fffffe0h ,0h ,108000h ,8020h ,-7fef8000h ,-7ff00000h ,8020h ,0h ,108020h ,-7fefffe0h ,100000h ,-7fff7fe0h ,-7ff00000h ,-7fef8000h ,8000h ,-7ff00000h ,-7fff8000h ,20h ,-7fef7fe0h ,108020h ,20h ,8000h ,-80000000h ,8020h ,-7fef8000h ,100000h ,-7fffffe0h ,100020h ,-7fff7fe0h ,-7fffffe0h ,100020h ,108000h ,0h ,-7fff8000h ,8020h ,-80000000h ,-7fefffe0h ,-7fef7fe0h ,108000h
	spfunction3 dd 208h,8020200h,0h,8020008h,8000200h,0h,20208h,8000200h,20008h,8000008h,8000008h,20000h,8020208h,20008h,8020000h,208h,8000000h,8h,8020200h,200h,20200h,8020000h,8020008h,20208h,8000208h,20200h,20000h,8000208h,8h,8020208h,200h,8000000h,8020200h,8000000h,20008h,208h,20000h,8020200h,8000200h,0h,200h,20008h,8020208h,8000200h,8000008h,200h,0h,8020008h,8000208h,20000h,8000000h,8020208h,8h,20208h,20200h,8000008h,8020000h,8000208h,208h,8020000h,20208h,8h,8020008h,20200h
	spfunction4 dd 802001h,2081h,2081h,80h,802080h,800081h,800001h,2001h,0h,802000h,802000h,802081h,81h,0h,800080h,800001h,1h,2000h,800000h,802001h,80h,800000h,2001h,2080h,800081h,1h,2080h,800080h,2000h,802080h,802081h,81h,800080h,800001h,802000h,802081h,81h,0h,0h,802000h,2080h,800080h,800081h,1h,802001h,2081h,2081h,80h,802081h,81h,1h,2000h,800001h,2001h,802080h,800081h,2001h,2080h,800000h,802001h,80h,800000h,2000h,802080h
	spfunction5 dd 100h,2080100h,2080000h,42000100h,80000h,100h,40000000h,2080000h,40080100h,80000h,2000100h,40080100h,42000100h,42080000h,80100h,40000000h,2000000h,40080000h,40080000h,0h,40000100h,42080100h,42080100h,2000100h,42080000h,40000100h,0h,42000000h,2080100h,2000000h,42000000h,80100h,80000h,42000100h,100h,2000000h,40000000h,2080000h,42000100h,40080100h,2000100h,40000000h,42080000h,2080100h,40080100h,100h,2000000h,42080000h,42080100h,80100h,42000000h,42080100h,2080000h,0h,40080000h,42000000h,80100h,2000100h,40000100h,80000h,0h,40080000h,2080100h,40000100h
	spfunction6 dd 20000010h,20400000h,4000h,20404010h,20400000h,10h,20404010h,400000h,20004000h,404010h,400000h,20000010h,400010h,20004000h,20000000h,4010h,0h,400010h,20004010h,4000h,404000h,20004010h,10h,20400010h,20400010h,0h,404010h,20404000h,4010h,404000h,20404000h,20000000h,20004000h,10h,20400010h,404000h,20404010h,400000h,4010h,20000010h,400000h,20004000h,20000000h,4010h,20000010h,20404010h,404000h,20400000h,404010h,20404000h,0h,20400010h,10h,4000h,20400000h,404010h,4000h,400010h,20004010h,0h,20404000h,20000000h,400010h,20004010h
	spfunction7 dd 200000h,4200002h,4000802h,0h,800h,4000802h,200802h,4200800h,4200802h,200000h,0h,4000002h,2h,4000000h,4200002h,802h,4000800h,200802h,200002h,4000800h,4000002h,4200000h,4200800h,200002h,4200000h,800h,802h,4200802h,200800h,2h,4000000h,200800h,4000000h,200800h,200000h,4000802h,4000802h,4200002h,4200002h,2h,200002h,4000000h,4000800h,200000h,4200800h,802h,200802h,4200800h,802h,4000002h,4200802h,4200000h,200800h,0h,2h,4200802h,0h,200802h,4200000h,800h,4000002h,4000800h,800h,200002h
	spfunction8 dd 10001040h,1000h,40000h,10041040h,10000000h,10001040h,40h,10000000h,40040h,10040000h,10041040h,41000h,10041000h,41040h,1000h,40h,10040000h,10000040h,10001000h,1040h,41000h,40040h,10040040h,10041000h,1040h,0h,0h,10040040h,10000040h,10001000h,41040h,40000h,41040h,40000h,10041000h,1000h,40h,10040040h,1000h,41040h,10001000h,40h,10000040h,10040000h,10040040h,10000000h,40000h,10001040h,0h,10041040h,40040h,10000040h,10040000h,10001000h,10001040h,0h,10041040h,41000h,41000h,1040h,1040h,40040h,10000000h,10041000h

	; Other Variables
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
	inputFileMaxSize	equ 5000
	inputFileHandle 	dw ?
	inputFileContent 	db inputFileMaxSize dup (20h) ; Fill up the empty spaces with spaces
	inputFileContentDec db inputFileMaxSize dup (20h) ; Fill up the empty spaces with spaces
	inputFileSize		dw ?
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; *********************           Code Segment           ********************
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CODESEG
	
	; include all of our necessary files
	include '..\Codes\Library\Base.asm'
	Base_Load <'..\Codes\Library\Console.asm', '..\Codes\Library\String.asm', '..\Codes\Library\Debug.asm', '..\Codes\Library\File.asm', '..\Codes\Perm.asm', '..\Codes\Key.asm', '..\Codes\Encrypt.asm'>
start:
	mov ax, @data
	mov ds, ax

	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Instructions
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; Clear the screen and print the header
	Console_ClearScreen
	Console_PrintHeader

	; Now print the instructions
	@@INSTRUCTIONS:
	Console_PrintColoredString ' Instructions :', 0Ah
	Console_NewLine

	Console_NewLine
	Console_WriteLine ' 1) You''ll need to enter your string to the input.txt text file '
	Console_WriteLine '  *) If the file doesn''t exists yet, the system will create it'
    Console_WriteLine '  *) If you wish to decrypt your string, you''ll need to enter the hex'
	Console_WriteLine '     format of your string ( No additional characters are allowed )'

	Console_NewLine
	Console_WriteLine ' 2) In the second phase, select your operating mode, encryption or decryption.'
	Console_WriteLine '  *) The block cipher mode of the operation is ECB ( Electronic Code Book )'
	Console_WriteLine '  *) The encryption type is DES - Data encryption standard ( one rotation )'

	Console_NewLine
	Console_WriteLine ' 3) In the third phase the system will perform the operation.'
	Console_WriteLine '    When the operation is finished, the result will appear on the screen.'
	Console_WriteLine '  *) The result will appear on the screen only if its less than 100 characters.'
	Console_WriteLine '     Either way, the result will be stored in ''Output.txt'''

	Console_NewLine
	Console_WriteLine ' Now that you''re ready to use my program, please continue.'
	Console_NewLine

	Console_WriteLine ' In order to continue, press (c), in order to exit, press (e)'

	Console_NewLine

	Console_PrintColoredString ' (E) Exit                                                       ', 0Ah
	Console_PrintColoredString '   (C) Continue', 0Ah

	; Read letter from keyboard
	xor ax, ax
	int 16h
	and al, '_' ; To upper case 

	; The user actually read my terms, great!
	cmp al, 'C'
	je @@FIRST_FILE_CHECK

	cmp al, 'E'
	je exit

	Console_ClearScreen
	Console_PrintHeader
	Console_PrintColoredString ' Warning: Please read the instructions!', 4

	jmp @@INSTRUCTIONS

	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Check if input.txt exists!
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	@@FIRST_FILE_CHECK:
	File_CheckIfInputExists @@OPTIONS_WITH_CLEAR

	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Encryption/Decryption selection
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	@@OPTIONS_WITH_CLEAR:
	Console_ClearScreen
	Console_PrintHeader

	@@OPTIONS:

	Console_PrintColoredString ' Phase one: Operating mode', 0ch
	Console_NewLine
	Console_WriteLine ' This phase should be performed after you entered your text into ''Input.txt'''

	Console_NewLine

	@@OPTIONS_MENU:

	Console_WriteLine ' Please select your operating mode: '
	Console_WriteLine '  (1) Encryption'
	Console_WriteLine '  (2) Decryption'

	REPT 14
		Console_NewLine
	ENDM

	Console_PrintColoredString ' (E) Exit                                                       ', 0Ah
	Console_PrintColoredString ' (1|2) Continue', 0Ah
	
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Receive Encryption/Decryption selection input
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; Read letter from keyboard
	xor ax, ax
	int 16h

	cmp al, 'E'
	je exit
	cmp al, 'e'
	je exit

	mov [encryption], al        ; Move the input to encryption
	sub al, 1 					; Turn 2 -> 1, 1 -> 0
	xor al, 00110000b 			; Xor the ascii value with ascii '0'
	shr al, 1 					; Only 00000001b and 00000000b will turn on the zero-flag
	jz @@SKIP_OPTIONS_ERROR  	; OK, we can continue.

	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Receive Encryption/Decryption selection input
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


	; Well, I really need the user to choose between encryption and decryption.
	; I know it's a hard choice, but please!
	; So.. let's try again!
	
	Console_ClearScreen
	Console_PrintHeader
	Console_PrintColoredString ' Phase one: Operating mode', 0ch
	Console_NewLine
	Console_PrintColoredString ' Warning  : Invalid selection!           ', 0Eh
	Console_NewLine
	Console_NewLine

	; Loop over and over again until the user selects a valid mode
	jmp @@OPTIONS_MENU

	; Great! continue...
	@@SKIP_OPTIONS_ERROR:
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	Read Input.txt size!
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; Check if the user didnt delete the file 
	File_CheckIfInputExists @@FILE_STILL_EXISTS

	@@FILE_STILL_EXISTS:

	File_Open '..\Input.txt', 2, inputFileHandle
	File_Size inputFileHandle, bx					; Get size of the file and put it in bx

	; Move the size to the inputFileSize variable
	mov [inputFileSize], bx

	; Check to see if the file size is bigger than zero
	cmp [inputFileSize], 0
	JNE @@CHECK_MAXIMUM

	File_Close inputFileHandle

	Console_ClearScreen
	Console_PrintHeader
	Console_PrintColoredString ' Phase one: Operating mode', 0ch
	Console_NewLine
	Console_PrintColoredString ' Warning  : ''Input.txt'' is empty!', 0Eh
	Console_NewLine
	Console_NewLine

	; Loop over and over again until the user enters the text into input.txt
	jmp @@OPTIONS_MENU

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
		Console_PrintColoredString ' Phase one: Operating mode', 0ch
		Console_NewLine
		Console_PrintColoredString ' Warning  : The decryption method only accepts hex string!', 0Eh
		Console_NewLine
		Console_NewLine
		jmp @@OPTIONS_MENU

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
	Console_PrintColoredString ' Please enter your 64-bit key (8 characters) : ', 0Ah

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

			Console_Write '  - Result : '

			; Run the encryption
			Encrypt_Run 1
	
			jmp @@finish
		
		@@decryption:

			Console_Write '  - Result : '

			; Run the decryption
			Encrypt_Run 0		
			
			jmp @@finish
			
		@@finish:
		Console_NewLine
		Console_NewLine
		Console_NewLine
		Console_PrintColoredString '          # You can find your final result in the Output.txt file! #', 0Ah
		
exit:
	Console_NewLine

	Console_PrintColoredString ' ------------------------------------------------------------------------------', 0Ah
	Console_NewLine
	
	mov ax, 4c00h
	int 21h
END start
