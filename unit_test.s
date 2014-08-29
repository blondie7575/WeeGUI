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

	lda	#38			; Initialize
	pha
	lda #11
	pha
	lda #2
	pha
	lda #2
	pha

tortureTestRectsLoop:

	jsr WGClearScreen

	tsx
	inx
	lda	$0100,x		; Load Height, then modify
	sta	PARAM3
	inc
	inc
	sta	$0100,x
	cmp	#25
	bcs	tortureTestRectsDone

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

;	ldx	#'Q'+$80
;	jsr	WGFillRect
	jsr	WGStrokeRect

;	jsr delayShort

	jmp tortureTestRectsLoop

tortureTestRectsDone:
	pla
	pla
	pla
	pla
	jmp	tortureTestRects

