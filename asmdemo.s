;
;  guidemo.s
;  WeeGUI sample application
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


.include "WeeGUI_MLI.s"


.org $6000

INBUF			= $0200
DOSCMD			= $be03
KBD				= $c000
KBDSTRB			= $c010


.macro WGCALL16 func,addr
	lda #<addr
	sta PARAM0
	lda #>addr
	sta PARAM1
	ldx #func
	jsr WeeGUI
.endmacro


; Sample code
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Show off some WeeGUI features

	jmp	animateRects

	ldx #WGClearScreen
	jsr WeeGUI

keyLoop:
	ldx #WGPendingViewAction
	jsr WeeGUI

	lda KBD
	bpl keyLoop
	sta KBDSTRB

	and #%01111111
	cmp #113
	beq	keyLoop_quit

	jmp keyLoop

keyLoop_quit:
	ldx #WGExit
	jsr WeeGUI
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; animateRects
; Strokes and paints rectangles of many different geometries
;
	; Stack:
	; Curr X
	; Curr Y
	; Curr Width
	; Curr Height
animateRects:
	ldx #WGClearScreen
	jsr WeeGUI

animateRectsEven:

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
	bcs	animateRectsEvenDone

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

	ldy	#'Q'+$80
	ldx	#WGFillRect
	jsr WeeGUI
	ldx #WGStrokeRect
	jsr WeeGUI

	jsr delayShort
	jsr delayShort
	jsr delayShort

	jmp animateRectsEvenLoop

animateRectsEvenDone:
	pla
	pla
	pla
	pla

animateRectsOdd:

	lda	#37			; Initialize
	pha
	lda #11
	pha
	lda #2
	pha
	lda #2
	pha

animateRectsOddLoop:
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
	bcs	animateRectsOddDone

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

	ldy	#'Q'+$80
	ldx	#WGFillRect
	jsr WeeGUI
	ldx #WGStrokeRect
	jsr WeeGUI

	jsr delayShort
	jsr delayShort
	jsr delayShort

	jmp animateRectsOddLoop

animateRectsOddDone:
	pla
	pla
	pla
	pla

	jmp	animateRectsEven

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

delay:			; ~1 sec
	pha
	phx
	phy

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

	ply
	plx
	pla
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
