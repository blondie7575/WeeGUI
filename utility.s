;
;  utility.s
;  General utilities for 6502
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; delay
; Sleeps for ~1 second
;
delay:
	SAVE_AXY

	ldy		#$ce	; Loop a bunch
delayOuter:
	ldx		#$ff
delayInner:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	dex
	bne		delayInner
	dey
	bne		delayOuter

	RESTORE_AXY
	rts


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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGStrLen
; Finds the length of a null-terminated string
; PARAM0: String pointer, LSB
; PARAM1: String pointer, MSB
; Return: A: String length, not including null
;
WGStrLen:
	phy

	ldy #$0
WGStrLen_loop:
	lda	(PARAM0),y
	beq	WGStrLen_done
	iny
	bra	WGStrLen_loop

WGStrLen_done:
	tya
	ply
	rts


