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
	jsr WGClearScreen

	lda	#0			; Initialize
	jsr WGScrollX
	jsr WGScrollY

tortureTestPrint_init:
	lda	#<testPrintView
	sta	PARAM0
	lda	#>testPrintView
	sta	PARAM1
	jsr	WGCreateView

	lda #0
	jsr	WGSelectView
	jsr	WGPaintView

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
	ldx	#0			; Initialize
	ldy	#0
	jsr	WGSetCursor
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
	lda	$0100,x
	jsr	WGScrollX	; Apply current X scroll
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
	lda	$0100,x
	jsr	WGScrollY
	dex
	dex

tortureTestPrint_print:
	VBL_SYNC
	jsr	WGEraseViewContents

	lda	#<unitTestStr
	sta	PARAM0
	lda #>unitTestStr
	sta PARAM1

	jsr WGPrint
	jsr WGPrint

;	jmp tortureTestPrint_lock
	jsr delayShort
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
	jsr WGClearScreen

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
	jsr WGClearScreen

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

	ldx	#'Q'+$80
	jsr	WGFillRect
	jsr	WGStrokeRect

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
	jsr WGClearScreen

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

	ldx	#'Q'+$80
	jsr	WGFillRect
	jsr	WGStrokeRect

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



testPrintView:
	.byte "000F061E0A287E"	; 0, 7,3,62,19,75,126

unitTestStr:
	.byte "This is a test of the emergency broadcast system. If this had been a real emergency, you would be dead now. Amusingly, it can be noted that if this had been a real emergency, and you were now a steaming pile of ash, there would of course be nobody.",0; to read this message. That begs any number",0; of extistential questions about this very text.",0
