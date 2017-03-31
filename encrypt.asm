	;	Computer Architecture, Project 4
	;	Code by Theodore (Tad) Miller
	;
	;	This program encrypts a message using 3 encryption algorithms.
	;	The first, caesar's cipher, shifts bits using a key
	;	The second, vigenere's algorithm (socially known as the vinaigrette),
	;	performs the XOR operation on a message using a key
	;	The third, and final, shifts the bits using a character

.ORIG x3000

JSR start

ALL	.FILL #-127
begin
	; Upper & lower bound for input
	AND R2, R2, #0
	LD R3, ALL

	JSR prompt
	JSR getIn
	JSR detOp


HALT

;********************************
; PRINT START MESSAGE
;********************************
START 	.STRINGZ "\Starting Privacy Module"
start
	LEA R0, START
	PUTS

	JSR begin

;********************************
; BEGIN PROMPT USER FOR INPUT
;********************************
PROMPT	.STRINGZ "\nENTER: E TO ENCRYPT, D TO DECRYPT, X TO EXIT: "
prompt
	STI R7, R7_TEMP
	LEA R0, PROMPT
	PUTS

	LDI R7, R7_TEMP
	JMP R7

;********************************
; PROMPT USER FOR INPUT. STORE IN R6
; CALL validIn TO DETERMINE IF INPUT
; IS VALID.
;********************************
getIn
	STI R7, R7_TEMP
	GETC

	JSR validIn

	AND R6, R6, #0
	ADD R6, R6, R0

	LDI R7, R7_TEMP
	JMP R7

;********************************
ASCII	.FILL		#-48
;********************************
; CALLS getIn AND CONVERTS ASCII
; TO DECIMAL
; USES R7 TO STORE #-48 TEMP
; ALSO USES ASCII TO STORE R7 SPOT
;********************************
decIn
	STI R7, ASCII

	JSR getIn
	LD R7, ASCII

	ADD R6, R6, R7

	LDI R7, ASCII
	JMP R7
;********************************
; DETERMINES IF VALUE IN R0 IS BTWN
; R2 AND R3.
; USE R1 FOR TEMP STOR
;********************************
R7_IN	.FILL x410C
validIn
	STI R7, R7_IN

	AND R1, R1, #0
	ADD R1, R0, R3
	BRzp validInBad

	AND R1, R1, #0
	ADD R1, R0, R2
	BRnz validInBad

	OUT

	LDI R7, R7_IN
	JMP R7
validInBad
	LDI R7, R7_TEMP
	BRnzp getIn
R7_TEMP	.FILL	x4100

;********************************
; DETERMINE OPERATION TO PERFORM
; CMP R6 (IN) TO R5 AND GO FROM THERE
;********************************
INVAL	.STRINGZ "\nINVALID ENTRY. PLEASE TRY AGAIN."
detOp
	; IF E
	JSR isEncrypt

	; IF D
	JSR isDecrypt

	; IF X
	JSR isExit

	; IF INVALID
	LEA R0, INVAL
	PUTS
	JSR begin

;********************************
; IF INPUT IS E - ENCRYPT
;********************************
E	.FILL #-69
isEncrypt
	LD R5, E
	ADD R5, R5, R6
	BRz encrypt

	JMP R7

;********************************
; IF INPUT IS D - DECRYPT
;********************************
D	.FILL #-68
isDecrypt
	LD R5, D
	ADD R5, R5, R6
	BRz decrypt

	JMP R7

;********************************
; IF INPUT IS X - EXIT
;********************************
X	.FILL #-88
isExit
	LD R5, X
	ADD R5, R5, R6
	BRz exit

	JMP R7

;********************************
; EXIT PROGRAM
;********************************
exit
	HALT


;********************************
ENCRYPTDONE	.STRINGZ	"\nENCRYPTION COMPLETE"
;********************************
; PERFORM ENCRYPTION OPERATION
; RUN ENCRYPTION ALGORITHMS ON EACH
; CHARACTER
;********************************
encrypt
	; FIRST GET KEY, MSG
	JSR getKey
	JSR getMsg

	; LOAD x4000 INTO R5
	LD R5, MESSAGE

encryptL
	; RUN EACH ENCRYPTION ON EACH
	; CHARACTER

	LDR R6, R5, #0
	STI R5, X

	JSR caesarE
	JSR vigenere
	JSR shift

	LDI R5, X
	STR R6, R5, #0

	ADD R5, R5, #1

	; CHECK THAT WE DON'T HIT EOL (ENTER KEY)
	LDR R7, R5, #0
	LD R0, nTEN
	
	ADD R0, R0, R7
	BRnp encryptL

	LEA R0, ENCRYPTDONE
	JSR cryptD
cryptD
	; EN/DECRYPTION COMPLETE - RETURN TO START OF PROGRAM
	PUTS
	JSR begin

