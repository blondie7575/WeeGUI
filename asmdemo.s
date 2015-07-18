;
;  asmdemo.s
;  WeeGUI sample application
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2015 One Girl, One Laptop Productions. All rights reserved.
;


.include "WeeGUI_MLI.s"


.org $6000

INBUF			= $0200
DOSCMD			= $be03
KBD				= $c000
KBDSTRB			= $c010


main:

	; BRUN the GUI library
	ldx #0
	ldy #0
@0:	lda brunCmdLine,x
	beq @1
	sta INBUF,y
	inx
	iny
	bra @0
@1:	jsr DOSCMD


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Show off rendering speed with some snazzy rectangle painting
;
	; Stack:
	; Curr X
	; Curr Y
	; Curr Width
	; Curr Height

	ldx #WGClearScreen
	jsr WeeGUI

animateRects:
	lda	#38			; Initialize
	pha
	lda #11
	pha
	lda #2
	pha
	lda #2
	pha

animateRectsEvenLoop:
@0:	lda $C019		; Sync to VBL
	bmi @0

	ldx #WGClearScreen
	jsr WeeGUI

	tsx
	inx
	lda	$0100,x		; Load Height, then modify
	sta	PARAM3
	inc
	inc
	sta	$0100,x
	cmp	#25
	bcs	animateRects

	inx				; Load Width, then modify
	lda	$0100,x
	sta PARAM2
	inc
	inc
	inc
	inc
	inc
	inc
	sta	$0100,x

	inx				; Load Y, then modify
	lda	$0100,x
	sta	PARAM1
	dec
	sta	$0100,x

	inx				; Load X, then modify
	lda	$0100,x
	sta	PARAM0
	dec
	dec
	dec
	sta	$0100,x

	ldy	#64
	ldx	#WGFillRect
	jsr WeeGUI
	ldx #WGStrokeRect
	jsr WeeGUI

	jsr delayShort
	jsr delayShort
	jsr delayShort
	jsr checkKbd

	bra animateRectsEvenLoop


delayShort:		; ~1/30 sec
	pha
	phx
	phy

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

	ply
	plx
	pla
	rts

checkKbd:
	lda KBD
	bpl checkKbdDone
	sta KBDSTRB

	cmp #241		; 'q' with high bit set
	bne	checkKbdDone

	ldx #WGExit
	jsr WeeGUI
	pla		; Pull our own frame off the stack...
	pla
	pla
	pla
	pla		; ...four local variables + return address...
	pla
	rts		; ...so we can quit to ProDOS from here

checkKbdDone:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

brunCmdLine:
	.byte "BRUN weegui",$8d,0


; Suppress some linker warnings - Must be the last thing in the file
.SEGMENT "ZPSAVE"
.SEGMENT "EXEHDR"
.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "LOWCODE"
