;
;  painting.s
;  Rendering routines for 80 column text elements
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGClearScreen
; Clears the text screen (assumes 80 cols)
; Side effects: Clobbers BASL,BASH
;
WGClearScreen:

	SAVE_AXY
	SETSWITCH	PAGE2OFF
	ldx	#23

WGClearScreen_lineLoop:

	lda TEXTLINES_L,x	; Compute video memory address of line
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	ldy	#39
	lda	#' ' + $80

WGClearScreen_charLoop:
	sta	(BASL),y
	SETSWITCH	PAGE2ON
	sta	(BASL),y
	SETSWITCH	PAGE2OFF
	dey
	bpl	WGClearScreen_charLoop

	dex
	bpl WGClearScreen_lineLoop

	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGFillRect
; Fills a rectangle (assumes 80 cols)
; PARAM0: Left edge
; PARAM1: Top edge
; PARAM2: Width
; PARAM3: Height
; X: Character to fill
; Side effects: Clobbers BASL,BASH
;
WGFillRect:

	SAVE_AXY
	SAVE_ZPS
	stx	SCRATCH0

	clc					; Compute bottom edge
	lda	PARAM1
	adc PARAM3
	tax

WGFillRect_vertLoop:
	phx					; We'll need X back for now, but save the line number

	lda TEXTLINES_L,x	; Compute video memory address of left edge of rect
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda	PARAM0
	lsr
	clc
	adc	BASL
	sta BASL
	lda	#$0
	adc BASH
	sta BASH

	lda	PARAM0			; Left edge even?
	and	#$01
	bne	WGFillRect_horzLoopOdd

	; CASE 1: Left edge even-aligned, even width
	SETSWITCH	PAGE2OFF
	lda	PARAM2
	lsr
	tay					; Iterate w/2
	dey
	phy					; We'll reuse this calculation for the odd columns

WGFillRect_horzLoopEvenAligned0:	; Draw even columns
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y
	dey
	bpl	WGFillRect_horzLoopEvenAligned0	; Loop for w/2

	SETSWITCH	PAGE2ON				; Prepare for odd columns
	ply								; Iterate w/2 again

WGFillRect_horzLoopEvenAligned1:	; Draw odd columns
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y
	dey
	bpl	WGFillRect_horzLoopEvenAligned1	; Loop for w/2

	lda	PARAM2						; Is width even?
	and	#$01
	beq	WGFillRect_horzLoopEvenAlignedEvenWidth

	; CASE 1a: Left edge even aligned, odd width
	lda	PARAM2						; Fill in extra last column
	lsr
	tay
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y

WGFillRect_horzLoopEvenAlignedEvenWidth:
	plx								; Prepare for next row
	dex
	cpx	PARAM1
	bcs	WGFillRect_vertLoop
	jmp	WGFillRect_done

WGFillRect_horzLoopOdd:
	; CASE 2: Left edge odd-aligned, even width
	SETSWITCH	PAGE2ON
	lda	PARAM2
	lsr
	tay					; Iterate w/2
	phy					; We'll reuse this calculation for the even columns

WGFillRect_horzLoopOddAligned0:		; Draw even columns
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y
	dey
	bne	WGFillRect_horzLoopOddAligned0	; Loop for w/2

	SETSWITCH	PAGE2OFF				; Prepare for odd columns
	ply									; Iterate w/2 again, shift left 1
	dey

WGFillRect_horzLoopOddAligned1:		; Draw even columns
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y
	dey
	bpl	WGFillRect_horzLoopOddAligned1	; Loop for w/2

	lda	PARAM2						; Is width even?
	and	#$01
	beq	WGFillRect_horzLoopOddAlignedEvenWidth

	; CASE 2a: Left edge odd aligned, odd width
	lda	PARAM2						; Fill in extra last column
	lsr
	tay
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y

WGFillRect_horzLoopOddAlignedEvenWidth:
	plx								; Prepare for next row
	dex
	cpx	PARAM1
	bcs	WGFillRect_vertLoopJmp
	jmp WGFillRect_done
WGFillRect_vertLoopJmp:
	jmp	WGFillRect_vertLoop

WGFillRect_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGStrokeRect
; Strokes a rectangle (assumes 80 cols)
; PARAM0: Left edge
; PARAM1: Top edge
; PARAM2: Width
; PARAM3: Height
; Side effects: Clobbers BASL,BASH
;
CH_TOP = '_'+$80
CH_BOTTOM = 'L';'_'+$80
CH_LEFT = 'Z';'_'+$80
CH_RIGHT = '_'
CH_BOTTOMLEFT = 'L'
CH_BOTTOMRIGHT = '_'+$80

WGStrokeRect:

	SAVE_AXY
	SAVE_ZPS

	; Top and bottom edges
	;
	ldx	PARAM1			; Start with top edge
	dex
	lda	#CH_TOP
	sta	SCRATCH0

