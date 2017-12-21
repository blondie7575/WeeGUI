;
;  painting.s
;  General rendering routines for 80 column text elements
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
; WGDesktop
; Paints the desktop pattern (assumes 80 cols)
; Side effects: Clobbers BASL,BASH
;
WGDesktop:

	SAVE_AXY
	SETSWITCH	PAGE2OFF
	ldx	#23

WGDesktop_lineLoop:
	lda TEXTLINES_L,x	; Compute video memory address of line
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	ldy	#39

WGDesktop_charLoop:
	lda #'W'
	sta	(BASL),y
	SETSWITCH	PAGE2ON
	lda #'V'
	sta	(BASL),y
	SETSWITCH	PAGE2OFF
	dey
	bpl	WGDesktop_charLoop

	dex
	bpl WGDesktop_lineLoop

	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPlot
; Plots a character at global cursor position (assumes 80 cols)
; A: Character to plot (Apple format)
; Side effects: Clobbers BASL,BASH
;
WGPlot:
	SAVE_XY
	pha

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
	ror
	bcs	WGPlot_xOdd

	SETSWITCH	PAGE2ON		; Plot the character
	pla
	sta	(BASL)
	jmp WGPlot_done

WGPlot_xOdd:
	SETSWITCH	PAGE2OFF	; Plot the character
	pla
	sta	(BASL)

WGPlot_done:
	SETSWITCH	PAGE2OFF
	RESTORE_XY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPrint
; Prints a null-terminated ASCII string at the current view's
; cursor position. Clips to current view.
; PARAM0: String pointer, LSB
; PARAM1: String pointer, MSB
; V: If set, characters are printed raw with no high bit alterations
; Side effects: Clobbers SA,BASL,BASH
;
WGPrint:
	SAVE_AXY
	SAVE_ZPS

	lda #%10000000
	ldx #%00111111
	bvc WGPrint_setupMask
	lda #0
	ldx #$ff
	clv

WGPrint_setupMask:
	sta WGPrint_specialMask
	stx WGPrint_setupMaskInverse

	; Start checking clipping boundaries
	lda WG_LOCALCURSORY
	cmp	WG_VIEWCLIP+3
	bcs	WGPrint_leapDone	; Entire string is below the clip box

	jsr	WGStrLen			; We'll need the length of the string
	sta	SCRATCH1

	LDX_ACTIVEVIEW			; Cache view width for later
	lda WG_VIEWRECORDS+7,x
	sta WG_SCRATCHA

	ldy #0

WGPrint_lineLoopFirst:		; Calculating start of first line is slightly different
	lda	WG_LOCALCURSORY
	cmp	WG_VIEWCLIP+1
	bcc	WGPrint_skipToEndFirst	; This line is above the clip box

	lda	WG_LOCALCURSORX		; Find start of line within clip box
	cmp WG_VIEWCLIP+0
	bcs WGPrint_visibleChars

	lda	WG_VIEWCLIP+0		; Line begins before left clip plane
	sec						; Advance string index and advance cursor into clip box
	sbc WG_LOCALCURSORX
	tay
	lda WG_VIEWCLIP+0
	sta	WG_LOCALCURSORX
	bra WGPrint_visibleChars

WGPrint_leapDone:
	bra WGPrint_done

WGPrint_skipToEndFirst:
	lda WG_SCRATCHA			; Skip string index ahead by distance to EOL
	sec
	sbc WG_LOCALCURSORX
	cmp	SCRATCH1
	bcs	WGPrint_done		; EOL is past the end of the string, so we're done
	tay

	lda	WG_SCRATCHA			; Skip cursor ahead to EOL
	sta WG_LOCALCURSORX
	bra WGPrint_nextLine

WGPrint_skipToEnd:
	tya						; Skip string index ahead by distance to EOL
	clc
	adc WG_SCRATCHA
	cmp SCRATCH1
	bcs WGPrint_done		; EOL is past the end of the string, so we're done
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

	lda INVERSE
	cmp #CHAR_INVERSE
	beq WGPrint_charLoopInverse
	
WGPrint_charLoopNormal:
	lda	(PARAM0),y			; Draw current character
	beq WGPrint_done
	ora WGPrint_specialMask
	jsr	WGPlot
	iny

	inc WG_CURSORX			; Advance cursors
	inc WG_LOCALCURSORX

	lda WG_LOCALCURSORX
	cmp	WG_SCRATCHA			; Check for wrap boundary
	beq	WGPrint_nextLine
	cmp	WG_VIEWCLIP+2		; Check for right clip plane
	beq	WGPrint_endVisible
	bra WGPrint_charLoopNormal

WGPrint_done:				; This is in the middle here to keep local branches in range
	RESTORE_ZPS
	RESTORE_AXY
	rts

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
	cmp	WG_VIEWRECORDS+8,x		; Check for bottom of view
	beq	WGPrint_done
	lda	(PARAM0),y				; Check for end string landing exactly at line end
	beq	WGPrint_done
	
	lda #0						; Wrap to next line
	sta	WG_LOCALCURSORX
	bra WGPrint_lineLoop

WGPrint_charLoopInverse:
	lda	(PARAM0),y			; Draw current character
	beq WGPrint_done
	cmp #$60
	bcc WGPrint_charLoopInverseLow
	and #%01111111			; Inverse lowercase is in alternate character set
	bra WGPrint_charLoopInversePlot

WGPrint_charLoopInverseLow:
	and WGPrint_setupMaskInverse	; Normal inverse

WGPrint_charLoopInversePlot:
	jsr	WGPlot
	iny

	inc WG_CURSORX			; Advance cursors
	inc WG_LOCALCURSORX

	lda WG_LOCALCURSORX
	cmp	WG_SCRATCHA			; Check for wrap boundary
	beq	WGPrint_nextLine
	cmp	WG_VIEWCLIP+2		; Check for right clip plane
	beq	WGPrint_endVisible
	bra WGPrint_charLoopInverse

WGPrint_specialMask:
	.byte 0
WGPrint_setupMaskInverse:
	.byte 0
