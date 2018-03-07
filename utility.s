;
;  utility.s
;  General utilities for 6502
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; delayShort
; Sleeps for ~1/30th second
;
delayShort:
	SAVE_AXY

	ldy		#$06	; Loop a bit
delayShortOuter:
	ldx		#$ff
delayShortInner:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	dex
	bne		delayShortInner
	dey
	bne		delayShortOuter

	RESTORE_AXY
	rts

.if 0
;;;;;;;;;;;;;;;;;;;;;;;
; scanHexDigit
; Scans a 4 bit hex value from an ASCII character
; A: ASCII character
; Out A: Hex value
;
scanHexDigit:
	cmp		#'a'
	bcs		scanHexDigitLowCase
	cmp		#'A'
	bcs		scanHexDigitLetter
	sec
	sbc		#'0'
	jmp		scanHexDigitDone

scanHexDigitLowCase:
	sec
	sbc		#32

scanHexDigitLetter:
	sec
	sbc		#55

scanHexDigitDone:
	rts


;;;;;;;;;;;;;;;;;;;;;;;
; scanHex8
; Scans an 8 bit hex value from a string
; PARAM0: Pointer to string (LSB)
; PARAM1: Pointer to string (MSB)
; Y: Offset into string
; Out A: 8-bit hex value
;     Y: One past what we scanned
; Side effects: Clobbers S0
;
scanHex8:
	lda		(PARAM0),y
	jsr		scanHexDigit
	asl
	asl
	asl
	asl
	sta		SCRATCH0		; Stash first digit for later

	iny
	lda		(PARAM0),y
	jsr		scanHexDigit
	ora		SCRATCH0
	iny						; Be nice and advance Y to end
	rts
.endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGStrLen
; Finds the length of a null-terminated string
; PARAM0: String pointer, LSB
; PARAM1: String pointer, MSB
; Return: A: String length, not including null
;
WGStrLen:
	phy

	ldy #0
WGStrLen_loop:
	lda (PARAM0),y
	beq WGStrLen_done
	iny
	bra WGStrLen_loop

WGStrLen_done:
	tya
	ply
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAllocStr
; Finds room in our block string allocator
; Return: PARAM0: Stored string, LSB
;         PARAM1: Stored string, MSB
;         Null if pool is full
;         X: Pool index of free space
; Side Effects: Clobbers AX
;
WGAllocStr:
	ldx #0

WGAllocStr_findEmptyLoop:
	lda WG_STRINGS,x
	beq WGAllocStr_done
	txa
	clc
	adc #16	; String blocks are 16 bytes wide
	bcs WGAllocStr_noRoom
	tax
	bra WGAllocStr_findEmptyLoop

WGAllocStr_noRoom:
	lda #0
	sta PARAM0
	sta PARAM1

WGAllocStr_done:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGStoreStr
; Finds room in our block allocator and copies the given string.
; A: Terminator character
; PARAM0: String pointer, LSB
; PARAM1: String pointer, MSB
; Return: PARAM0: Stored string, LSB
;         PARAM1: Stored string, MSB
; Side Effects: Clobbers SA
;
WGStoreStr:
	sta WG_SCRATCHA
	SAVE_AXY

	jsr WGAllocStr
	lda PARAM1
	beq WGStoreStr_done
	ldy #0

	phx			; Remember the start of our string

WGStoreStr_copyLoop:
	lda (PARAM0),y
	cmp WG_SCRATCHA
	beq WGStoreStr_terminate
	sta WG_STRINGS,x
	inx
	iny
	cpy #15				; Clip string to maximum block size
	bne WGStoreStr_copyLoop

WGStoreStr_terminate:
	lda #0				; Terminate the stored string
	sta WG_STRINGS,x

	pla					; Return pointer to the start of the block
	clc
	adc #<WG_STRINGS
	sta PARAM0
	lda #0
	adc #>WG_STRINGS
	sta PARAM1

WGStoreStr_done:
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGStorePascalStr
; Finds room in our block allocator and copies the given string.
; X: Length
; PARAM0: String pointer, LSB
; PARAM1: String pointer, MSB
; Return: PARAM0: Stored string, LSB
;         PARAM1: Stored string, MSB
; Side Effects: Clobbers SA
;
WGStorePascalStr:
	stx WG_SCRATCHA
	SAVE_AXY

	jsr WGAllocStr
	lda PARAM1
	beq WGStorePascalStr_done
	ldy #0

	phx			; Remember the start of our string

WGStorePascalStr_copyLoop:
	cpy WG_SCRATCHA
	beq WGStorePascalStr_terminate
	lda (PARAM0),y
	sta WG_STRINGS,x
	inx
	iny
	cpy #15				; Clip string to maximum block size
	bne WGStorePascalStr_copyLoop

WGStorePascalStr_terminate:
	lda #0				; Terminate the stored string
	sta WG_STRINGS,x

	pla					; Return pointer to the start of the block
	clc
	adc #<WG_STRINGS
	sta PARAM0
	lda #0
	adc #>WG_STRINGS
	sta PARAM1

WGStorePascalStr_done:
	RESTORE_AXY
	rts