WGStrokeRect_horzEdge:
	lda TEXTLINES_L,x	; Compute video memory address of left edge of rect
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda	PARAM0
	lsr
	clc
	adc	BASL
	sta BASL
	lda	#$0
	adc BASH
	sta BASH

	lda	PARAM0			; Left edge even?
	and	#$01
	bne	WGStrokeRect_horzLoopOdd

	; CASE 1: Left edge even-aligned, even width
	SETSWITCH	PAGE2OFF
	lda	PARAM2
	lsr
	tay					; Start at right edge
	dey
	phy					; We'll reuse this calculation for the odd columns

WGStrokeRect_horzLoopEvenAligned0:	; Draw even columns
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y
	dey
	bpl	WGStrokeRect_horzLoopEvenAligned0	; Loop for w/2

	SETSWITCH	PAGE2ON			; Prepare for odd columns
	ply								; Start at right edge again

WGStrokeRect_horzLoopEvenAligned1:	; Draw odd columns
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y
	dey
	bpl	WGStrokeRect_horzLoopEvenAligned1	; Loop for w/2

	lda	PARAM2						; Is width even?
	and	#$01
	beq	WGStrokeRect_horzLoopEvenAlignedEvenWidth

	; CASE 1a: Left edge even aligned, odd width
	;SETSWITCH	PAGE2OFF
	lda	PARAM2						; Fill in extra last column
	lsr
	tay
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y

WGStrokeRect_horzLoopEvenAlignedEvenWidth:
	inx
	cpx	PARAM1
	bne WGStrokeRect_vertEdge
	clc								; Prepare for bottom edge
	lda PARAM1
	adc PARAM3
	tax
	lda	#CH_BOTTOM
	sta SCRATCH0
	jmp	WGStrokeRect_horzEdge

WGStrokeRect_horzLoopOdd:
	; CASE 2: Left edge odd-aligned, even width
	SETSWITCH	PAGE2ON
	lda	PARAM2
	lsr
	tay					; Iterate w/2
	phy					; We'll reuse this calculation for the even columns

WGStrokeRect_horzLoopOddAligned0:		; Draw even columns
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y
	dey
	bne	WGStrokeRect_horzLoopOddAligned0	; Loop for w/2

	SETSWITCH	PAGE2OFF				; Prepare for odd columns
	ply									; Iterate w/2 again, shift left 1
	dey

WGStrokeRect_horzLoopOddAligned1:		; Draw even columns
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y
	dey
	bpl	WGStrokeRect_horzLoopOddAligned1	; Loop for w/2

	lda	PARAM2						; Is width even?
	and	#$01
	beq	WGStrokeRect_horzLoopOddAlignedEvenWidth

	; CASE 2a: Left edge odd aligned, odd width
	lda	PARAM2						; Fill in extra last column
	dec
	lsr
	tay
	lda	SCRATCH0					; Plot the character
	sta	(BASL),y

WGStrokeRect_horzLoopOddAlignedEvenWidth:
	inx
	cpx	PARAM1
	bne WGStrokeRect_vertEdge
	clc								; Prepare for bottom edge
	lda PARAM1
	adc PARAM3
	tax
	lda #CH_BOTTOM
	sta SCRATCH0
	jmp	WGStrokeRect_horzEdge


WGStrokeRect_vertEdge:
	; Left and right edges
	;
	clc
	lda	PARAM1				; Compute bottom edge
	adc PARAM3
	sta	SCRATCH0

	ldx	PARAM1				; Start with top edge

WGStrokeRect_vertLoop:

	phx					; We'll need X back for now, but save the line number

	lda TEXTLINES_L,x	; Compute video memory address of left edge of rect
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda	PARAM0
	dec
	lsr
	clc
	adc	BASL
	sta BASL
	lda	#$0
	adc BASH
	sta BASH

	lda	PARAM0			; Left edge even?
	dec
	and	#$01
	bne	WGStrokeRect_vertLoopOdd

	; CASE 1: Left edge even-aligned, even width
	SETSWITCH	PAGE2ON
	ldy	#$0
	lda	#CH_LEFT					; Plot the left edge
	sta	(BASL),y

	lda	PARAM2						; Is width even?
	inc
	inc
	and	#$01
	bne	WGStrokeRect_vertLoopEvenAlignedOddWidth

	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	dec
	tay
	SETSWITCH	PAGE2OFF
	lda	#CH_RIGHT					; Plot the right edge
	sta	(BASL),y
	jmp	WGStrokeRect_vertLoopEvenAlignedNextRow

WGStrokeRect_vertLoopEvenAlignedOddWidth:
	; CASE 1a: Left edge even-aligned, odd width
	SETSWITCH	PAGE2ON
	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	lda	#CH_RIGHT					; Plot the right edge
	sta	(BASL),y

WGStrokeRect_vertLoopEvenAlignedNextRow:
	plx								; Prepare for next row
	inx
	cpx	SCRATCH0
	bne	WGStrokeRect_vertLoop
	jmp	WGStrokeRect_done


