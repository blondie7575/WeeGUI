;
;  rects.s
;  Rectangle rendering routines for 80 column text elements
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGFillRect
; Fills a rectangle (assumes 80 cols)
; PARAM0: Left edge
; PARAM1: Top edge
; PARAM2: Width
; PARAM3: Height
; Y: Character to fill (Apple format)
; Side effects: Clobbers Y,S0,BASL,BASH
;
WGFillRect:
	SAVE_AX
	sty SCRATCH0

	clc					; Compute bottom edge
	lda PARAM1
	adc PARAM3
	dec
	tax

WGFillRect_vertLoop:
	phx					; We'll need X back for now, but save the line number

	lda TEXTLINES_L,x	; Compute video memory address of left edge of rect
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda PARAM0
	lsr
	clc
	adc BASL
	sta BASL
	lda #$0
	adc BASH
	sta BASH

	lda PARAM0			; Left edge even?
	ror
	bcs WGFillRect_horzLoopOdd

	lda PARAM2
	cmp #1			; Width==1 is a special case
	bne WGFillRect_horzLoopEvenAlignedNormalWidth
	jmp WGFillRect_horzLoopEvenAlignedOneWidth

WGFillRect_horzLoopEvenAlignedOneWidth:
	SETSWITCH PAGE2ON
	bra WGFillRect_horzLoopEvenAlignedOddWidth

WGFillRect_horzLoopEvenAlignedNormalWidth:
	; CASE 1: Left edge even-aligned, even width
	SETSWITCH PAGE2OFF
	lda PARAM2
	lsr
	tay					; Iterate w/2
	dey
	phy					; We'll reuse this calculation for the odd columns

	lda SCRATCH0					; Prepare to plot
WGFillRect_horzLoopEvenAligned0:	; Draw even columns
	sta (BASL),y					; Plot the character
	dey
	bpl WGFillRect_horzLoopEvenAligned0	; Loop for w/2

	SETSWITCH PAGE2ON				; Prepare for odd columns
	ply								; Iterate w/2 again

WGFillRect_horzLoopEvenAligned1:	; Draw odd columns
	sta (BASL),y					; Plot the character
	dey
	bpl WGFillRect_horzLoopEvenAligned1	; Loop for w/2

	lda PARAM2						; Is width even?
	ror
	bcc WGFillRect_horzLoopEvenAlignedEvenWidth

WGFillRect_horzLoopEvenAlignedOddWidth:
	; CASE 1a: Left edge even aligned, odd width
	lda PARAM2						; Fill in extra last column
	lsr
	tay
	lda SCRATCH0					; Plot the character
	sta (BASL),y

WGFillRect_horzLoopEvenAlignedEvenWidth:
	plx								; Prepare for next row
	dex
	bmi WGFillRect_done				; If we were at zero, we'll wrap dangerously
	cpx PARAM1
	bcs WGFillRect_vertLoop
	bra WGFillRect_done

WGFillRect_horzLoopOdd:
	; CASE 2: Left edge odd-aligned, even width

	lda PARAM2
	cmp #1				; Width==1 is a special case
	beq WGFillRect_horzLoopOddAlignedOneWidth

	SETSWITCH PAGE2ON
	lda PARAM2
	lsr
	tay					; Iterate w/2
	phy					; We'll reuse this calculation for the even columns

	lda SCRATCH0					; Prepare to plot
WGFillRect_horzLoopOddAligned0:		; Draw even columns
	sta (BASL),y					; Plot the character
	dey
	bne WGFillRect_horzLoopOddAligned0	; Loop for w/2

	SETSWITCH PAGE2OFF				; Prepare for odd columns
	ply									; Iterate w/2 again, shift left 1
	dey

WGFillRect_horzLoopOddAligned1:		; Draw even columns
	sta (BASL),y					; Plot the character
	dey
	bpl WGFillRect_horzLoopOddAligned1	; Loop for w/2

	lda PARAM2						; Is width even?
	ror
	bcc WGFillRect_horzLoopOddAlignedEvenWidth

WGFillRect_horzLoopOddAlignedOddWidth:
	; CASE 2a: Left edge odd aligned, odd width
	lda PARAM2						; Fill in extra last column
	lsr
	tay
	lda SCRATCH0					; Plot the character
	sta (BASL),y

WGFillRect_horzLoopOddAlignedEvenWidth:
	plx								; Prepare for next row
	dex
	bmi WGFillRect_done				; If we were at zero, we'll wrap dangerously
	cpx PARAM1
	bcc WGFillRect_done
	jmp WGFillRect_vertLoop

