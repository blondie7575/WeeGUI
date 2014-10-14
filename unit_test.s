;
;  unit_test.s
;  WeeGui
;
;  Unit tests of various systems
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; tortureTestPrint
; Prints strings in a range of positions and scrolling offsets
;
	; Stack:
	; Curr Scroll X
	; Curr Scroll Y
	; Delta X
	; Delta Y
tortureTestPrint:
	ldx #WGClearScreen
	jsr WeeGUI

	lda	#0			; Initialize
	ldx #WGScrollX
	jsr WeeGUI

	ldx #WGScrollY
	jsr WeeGUI

tortureTestPrint_init:
	WGCALL16 WGCreateView,testPrintView

	lda #0
	ldx #WGSelectView
	jsr WeeGUI

	ldx #WGPaintView
	jsr WeeGUI

	lda #0
	pha
	pha
	lda #-1
	pha
	pha

	tsx
	inx

tortureTestPrint_loop:
	phx
	lda	#0			; Initialize
	sta PARAM0
	sta PARAM1
	ldx #WGSetCursor
	jsr WeeGUI
	plx

	inx				; Grab current delta X
	lda	$0100,x
	inx
	inx
	clc
	adc	$0100,x		; Add Scroll X
	sta	$0100,x
	beq tortureTestPrint_flipDeltaX		; Check for bounce
	cmp #-5
	beq tortureTestPrint_flipDeltaX
	bra tortureTestPrint_continueX

tortureTestPrint_flipDeltaX:
	dex
	dex
	lda $0100,x
	eor #$ff
	inc
	sta $0100,x
	inx
	inx

tortureTestPrint_continueX:
	phx
	lda	$0100,x
	ldx #WGScrollX	; Apply current X scroll
	jsr WeeGUI
	plx
	dex
	dex
	dex

	lda	$0100,x		; Grab current delta Y
	inx
	inx
	clc
	adc	$0100,x		; Add Scroll Y
	sta	$0100,x
	beq tortureTestPrint_flipDeltaY		; Check for bounce
	cmp #-5
	beq tortureTestPrint_flipDeltaY
	bra tortureTestPrint_continueY

tortureTestPrint_flipDeltaY:
	dex
	dex
	lda $0100,x
	eor #$ff
	inc
	sta $0100,x
	inx
	inx

tortureTestPrint_continueY:
	phx
	lda	$0100,x
	ldx #WGScrollY
	jsr WeeGUI
	plx
	dex
	dex

tortureTestPrint_print:
;	VBL_SYNC
	phx
	ldx #WGEraseViewContents
	jsr WeeGUI

	WGCALL16 WGPrint,unitTestStr

	ldx #WGPrint	; Do it again
	jsr WeeGUI

;	jmp tortureTestPrint_lock
	jsr delay

	plx
	jmp tortureTestPrint_loop

tortureTestPrint_reset:
	pla
	pla
	jmp tortureTestPrint_init

tortureTestPrint_lock:
	jmp tortureTestPrint_lock



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; tortureTestRects
; Strokes and paints rectangles of many different geometries
;
	; Stack:
	; Curr X
	; Curr Y
	; Curr Width
	; Curr Height
tortureTestRects:
	ldx #WGClearScreen
	jsr WeeGUI

tortureTestRectsEven:

	lda	#38			; Initialize
	pha
	lda #11
	pha
	lda #2
	pha
	lda #2
	pha

tortureTestRectsEvenLoop:
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
	bcs	tortureTestRectsEvenDone

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

	jmp tortureTestRectsEvenLoop

tortureTestRectsEvenDone:
	pla
	pla
	pla
	pla

tortureTestRectsOdd:

	lda	#37			; Initialize
	pha
	lda #11
	pha
	lda #2
	pha
	lda #2
	pha

tortureTestRectsOddLoop:
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
	bcs	tortureTestRectsOddDone

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

	jmp tortureTestRectsOddLoop

tortureTestRectsOddDone:
	pla
	pla
	pla
	pla

	jmp	tortureTestRectsEven



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




testPrintView:
	.byte 0,0,15,6,30,10,40,126

unitTestStr:
	.byte "This is a test of the emergency broadcast system. If this had been a real emergency, you would be dead now. Amusingly, it can be noted that if this had been a real emergency, and you were now a steaming pile of ash, there would of course be nobody.",0; to read this message. That begs any number",0; of extistential questions about this very text.",0
