;
; Zdrojovy kod obsluzneho monitoru pocitace PMI-80
;*************************************************
; (c) Roman Kiss, TESLA etc.
;*************************************************
;
;	Disassembled by:
;       (c)   www.nostalcomp.cz   2014           
;		DASMx object code disassembler
;		(c) Copyright 1996-1999   Conquest Consultants
;		Version 1.30 (Oct  6 1999)
;
;	File:	pmi80.rom,  	Size:	1024 bytes,  	Checksum:	82C9, 	CRC-32:	B93F4407
;
;	Date:		Tue Apr 06 20:17:03 2010, revised 7.1. 2014!
;
;	CPU:		Intel 8080 (MCS-80/85 family)
;
; RST 7 = FFh (unused memory cell)


; Ports and important memory locations
PORT_A         .equ         0F8h
PORT_B         .equ         0F9h
PORT_C         .equ         0FAh
PORT_CW        .equ         0FBh
STACK          .equ       01FD9h  
VIDEORAM       .equ       01FEFh 
IN_ADR         .equ       01FF8h
IN_DATA        .equ       01FFAh
VIDEO_POINTER  .equ       01FFCh
INT_VECTOR     .equ       01FE6h 


	.org	00000h

START:            ; 0000h - RESET 
	mvi	a,08AH      ; Set primary 8255A. 
	out	0FBH        ; CW 8Ah => mode 0, PA out, PB in, PC0-3 out, PC4-7 in 
	nop             ; It's posible to insert DI (0004h = F3h) here
	jmp	L002E
;
;-------------------------------------------------------------------------------
ENTRY:              ; 0008h - ENTRY (BREAK STOP)
	shld	$1FDF
	pop	h
	shld	$1FE2
	lxi	h,0000h
	dad	sp
	shld	$1FE4
	lxi	h,$1FDD
	sphl
	push	b
	push	d
	push	psw
	pop	h
	shld	$1FDD
	lhld	$1FEC
	lda	$1FEE
	mov	m,a
	lxi	h,TEXT_BR_STOP
	jmp	L0040

L002E:
	lxi	h,STACK
	shld	$1FE4
	jmp	L003D
	rst	7
;	
;-------------------------------------------------------------------------------
INTERRUPT:
	jmp	INT_VECTOR   ; 0038h - interrupt type RST7

; 2 spare bytes
	rst	7
	rst	7
;
;-------------------------------------------------------------------------------
L003D:                 ;ENTRY cont.
	lxi	h,TEXT_PMI_80

L0040:
	lxi	sp,STACK

L0043:
	shld	VIDEO_POINTER
	call	OUTKE
	lxi	h,VIDEORAM
	shld	VIDEO_POINTER

L004F:
	mvi	a,01DH
	call	CLEAR
	call	OUTKE
	lxi	h,TABPRIKAZY
	mvi	b,006H

L005C:
	cmp	m
	inx	h
	jz	L006D
	inx	h
	inx	h
	dcr	b
	jnz	L005C

L0067:
	lxi	h,TEXT_ERROR
	jmp	L0040

L006D:
	mov	c,m
	inx	h
	mov	h,m
	mov	l,c
	pchl			
; PCHL - jump to HL
; - HL contains the routine address
;
; End of main program loop
; Continued with commands and routines
;
;-------------------------------------------------------------------------------
PRIKAZ_MEM:                 ;command MEM
	mvi	a,016H
	call	CLEAR
	call	MODAD
L007A:
	mov	a,m
	sta	IN_DATA
	mvi	a,018H
	stax	b
	call	MODDA
	lhld	IN_ADR
	lda	IN_DATA
	mov	m,a
	inx	h
	shld	IN_ADR
	call	OUTAD
	jmp	L007A
;	
;-------------------------------------------------------------------------------
TEXT_MG_RUN:
	.db	01EH,	016H,	020H,	019H,	019H,	012H,	015H,	01BH,	01EH
	
TEXT_MG_STOP:
	.db	01EH,	016H,	020H,	019H,	005H,	010H,	011H,	013H,	01EH

	rst	7
	rst	7
	rst	7
	rst	7
;
;-------------------------------------------------------------------------------
; Clears display buffer and store value from accumulator 
; to the first position of display.
CLEAR:                    ;CLEAR
	lxi	d,ENTRY
L00AE:
	lhld	VIDEO_POINTER
	dad	d
	mvi	m,019H
	dcr	e
	jnz	L00AE
	dcx	h
	mov	m,a
	ret
;
;-------------------------------------------------------------------------------
; Shows two bytes from "address register" ($1FF8-9) on display in "address space"
OUTAD:                    ;OUTAD
	lxi	b,01FF1H
	lhld	IN_ADR
	mov	a,h
	call	L00C6
L00C5:
	mov	a,l
L00C6:
	push	d
	mov	d,a
	rrc
	rrc
	rrc
	rrc
	ani	00FH
	stax	b
	inx	b
	mov	a,d
	ani	00FH
	stax	b
	inx	b
	pop	d
	ret
;
;-------------------------------------------------------------------------------
; Let user modify value in address register (two bytes)
; Modifying is ended by pressing the "=" key
; When pressed any other key than hexadecimal, =, RE or I (RESET or Interrupt)
; an error message is shown.
MODAD:                    ;MODAD
	call	OUTAD
	call	OUTKE
	rz
	jnc	L0197
	lhld	IN_ADR
	ani	00FH
	dad	h
	dad	h
	dad	h
	dad	h
	add	l
	mov	l,a
	shld	IN_ADR
	jmp	MODAD
;
;-------------------------------------------------------------------------------
; Shows one byte from "data register" ($1FFA) as two hexa characters
; in data display section
OUTDA:                    ;OUTDA
	lxi	b,$1FF6
	lhld	IN_DATA
	jmp	L00C5
;
;-------------------------------------------------------------------------------
; Let user modify value in data register... 
; Modifying is ended by pressing the "=" key
; When pressed any other key than hexadecimal, =, RE or I (RESET or Interrupt)
; an error message is shown.
MODDA:                    ;MODDA
	call	OUTDA
	call	OUTKE
	rz
	jnc	L019D
	nop
	nop
	nop
	ani	00FH
	dad	h
	dad	h
	dad	h
	dad	h
	add	l
	mov	l,a
	shld	IN_DATA
	jmp	MODDA
;
;-------------------------------------------------------------------------------
; Main interface subroutine. Refresh display, check keys and return key code, when pressed
OUTKE:                    ;OUTKE
	call	DISP
	jnc	OUTKE  ;Any key pressed?
	rrc        ;restore key value
	mov	c,a    ;save key code

L011E:
	call	DISP ;
	jc	L011E  ;Are keys up? If not, call DISP
	call	DISP ; (Not obvious why...)
	mov	a,c    ;restore key code
	cpi	090H   ; set flags
	ret        ;
;
; ****************************************************************************
; probably unused code - not addressed, not called, not referenced...
	.db	008H
	dad	b
	dcr	c
	dcx	b
	ldax	b
	inx	d
	inr	d
	mvi	c,00CH
	rrc
	dcr	b
	ldax	d
	dcr	c
	dcx	b
	ldax	b
	;cpo	LD9DF
	cpo  $D9DF
	in	0DDH
	rst	7
; End of unused code
; *****************************************************************************
;
;-------------------------------------------------------------------------------
DISP:                 ;DISP  
;main display routine
	push	h  
	push	b
	push	d
	lxi	d,0000h ;nul D,E
	mov	b,d     ;nul B 
	mov	a,d     ;nul A 
	sta	$1FFE   ;inic STATUS
LOOP1:
	mvi	a,07FH  
	out	0F8H    
	nop
	mov	a,e     ;index of char position
	cma
	out	0FAH
	nop
	lhld	VIDEO_POINTER  ;addr of "video buffer"
	dad	d       ;add position
	mov	c,m     ;data to C
	lxi	h,TPREV ;conversion table
	dad	b
	mov	a,m     ;converted data
	out	0F8H    ;to the port segment
	nop
	lda	$1FFE   ;lda STATUS
	ora	a
	jnz	NOKEY    ;KEY?
	mvi	c,009H   ;Yes
	lxi	h,0019AH ;lxi h, TABKEY-9 - key conversion table
	in	0FAH     ;from key port 
	nop
	ani	070H     ;mask
	rlc
	rlc
	jnc	PRVA     ;YES, first line
	rlc          ;NO
	jnc	DRUHA    ;YES, second line
	rlc          ;NO
	jc	NOKEY    ;C!=1, no line
	dad	b        ;add one line
DRUHA:
	dad	b        ;add one line
PRVA:
	dad	b        ;add one line
	dad	d        ;add KEY
	mov	a,m      ;get key code
	sta	$1FFE    ;save to STATUS
NOKEY:
	inr	e        ;next digit
	mvi	a,00AH
	cmp	e
	jnz	LOOP1    ;the last one?
	lda	$1FFE    ;lda STATUS   YES
	rlc          ;set carry
	pop	d
	pop	b
	pop	h
	ret
;
L0197:
	lxi	h,TEXT_ERR_ADRES
	jmp	L0040
;
L019D:
	lxi	h,TEXT_ERR_DATA
	jmp	L0040
;	
;-------------------------------------------------------------------------------	
; Key codes
; 80h-8Fh = keys 0-F, 9xh = control keys, FFh = unused
 
TABKEY:
	.db	080H, 084H,	088H, 091H,	08DH,	08CH,	089H,	085H,	081H ;third line
	.db	082H,	086H,	08AH,	09AH,	08FH,	08EH,	08BH,	087H,	083H ;second line
	.db	0FFH,	094H,	093H,	0FFH,	097H,	092H,	0FFH,	0FFH,	090H ;first line

; display conversion table
; Caution! All segments are inverted
TPREV:  
	.db	040H    ;char 0
	.db	079H    ;char 1 etc: 
	.db	024H, 030H,	019H,	012H,	002H,	078H,	000H,	018H,	008H,	003H,	046H,	021H
	.db	006H,	00EH,	007H,	023H,	02FH,	00CH,	047H,	063H,	048H,	071H,	037H,	07FH
	.db	009H,	02BH,	00BH,	02CH,	05DH,	03FH,	042H,	061H
	.db	07BH  ;char 22 (comma), the last one
	.db	011H  ;(not mentioned in manual)

	rst	7     ; free space
	rst	7
	rst	7
	rst	7
	rst	7
	
; .org 001E7h

TEXT_PMI_80: ;"PMI-80"
	.db	01EH, 013H, 016H,	001H, 019H,	01FH,	008H,	000H,	01EH
 	
TEXT_ERR_ADRES:
	.db	00EH, 012H,	012H,	018H,	00AH,	00DH,	012H,	00EH,	005H

TEXT_ERR_DATA:
	.db	00EH,	012H,	012H, 018H,	019H,	00DH,	00AH,	010H,	00AH

TEXT_ERROR:
	.db	01EH,	019H,	00EH,	012H,	012H,	011H,	012H,	019H,	01EH

TABPRIKAZY:     ;key code + routine address (low, high)
	.db	092H,	072H,	000H     ; MEM 
  	.db	091H,	029H,	002H     ; EX
  	.db 097H, 	05AH,	002H     ; BR
	.db	09AH,	07EH,	002H     ; R
	.db	094H,	04CH,	003H     ; SAVE
	.db	093H,	08CH,	003H     ; LOAD
	rst	7     ; free space
	rst	7
	rst	7

TEXT_BR_STOP:
	.db	01EH,	00BH,	012H,	01FH,	005H,	010H,	011H,	013H,	01EH
;
;-------------------------------------------------------------------------------
PRIKAZ_EX:        ; command EX
	mvi	a,020H
	call	CLEAR
	lhld	$1FE2
	shld	IN_ADR
	call	MODAD
	lhld	IN_ADR
	shld	$1FE2
	mvi	a,006H
	out	0F8H
	nop
	mvi	a,00FH
	out	0FAH
	nop
	lxi	h,STACK
	sphl
	pop	d
	pop	b
	pop	psw
	lhld	$1FE4
	sphl
	lhld	$1FE2
	push	h
	lhld	$1FDF
	ret
;
;-------------------------------------------------------------------------------
PRIKAZ_BR:        ; command BR
	mvi	a,00BH
	call	CLEAR
	lhld	$1FEC
	shld	IN_ADR
	call	MODAD
	lhld	IN_ADR
	shld	$1FEC
	mov	a,m
	sta	$1FEE
	mvi	m,0CFH
	lhld	$1FE2
	dcx	h
	shld	$1FE2
	jmp	PRIKAZ_EX
;
;-------------------------------------------------------------------------------
PRIKAZ_R:         ; command R
	mvi	a,012H
	call	CLEAR
	call	OUTKE
	jnc	L0067
	ani	00FH
	lxi	b,00006H
L028E:
	lxi	h,0012AH
	dcx	b
	dad	b
	inr	c
	dcr	c
	jz	L004F
	cmp	m
	jnz	L028E
L029C:
	lxi	h,0012FH
	call	L02CD
	mov	e,l
	lxi	h,00134H
	call	L02CD
	mov	h,e
	shld	$1FF6
	push	b
	call	L02CA
	push	h
	mov	c,m
	inx	h
	mov	h,m
	mov	l,c
	shld	IN_ADR
	call	MODAD
	pop	d
	mov	a,l
	stax	d
	inx	d
	mov	a,h
	stax	d
	pop	b
	dcr	c
	jnz	L029C
	jmp	L004F
;
L02CA:
	lxi	h,00139H
L02CD:
	mvi	b,000H
	dad	b
	mov	l,m
	mvi	h,01FH
	ret
;
;-------------------------------------------------------------------------------
TOUT:                   ;TOUT     02D4h
	mvi	b,009H
L02D6:
	mvi	a,0C7H
	call	L02EE
	mov	a,c
	rar
	mov	c,a
	mvi	a,08FH
	rar
	call	L02EE
	mvi	a,047H
	call	L02EE
	dcr	b
	jnz	L02D6
	ret
;
L02EE:
	mvi	d,020H
L02F0:
	out	0F8H
	mvi	e,004H
L02F4:
	dcr	e
	jnz	L02F4
	xri	040H
	dcr	d
	jnz	L02F0
	ret
;
	rst	7
;	
;-------------------------------------------------------------------------------
TIN:                    ;TIN    0300h
	mvi	b,008H
	mvi	d,000H
L0304:
	call	L0342
	jc	L0304
	call	L0342
	jc	L0304
L0310:
	call	L0342
	jnc	L0310
	call	L0342
	jnc	L0310
L031C:
	dcr	d
	call	L0342
	jc	L031C
	call	L0342
	jc	L031C
L0329:
	inr	d
	call	L0342
	jnc	L0329
	call	L0342
	jnc	L0329
	mov	a,d
	ral
	mov	a,c
	rar
	mov	c,a
	mvi	d,000H
	dcr	b
	jnz	L031C
	ret
;
L0342:
	mvi	e,002H
L0344:
	dcr	e
	jnz	L0344
	in	0FAH
	ral
	ret
;
;-------------------------------------------------------------------------------
PRIKAZ_SAVE:            ; command SAVE   034Ch
	mvi	a,005H
	call	CLEAR
	call	MODAD
	call	MODDA
	lxi	h,TEXT_MG_RUN
	shld	VIDEO_POINTER
	call	OUTKE
	mvi	a,023H
	out	0F8H
	mvi	a,00FH
	out	0FAH
	mvi	d,0F0H
	mvi	a,0C7H
	call	L02F0
	lda	IN_DATA
	mov	c,a
	call	TOUT
	mvi	a,010H
	call	CLEAR
	lhld	IN_ADR
L037E:
	mov	c,m
	call	TOUT
	inr	l
	jnz	L037E
L0386:
	lxi	h,TEXT_MG_STOP
	jmp	L0043
;
;-------------------------------------------------------------------------------
PRIKAZ_LOAD:            ; command LOAD  038Ch
	mvi	a,014H
	call	CLEAR
	call	MODAD
	call	MODDA
	lxi	h,TEXT_MG_RUN
L039A:
	shld	VIDEO_POINTER
	call	OUTKE
L03A0:
	lhld	IN_ADR
	mvi	a,007H
	out	0F8H
	mvi	a,00FH
	out	0FAH
L03AB:
	mvi	d,0A0H
L03AD:
	call	L0342
	jc	L03AB
	dcr	d
	jnz	L03AD
	call	TIN
	lda	IN_DATA
	cmp	c
	jnz	L03CC
L03C1:
	call	TIN
	mov	m,c
	inr	l
	jnz	L03C1
	jmp	L0386
;
L03CC:
	jc	L03E7
	mvi	a,00FH
	call	CLEAR
	mov	a,c
	lxi	b,$1FF6
	call	L00C6
	lxi	h,VIDEORAM
	shld	VIDEO_POINTER
	call	OUTKE
	jmp	L03A0
;
L03E7:
	lxi	h,TEXT_MG_SPAT
	jmp	L039A

TEXT_MG_SPAT:
	.db	 01EH,	016H,	020H,	019H,	005H,	013H,	00AH,	010H,	01EH

	rst	7      ; free space
	rst	7
	rst	7
	rst	7
	rst	7
	rst	7
	rst	7
	rst	7
	rst	7
	rst	7      ;03FFh end of monitor
	
;***************************** www.nostalcomp.cz *****************************

  .END                 