WGFillRect_done:
	SETSWITCH PAGE2OFF
	RESTORE_AX
	rts

WGFillRect_horzLoopOddAlignedOneWidth:
	SETSWITCH PAGE2OFF
	bra WGFillRect_horzLoopOddAlignedOddWidth


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGStrokeRect / WGStrokeRoundRect
; Strokes a rectangle (assumes 80 cols)
; PARAM0: Left edge
; PARAM1: Top edge
; PARAM2: Width
; PARAM3: Height
; Side effects: Clobbers BASL,BASH
;
CH_TOP = '_'+$80
CH_BOTTOM = 'L'
CH_LEFT = 'Z'
CH_RIGHT = '_'
CH_ROUND_LEFT = '('+$80
CH_ROUND_RIGHT = ')'+$80
CH_DOUBLE = '\'

.macro PLOTHLINE
	lda (BASL),y
	cmp SCRATCH0
	beq @PLOTHLINE_skip
	cmp #CH_DOUBLE
	beq @PLOTHLINE_skip
	cmp #CH_BOTTOM
	beq @PLOTHLINE_double
	cmp #CH_TOP
	beq @PLOTHLINE_double
	lda SCRATCH0
	bra @PLOTHLINE_plot
@PLOTHLINE_double:
	lda #CH_DOUBLE
@PLOTHLINE_plot:
	sta (BASL),y
@PLOTHLINE_skip:
.endmacro


WGStrokeRect:
	pha
	lda #CH_LEFT
	sta SCRATCH1
	lda #CH_RIGHT
	bra WGStrokeRect_common
WGStrokeRoundRect:
	pha
	lda #CH_ROUND_LEFT
	sta SCRATCH1
	lda #CH_ROUND_RIGHT
WGStrokeRect_common:
	sta SCRATCH2
	pla
	SAVE_AXY
	SAVE_ZPS

	; Top and bottom edges
	;
	ldx PARAM1			; Start with top edge
	dex
	lda #CH_TOP
	sta SCRATCH0

WGStrokeRect_horzEdge:
	lda TEXTLINES_L,x	; Compute video memory address of left edge of rect
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda PARAM0
	lsr
	clc
	adc BASL
	sta BASL
	lda #$0
	adc BASH
	sta BASH

	lda PARAM0			; Left edge even?
	ror
	bcc WGStrokeRect_horzEdgeEven
	jmp WGStrokeRect_horzLoopOdd

WGStrokeRect_horzEdgeEven:
	lda PARAM2
	cmp #1				; Width==1 is a special case
	bne WGStrokeRect_horzLoopEvenAlignedNormalWidth
	jmp WGStrokeRect_horzLoopEvenAlignedOneWidth

WGStrokeRect_horzLoopEvenAlignedNormalWidth:
	; CASE 1: Left edge even-aligned, even width
	SETSWITCH PAGE2OFF
	lda PARAM2
	lsr
	tay					; Start at right edge
	dey
	phy					; We'll reuse this calculation for the odd columns

WGStrokeRect_horzLoopEvenAligned0:	; Draw even columns
	PLOTHLINE						; Plot the character
	dey
	bpl WGStrokeRect_horzLoopEvenAligned0	; Loop for w/2

	SETSWITCH PAGE2ON			; Prepare for odd columns
	ply								; Start at right edge again

WGStrokeRect_horzLoopEvenAligned1:	; Draw odd columns
	PLOTHLINE						; Plot the character
	dey
	bpl WGStrokeRect_horzLoopEvenAligned1	; Loop for w/2

	lda PARAM2						; Is width even?
	ror
	bcc WGStrokeRect_horzLoopEvenAlignedEvenWidth

WGStrokeRect_horzLoopEvenAlignedOddWidth:
	; CASE 1a: Left edge even aligned, odd width
	lda PARAM2						; Fill in extra last column
	lsr
	tay
	PLOTHLINE						; Plot the character

WGStrokeRect_horzLoopEvenAlignedEvenWidth:
	inx
	cpx PARAM1
	beq WGStrokeRect_horzLoopEvenAlignedEvenWidthBottom
	jmp WGStrokeRect_vertEdge

WGStrokeRect_horzLoopEvenAlignedEvenWidthBottom:
	clc								; Prepare for bottom edge
	lda PARAM1
	adc PARAM3
	tax
	lda #CH_BOTTOM
	sta SCRATCH0
	jmp WGStrokeRect_horzEdge

WGStrokeRect_horzLoopEvenAlignedOneWidth:
	SETSWITCH PAGE2ON
	bra WGStrokeRect_horzLoopEvenAlignedOddWidth

WGStrokeRect_horzLoopOdd:
	; CASE 2: Left edge odd-aligned, even width

	lda PARAM2
	cmp #1				; Width==1 is a special case
	beq WGStrokeRect_horzLoopOddAlignedOneWidth

	SETSWITCH PAGE2ON
	lda PARAM2
	lsr
	tay					; Iterate w/2
	phy					; We'll reuse this calculation for the even columns

WGStrokeRect_horzLoopOddAligned0:		; Draw even columns
	PLOTHLINE						; Plot the character
	dey
	bne WGStrokeRect_horzLoopOddAligned0	; Loop for w/2

	SETSWITCH PAGE2OFF				; Prepare for odd columns
	ply									; Iterate w/2 again, shift left 1
	dey

WGStrokeRect_horzLoopOddAligned1:		; Draw even columns
	PLOTHLINE						; Plot the character
	dey
	bpl WGStrokeRect_horzLoopOddAligned1	; Loop for w/2

	lda PARAM2						; Is width even?
	ror
	bcc WGStrokeRect_horzLoopOddAlignedEvenWidth

WGStrokeRect_horzLoopOddAlignedOddWidth:
	; CASE 2a: Left edge odd aligned, odd width
	lda PARAM2						; Fill in extra last column
	dec
	lsr
	tay
	PLOTHLINE						; Plot the character

WGStrokeRect_horzLoopOddAlignedEvenWidth:
	inx
	cpx PARAM1
	bne WGStrokeRect_vertEdge
	clc								; Prepare for bottom edge
	lda PARAM1
	adc PARAM3
	tax
	lda #CH_BOTTOM
	sta SCRATCH0
	jmp WGStrokeRect_horzEdge

WGStrokeRect_horzLoopOddAlignedOneWidth:
	SETSWITCH PAGE2OFF
	bra WGStrokeRect_horzLoopOddAlignedOddWidth

WGStrokeRect_vertEdge:
	; Left and right edges
	;
	clc
	lda PARAM1				; Compute bottom edge
	adc PARAM3
	sta SCRATCH0

	ldx PARAM1				; Start with top edge

WGStrokeRect_vertLoop:

	phx					; We'll need X back for now, but save the line number

	lda TEXTLINES_L,x	; Compute video memory address of left edge of rect
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda PARAM0
	dec
	lsr
	clc
	adc BASL
	sta BASL
	lda #$0
	adc BASH
	sta BASH

	lda PARAM0			; Left edge even?
	dec
	ror
	bcs WGStrokeRect_vertLoopOdd

	; CASE 1: Left edge even-aligned, even width
	SETSWITCH PAGE2ON
	ldy #$0
	lda SCRATCH1					; Plot the left edge
	sta (BASL),y

	lda PARAM2						; Is width even?
	inc
	inc
	ror
	bcs WGStrokeRect_vertLoopEvenAlignedOddWidth

	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	dec
	tay
	SETSWITCH PAGE2OFF
	lda SCRATCH2					; Plot the right edge
	sta (BASL),y
	jmp WGStrokeRect_vertLoopEvenAlignedNextRow

WGStrokeRect_vertLoopEvenAlignedOddWidth:
	; CASE 1a: Left edge even-aligned, odd width
	SETSWITCH PAGE2ON
	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	lda SCRATCH2					; Plot the right edge
	sta (BASL),y

WGStrokeRect_vertLoopEvenAlignedNextRow:
	plx								; Prepare for next row
	inx
	cpx SCRATCH0
	bne WGStrokeRect_vertLoop
	jmp WGStrokeRect_done


WGStrokeRect_vertLoopOdd:
	; CASE 2: Left edge odd-aligned, even width
	SETSWITCH PAGE2OFF
	ldy #$0
	lda SCRATCH1					; Plot the left edge
	sta (BASL),y

	lda PARAM2						; Is width even?
	inc
	inc
	ror
	bcs WGStrokeRect_vertLoopOddAlignedOddWidth

	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	SETSWITCH PAGE2ON
	lda SCRATCH2					; Plot the right edge
	sta (BASL),y
	jmp WGStrokeRect_vertLoopOddAlignedNextRow

WGStrokeRect_vertLoopOddAlignedOddWidth:
	; CASE 2a: Left edge odd-aligned, odd width
	SETSWITCH PAGE2OFF
	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	lda SCRATCH2					; Plot the right edge
	sta (BASL),y

WGStrokeRect_vertLoopOddAlignedNextRow:
	plx								; Prepare for next row
	inx
	cpx SCRATCH0
	bne WGStrokeRect_vertLoopJmp
	jmp WGStrokeRect_done
WGStrokeRect_vertLoopJmp:
	jmp WGStrokeRect_vertLoop
	
WGStrokeRect_done:
	SETSWITCH PAGE2OFF
	RESTORE_ZPS
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGFancyRect
; Draws a fancy rectangle (assumes 80 cols)
; PARAM0: Left edge
; PARAM1: Top edge
; PARAM2: Width
; PARAM3: Height
; Side effects: Clobbers BASL,BASH
;
FR_TOP = '\'
FR_BOTTOM = '_'+$80
FR_LEFT = 'Z'
FR_RIGHT = 'Z'
FR_TOPLEFT = 'Z'
FR_TOPRIGHT = '^'
FR_TOPRIGHTA = 'R'
FR_BOTTOMRIGHT = $7f
FR_BOTTOMRIGHTA1 = 'Q'
FR_BOTTOMRIGHTA2 = 'P'
FR_BOTTOMLEFT = 'Z'
FR_BOTTOMLEFTA = 'O'

WGFancyRect:
	SAVE_AXY
	SAVE_ZPS

	; Top and bottom edges
	;
	ldx PARAM1			; Start with top edge
	dex
	lda #FR_TOP
	sta SCRATCH0

WGFancyRect_horzEdge:
	lda TEXTLINES_L,x	; Compute video memory address of left edge of rect
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda PARAM0
	lsr
	clc
	adc BASL
	sta BASL
	lda #$0
	adc BASH
	sta BASH

	lda PARAM0			; Left edge even?
	ror
	bcs WGFancyRect_horzLoopOdd

	; CASE 1: Left edge even-aligned, even width
	SETSWITCH PAGE2OFF
	lda PARAM2
	lsr
	tay					; Start at right edge
	dey
	phy					; We'll reuse this calculation for the odd columns

WGFancyRect_horzLoopEvenAligned0:	; Draw even columns
	lda SCRATCH0					; Plot the character
	sta (BASL),y
	dey
	bpl WGFancyRect_horzLoopEvenAligned0	; Loop for w/2

	SETSWITCH PAGE2ON			; Prepare for odd columns
	ply								; Start at right edge again

WGFancyRect_horzLoopEvenAligned1:	; Draw odd columns
	lda SCRATCH0					; Plot the character
	sta (BASL),y
	dey
	bpl WGFancyRect_horzLoopEvenAligned1	; Loop for w/2

	lda PARAM2						; Is width even?
	ror
	bcc WGFancyRect_horzLoopEvenAlignedEvenWidth

WGFancyRect_horzLoopEvenAlignedOddWidth:
	; CASE 1a: Left edge even aligned, odd width
	lda PARAM2						; Fill in extra last column
	lsr
	tay
	lda SCRATCH0					; Plot the character
	sta (BASL),y

WGFancyRect_horzLoopEvenAlignedEvenWidth:
	inx
	cpx PARAM1
	bne WGFancyRect_vertEdge
	clc								; Prepare for bottom edge
	lda PARAM1
	adc PARAM3
	tax
	lda #FR_BOTTOM
	sta SCRATCH0
	jmp WGFancyRect_horzEdge

WGFancyRect_horzLoopOdd:
	; CASE 2: Left edge odd-aligned, even width

	SETSWITCH PAGE2ON
	lda PARAM2
	lsr
	tay					; Iterate w/2
	phy					; We'll reuse this calculation for the even columns

WGFancyRect_horzLoopOddAligned0:		; Draw even columns
	lda SCRATCH0					; Plot the character
	sta (BASL),y
	dey
	bne WGFancyRect_horzLoopOddAligned0	; Loop for w/2

	SETSWITCH PAGE2OFF				; Prepare for odd columns
	ply									; Iterate w/2 again, shift left 1
	dey

WGFancyRect_horzLoopOddAligned1:		; Draw even columns
	lda SCRATCH0					; Plot the character
	sta (BASL),y
	dey
	bpl WGFancyRect_horzLoopOddAligned1	; Loop for w/2

	lda PARAM2						; Is width even?
	ror
	bcc WGFancyRect_horzLoopOddAlignedEvenWidth

WGFancyRect_horzLoopOddAlignedOddWidth:
	; CASE 2a: Left edge odd aligned, odd width
	lda PARAM2						; Fill in extra last column
	dec
	lsr
	tay
	lda SCRATCH0					; Plot the character
	sta (BASL),y

WGFancyRect_horzLoopOddAlignedEvenWidth:
	inx
	cpx PARAM1
	bne WGFancyRect_vertEdge
	clc								; Prepare for bottom edge
	lda PARAM1
	adc PARAM3
	tax
	lda #FR_BOTTOM
	sta SCRATCH0
	jmp WGFancyRect_horzEdge

WGFancyRect_vertEdge:
	; Left and right edges
	;
	clc
	lda PARAM1				; Compute bottom edge
	adc PARAM3
	sta SCRATCH0

	ldx PARAM1				; Start with top edge

WGFancyRect_vertLoop:

	phx					; We'll need X back for now, but save the line number

	lda TEXTLINES_L,x	; Compute video memory address of left edge of rect
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda PARAM0
	dec
	lsr
	clc
	adc BASL
	sta BASL
	lda #$0
	adc BASH
	sta BASH

	lda PARAM0			; Left edge even?
	dec
	ror
	bcs WGFancyRect_vertLoopOdd

	; CASE 1: Left edge even-aligned, even width
	SETSWITCH PAGE2ON
	ldy #$0
	lda #FR_LEFT					; Plot the left edge
	sta (BASL),y

	lda PARAM2						; Is width even?
	inc
	inc
	ror
	bcs WGFancyRect_vertLoopEvenAlignedOddWidth

	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	dec
	tay
	SETSWITCH PAGE2OFF
	lda #FR_RIGHT					; Plot the right edge
	sta (BASL),y
	jmp WGFancyRect_vertLoopEvenAlignedNextRow

WGFancyRect_vertLoopEvenAlignedOddWidth:
	; CASE 1a: Left edge even-aligned, odd width
	SETSWITCH PAGE2ON
	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	lda #FR_RIGHT					; Plot the right edge
	sta (BASL),y

WGFancyRect_vertLoopEvenAlignedNextRow:
	plx								; Prepare for next row
	inx
	cpx SCRATCH0
	bne WGFancyRect_vertLoop
	jmp WGFancyRect_corners


WGFancyRect_vertLoopOdd:
	; CASE 2: Left edge odd-aligned, even width
	SETSWITCH PAGE2OFF
	ldy #$0
	lda #FR_LEFT					; Plot the left edge
	sta (BASL),y

	lda PARAM2						; Is width even?
	inc
	inc
	ror
	bcs WGFancyRect_vertLoopOddAlignedOddWidth

	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	SETSWITCH PAGE2ON
	lda #FR_RIGHT					; Plot the right edge
	sta (BASL),y
	jmp WGFancyRect_vertLoopOddAlignedNextRow

WGFancyRect_vertLoopOddAlignedOddWidth:
	; CASE 2a: Left edge odd-aligned, odd width
	SETSWITCH PAGE2OFF
	lda PARAM2						; Calculate right edge
	inc
	inc
	lsr
	tay
	lda #FR_RIGHT					; Plot the right edge
	sta (BASL),y

WGFancyRect_vertLoopOddAlignedNextRow:
	plx								; Prepare for next row
	inx
	cpx SCRATCH0
	bne WGFancyRect_vertLoopJmp
	jmp WGFancyRect_corners
WGFancyRect_vertLoopJmp:
	jmp WGFancyRect_vertLoop

WGFancyRect_corners:
	lda PARAM0						; Top left corner
	dec
	sta WG_CURSORX
	lda PARAM1
	dec
	sta WG_CURSORY
	lda #FR_TOPLEFT
	jsr WGPlot

	lda PARAM0						; Top right corner
	clc
	adc PARAM2
	sta WG_CURSORX
	lda #FR_TOPRIGHT
	jsr WGPlot

	inc WG_CURSORY
	lda #FR_TOPRIGHTA
	jsr WGPlot

	lda PARAM1						; Bottom right corner
	dec
	clc
	adc PARAM3
	sta WG_CURSORY
	lda #FR_BOTTOMRIGHTA1
	jsr WGPlot

	inc WG_CURSORY
	lda #FR_BOTTOMRIGHT
	jsr WGPlot

	dec WG_CURSORX
	lda #FR_BOTTOMRIGHTA2
	jsr WGPlot

	lda PARAM0						; Bottom left corner
	sta WG_CURSORX
	lda #FR_BOTTOMLEFTA
	jsr WGPlot
	dec WG_CURSORX
	lda #FR_BOTTOMLEFT
	jsr WGPlot

WGFancyRect_done:
	SETSWITCH	PAGE2OFF
	RESTORE_ZPS
	RESTORE_AXY
	rts