;********************************
DECRYPTDONE	.STRINGZ	"\nDECRYPTION COMPLETE\n"
;********************************
; PERFORM DECRYPTION OPERATION
; RUN DECRYPTION ALGORITHMS ON EACH
; CHARACTER
;********************************
decrypt
	; FIRST GET KEY, MSG
	JSR getKey

	; LOAD x4000 INTO R5
	LD R5, MESSAGE

	LEA R0, DECRYPTDONE
	PUTS

decryptL
	; RUN EACH DECRYPTION ON EACH
	; CHARACTER

	LDR R6, R5, #0
	STI R5, X

	JSR unshift
	JSR vigenere
	JSR caesarD

	LDI R5, X
	STR R6, R5, #0

	LDR R0, R5, #0
	PUTC

	ADD R5, R5, #1

	; CHECK THAT WE DON'T HIT EOL (ENTER KEY)
	LDR R7, R5, #0
	LD R0, nTEN
	
	ADD R0, R0, R7
	BRnp decryptL

	JSR begin
;********************************
ENCRYPTK	.FILL	#128
R7_CAE		.FILL	x4112
;********************************
; RUN CAESAR'S CIPHER (ENCRYPT) ON VALUE IN R6
; USE R5 AS COUNTER. R6 FOR RESULT
;********************************
caesarE
	STI R7, R7_CAE
	LD R3, ENCRYPTK
	; LOAD OUR KEY K INTO R0
	LDI R0, NUM2
	
	; ADD R6, R0, SO WE HAVE (K + MESSAGE) MOD 127
	ADD R6, R6, R0
	JSR mod

	LDI R7, R7_CAE
	JMP R7

caesarD
	STI R7, R7_CAE
	LD R3, ENCRYPTK

	; LOAD OUR KEY K INTO R0
	LDI R0, NUM2
	NOT R0, R0
	ADD R0, R0, #1

	ADD R6, R6, R0
	ADD R6, R6, R3

	LDI R7, R7_CAE
	JMP R7

;********************************
R7_VIG		.FILL	x4113
;********************************
; RUN VIGENERE'S CIPHER ON VALUE
; STORED IN R6 WITH KEY IN R0
; RESULT GOES BACK INTO R2
; E.G. (R6 XOR R0) = C (R6)
;********************************
vigenere
	STI R7, R7_VIG

	LDI R0, CHR1
	JSR xor

	LDI R7, R7_VIG
	JMP R7

;********************************
; RUN BIT SHIFT ON R6 BASED ON
; VALUE STORED IN NUM1. USES
; MULT AND R0
;********************************
unshift
	STI R7, R7_SHFT

	; For nPower; 2^NUM1
	AND R0, R0, #0
	ADD R0, R0, #2
	LDI R1, NUM1

	; Calculate 2^NUM1
	JSR nPower

	ADD R3, R0, #0

	; Use R5 for quotient
	AND R5, R5, #0

unshiftL
	ADD R5, R5, #1
	ADD R6, R6, R3
	BRnp unshiftL
	
	; Put R5 back into R6
	NOT R5, R5
	ADD R6, R5, #1

	LDI R7, R7_SHFT
	JMP R7


;********************************
R7_SHFT		.FILL	x4114
;********************************
; RUN BIT SHIFT ON R6 BASED ON
; VALUE STORED IN NUM1. USES
; MULT AND R0
;********************************
shift
	STI R7, R7_SHFT

	; For nPower; 2^NUM1
	AND R0, R0, #0
	ADD R0, R0, #2
	LDI R1, NUM1

	; Calculate 2^NUM1
	JSR nPower
	STI R0, ENCRYPTK

	; Swap R1 with R6
	ADD R5, R0, #0
	ADD R0, R6, #0
	ADD R6, R5, #0

	JSR mult

	; for weird mult error
	LDI R0, ENCRYPTK
	NOT R0, R0
	ADD R0, R0, #1

	; Put back into R6
	ADD R6, R5, R0

	LDI R7, R7_SHFT
	JMP R7

;********************************
R7_PWR		.FILL	x4115
;********************************
; TAKE VALUE IN R0. RAISE TO POWER
; OF R1. STORE IN R0. ONLY WORKS WITH 2
;********************************
nPower
	STI R7, R7_PWR
	ADD R1, R1, #-1
	BRn nPowerZ
	BRz nPowerD
	
nPowerL	ADD R0, R0, R0
	ADD R1, R1, #-1

	BRp nPowerL

	JSR nPowerD

nPowerZ	AND R0, R0, #0
	ADD R0, R0, #1

nPowerD	LDI R7, R7_PWR
	JMP R7

;********************************
; RUN XOR ON R0 AND R6.
; STORE RESULT IN R6
; USE R1 AS TMP REGISTER
;********************************
xor
	AND R1, R0, R6
	NOT R1, R1

	NOT R0, R0
	NOT R6, R6
	AND R0, R0, R6
	NOT R0, R0
	AND R6, R6, R1

	JMP R7

;********************************
R7_MOD		.FILL	x4110
;********************************
; PERFORM A MOD B = X
; WHERE A IS R6, B IS R3, AND X IS R6
;********************************
mod	
	AND R4, R4, #0
	ADD R4, R4, #-2
	STI R7, R7_MOD

	;	Take 2C of our B number. We will subtract A from it.
	NOT R0, R3
	ADD R0, R0, #1

modL	ADD R4, R4, #1
	ADD R6, R6, R0
	BRzp modL

	ADD R6, R6, R3


	LDI R7, R7_MOD
	JMP R7

;********************************
MESSAGE	.FILL		x4000
	.FILL		x4001
	.FILL		x4002
	.FILL		x4003
	.FILL		x4004
	.FILL		x4005
	.FILL		x4006
	.FILL		x4007
	.FILL		x4008
	.FILL		x4009
EOL	.FILL		x400A ; END OF LINE
nTEN	.FILL		#-10
R7_MSG	.FILL		x4111
MSGIN	.STRINGZ	"\nENTER MESSAGE: "
LWRBND	.FILL		#-9
UPRBND	.FILL		#-127
;********************************
; GET ENCRYPTION MESSAGE
; USE R5 TO COUNT THE SPOT WE ARE IN
; USE R0 TO MAKE SURE WE'RE NOT HITTING ENTER && R5 < 10
;********************************
getMsg
	; Store R7
	STI R7, R7_MSG

	; Output enter
	LEA R0, MSGIN
	PUTS

	; Put ENTER key in x400A for reading later on
	LD R5, EOL
	AND R0, R0, #0
	ADD R0, R0, #10
	STR R0, R5, #0

	LD R5, MESSAGE

	LD R2, LWRBND
	LD R3, UPRBND

getMsgL
	JSR getIn
	STR R6, R5, #0
	ADD R5, R5, #1

	; IF WE INPUT ENTER
	LD R0, nTEN
	ADD R0, R0, R6

	BRz getMsgD

	; IF WE GET > 10 CHARS
	LD R0, EOL
	NOT R0, R0
	ADD R0, R0, #1
	ADD R0, R0, R5

	BRn getMsgL

	; DONE - TIME TO RETURN
getMsgD	
	AND R5, R5, #0
	AND R6, R6, #0

	LDI R7, R7_MSG
	JMP R7

;********************************
KEYIN	.STRINGZ	"\nENTER ENCRYPTION KEY: "
NUM1	.FILL		x400B
CHR1	.FILL		x400C
NUM2	.FILL		x400D
NUM1LWR	.FILL		#-47
NUM1UPR	.FILL		#-56
CHR1LWR	.FILL		#-57
CHR1UPR	.FILL		#-127
R7_KEY	.FILL		x410D
R7_KEY2	.FILL		x410E
R7_MUL	.FILL		x410F
HUND	.FILL		#100
TEN	.FILL		#10
;********************************
; GET KEY
; FORM IS NUM-CHAR-NUM-NUM-NUM
; NUM >= 0 <= 7
; CHAR >= a <= Z
;
; USE R2, R3 FOR BOUNDS
; R6 FOR INPUT
; R5 ALSO FOR NUM2. (1 - 127)
;********************************
getKey
	STI R7, R7_KEY

	LEA R0, KEYIN
	PUTS

	JSR getKeyN1
	JSR getKeyC1
	JSR getKeyN2

	LDI R7, R7_KEY
	JMP R7

getKeyN1
	STI R7, R7_KEY2

	; Load bounds
	LD R2, NUM1LWR
	LD R3, NUM1UPR

	; Get input
	JSR decIn

	; Store in NUM1 slot
	STI R6, NUM1

	LDI R7, R7_KEY2
	JMP R7

getKeyC1
	STI R7, R7_KEY2

	; Load bounds
	LD R2, CHR1LWR
	LD R3, CHR1UPR

	; Get input
	JSR getIn

	; Store in NUM1 slot
	STI R6, CHR1

	LDI R7, R7_KEY2
	JMP R7

; BOUNDS
; FIRST NUM: 0 - 7
; SECND NUM: 0 - 2
; THIRD NUM: 0 - 1
getKeyN2
	STI R7, R7_KEY2

	; RANGE 0 - 1
	LD R2, NUM1LWR
	LD R3, NUM1LWR
	ADD R3, R3, #-3
	JSR decIn

	LD R0, HUND
	JSR mult

	; RANGE 0 - 2
	ADD R3, R3, #-1
	JSR decIn

	LD R0, TEN
	JSR mult

	; RANGE 0 - 7
	ADD R3, R3, #-5
	JSR decIn
	ADD R5, R5, R6

	STI R5, NUM2

	AND R5, R5, #0

	LDI R7, R7_KEY2
	JMP R7

mult	; Calculate R0 * R6. Store in R5
	STI R7, R7_MUL
	ADD R6, R6, #0
	BRz multD
multL
	ADD R5, R5, R0
	ADD R6, R6, #-1
	BRp mult

multD	LDI R7, R7_MUL
	JMP R7

.END