WGStrokeRect_vertLoopOdd:
	; CASE 2: Left edge odd-aligned, even width
	SETSWITCH	PAGE2OFF
	ldy	#$0
	lda	#CH_LEFT					; Plot the left edge
	sta	(BASL),y

	lda	PARAM2						; Is width even?
	inc
	inc
	and	#$01
	bne	WGStrokeRect_vertLoopOddAlignedOddWidth

	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	SETSWITCH	PAGE2ON
	lda	#CH_RIGHT					; Plot the right edge
	sta	(BASL),y
	jmp	WGStrokeRect_vertLoopOddAlignedNextRow

WGStrokeRect_vertLoopOddAlignedOddWidth:
	; CASE 2a: Left edge odd-aligned, odd width
	SETSWITCH	PAGE2OFF
	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	lda	#CH_RIGHT					; Plot the right edge
	sta	(BASL),y

WGStrokeRect_vertLoopOddAlignedNextRow:
	plx								; Prepare for next row
	inx
	cpx	SCRATCH0
	bne	WGStrokeRect_vertLoopJmp
	jmp WGStrokeRect_done
WGStrokeRect_vertLoopJmp:
	jmp WGStrokeRect_vertLoop
	
WGStrokeRect_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPlot
; Plots a character at current cursor position (assumes 80 cols)
; A: Character to plot
; Side effects: Clobbers SCRATCH0,BASL,BASH
;
WGPlot:
	sta SCRATCH0
	SAVE_AXY
	SAVE_ZPS

	ldx	WG_CURSORY
	lda TEXTLINES_L,x	; Compute video memory address of point
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda	WG_CURSORX
	lsr
	clc
	adc	BASL
	sta BASL
	lda	#$0
	adc BASH
	sta BASH

	lda	WG_CURSORX			; X even?
	and	#$01
	bne	WGPlot_xOdd

	SETSWITCH	PAGE2ON		; Plot the character
	ldy	#$0
	lda	SCRATCH0
	sta	(BASL),y
	jmp WGPlot_done

WGPlot_xOdd:
	SETSWITCH	PAGE2OFF	; Plot the character
	ldy	#$0
	lda	SCRATCH0
	sta	(BASL),y

WGPlot_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPrintASCII
; Prints a null-terminated ASCII string at the current view's
; cursor position. Clips to current view
; PARAM0: String pointer, LSB
; PARAM1: String pointer, MSB
; Side effects: Clobbers BASL,BASH
;
WGPrintASCII:
	SAVE_AXY
	SAVE_ZPS

	jsr	WGSyncGlobalCursor

	LDY_ACTIVEVIEW

	iny						; Clip to upper extent
	lda	WG_CURSORY
	cmp WG_VIEWRECORDS,y
	bcc	WGPrintASCII_done

	lda	WG_VIEWRECORDS,y	; Clip to lower extent
	iny
	iny
	clc
	adc	WG_VIEWRECORDS,y
	dec
	cmp	WG_CURSORY
	bcc	WGPrintASCII_done

	jsr	WGStrLen			; We'll need the length of the string to clip horizontally
	sta	SCRATCH0

	dey						; Clip left/right extents
	dey
	dey
	lda	WG_CURSORX			; startIndex = -(globalX - windowStartX)
	sec
	sbc	WG_VIEWRECORDS,y
	eor	#$ff
	inc
	bmi	WGPrintASCII_leftEdgeStart
	cmp	SCRATCH0
	bcs	WGPrintASCII_done	; Entire string is left of window

	tax						; Starting mid-string on the left
	lda	WG_VIEWRECORDS,y
	sta	WG_CURSORX
	txa
	bra	WGPrintASCII_findRightEdge

WGPrintASCII_leftEdgeStart:
	lda #0

WGPrintASCII_findRightEdge:
	pha						; Stash start index

	lda	WG_VIEWRECORDS,y
	iny
	iny
	clc
	adc	WG_VIEWRECORDS,y
	tax
	dex
	ply						; End cursor in X, start index in Y

WGPrintASCII_loop:
	cpx	WG_CURSORX
	bcc	WGPrintASCII_done	; Hit the right edge of the window
	lda	(PARAM0),y
	beq	WGPrintASCII_done	; Hit the end of the string
	ora #$80
	jsr	WGPlot

	iny
	clc
	lda #1
	adc WG_CURSORX
	sta	WG_CURSORX
	lda #0
	adc WG_CURSORY
	sta	WG_CURSORY
	jmp	WGPrintASCII_loop

WGPrintASCII_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPrint
; Prints a null-terminated Apple string at the current view's
; cursor position. Clips to current view.
; PARAM0: String pointer, LSB
; PARAM1: String pointer, MSB
; Side effects: Clobbers BASL,BASH
;
WGPrint:
	SAVE_AXY
	SAVE_ZPS

	


WGPrint_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts
