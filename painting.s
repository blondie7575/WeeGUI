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
	dec
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
; Side effects: Clobbers S0, BASL,BASH
;
WGPlot:
	sta SCRATCH0
	SAVE_AXY

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
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPrint
; Prints a null-terminated Apple string at the current view's
; cursor position. Clips to current view.
; PARAM0: String pointer, LSB
; PARAM1: String pointer, MSB
; Side effects: Clobbers SA,BASL,BASH
;
WGPrint:
	SAVE_AXY
	SAVE_ZPS

	jsr	WGStrLen			; We'll need the length of the string
	sta	SCRATCH1

	LDX_ACTIVEVIEW			; Cache view width for later
	inx
	inx
	inx
	inx
	inx
	inx
	inx
	lda WG_VIEWRECORDS,x
	sta WG_SCRATCHA
	inx						; Leave X pointing at view height, for later quick access

	ldy #0

WGPrint_lineLoopFirst:		; Calculating start of first line is slightly different
	lda	WG_LOCALCURSORY
	cmp	WG_VIEWCLIP+1
	bcc	WGPrint_skipToEndFirst	; This line is above the clip box

	lda	WG_LOCALCURSORX		; Find start of line within clip box
	cmp WG_VIEWCLIP+0
	bcs WGPrint_visibleChars

	lda	WG_VIEWCLIP+0
	sec						; Line begins before left clip plane
	sbc WG_LOCALCURSORX
	tay						; Advance string index and advance cursor into clip box
	lda WG_VIEWCLIP+0
	sta	WG_LOCALCURSORX
	bra WGPrint_visibleChars

WGPrint_skipToEndFirst:
	lda WG_SCRATCHA			; Skip string index ahead by distance to EOL
	sec
	sbc WG_LOCALCURSORX
	cmp	SCRATCH1
	bcs	WGPrint_done
	tay

	lda	WG_SCRATCHA			; Skip cursor ahead to EOL
	sta WG_LOCALCURSORX
	bra WGPrint_nextLine

WGPrint_skipToEnd:
	tya						; Skip string index ahead by distance to EOL
	clc
	adc WG_SCRATCHA
	tay

	lda	WG_SCRATCHA			; Skip cursor ahead to EOL
	sta WG_LOCALCURSORX
	bra WGPrint_nextLine

WGPrint_lineLoop:
	lda	WG_LOCALCURSORY
	cmp	WG_VIEWCLIP+1
	bcc	WGPrint_skipToEnd	; This line is above the clip box

	lda	WG_LOCALCURSORX		; Find start of line within clip box
	cmp WG_VIEWCLIP+0
	bcs WGPrint_visibleChars

	tya
	clc
	adc	WG_VIEWCLIP+0		; Jump ahead by left span
	tay

	lda WG_VIEWCLIP+0		; Set cursor to left edge of visible area
	sta	WG_LOCALCURSORX

WGPrint_visibleChars:
	jsr	WGSyncGlobalCursor

WGPrint_charLoop:
	lda	(PARAM0),y			; Draw current character
	beq WGPrint_done
	ora #$80
	jsr	WGPlot
	iny

	inc WG_CURSORX			; Advance cursors
	inc WG_LOCALCURSORX

	lda WG_LOCALCURSORX
	cmp	WG_SCRATCHA			; Check for wrap boundary
	beq	WGPrint_nextLine
	cmp	WG_VIEWCLIP+2		; Check for right clip plane
	beq	WGPrint_endVisible
	bra WGPrint_charLoop

WGPrint_endVisible:
	tya
	clc
	adc	WG_VIEWCLIP+4		; Advance string index by right span
	cmp	SCRATCH1
	bcs	WGPrint_done
	tay

WGPrint_nextLine:
	inc	WG_LOCALCURSORY			; Advance cursor
	lda	WG_LOCALCURSORY
	cmp	WG_VIEWCLIP+3			; Check for bottom clip plane
	beq	WGPrint_done
	cmp	WG_VIEWRECORDS,x		; Check for bottom of view
	beq	WGPrint_done

	lda #0						; Wrap to next line
	sta	WG_LOCALCURSORX
	jmp WGPrint_lineLoop

WGPrint_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts
