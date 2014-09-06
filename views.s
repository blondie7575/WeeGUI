;
;  views.s
;  Management routines for GUI views
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCreateView
; Creates a new view
; PARAM0: Pointer to ASCII configuration string (LSB)
; PARAM1: Pointer to ASCII configuration string (MSB)
;
; Configuration string: "STXXYYSWSHVWVH"
; ST: (4:4) Style:ID
; XX: Screen X origin
; YY: Screen Y origin
; SW: Screen width
; SH: Screen height
; VW: View Width
; VH: View Height
;
WGCreateView:
	SAVE_AXY
	SAVE_ZPS

	ldy #0
	jsr	scanHex8
	pha

	and #%00001111	; Find our new view record
	asl
	asl
	asl
	asl				; Records are 8 bytes wide
	tax

	pla				; Cache style nybble for later
	lsr
	lsr
	lsr
	lsr
	pha

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen X
	inx

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen Y
	inx

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen Width
	inx

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen Height
	inx

	pla
	sta	WG_VIEWRECORDS,x	; Style
	inx

	lda	#0					; Initialize scrolling
	sta	WG_VIEWRECORDS,x
	inx
	sta	WG_VIEWRECORDS,x
	inx

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; View Width
	inx

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; View Height

WGCreateView_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCreateCheckbox
; Creates a new checkbox
; PARAM0: Pointer to ASCII configuration string (LSB)
; PARAM1: Pointer to ASCII configuration string (MSB)
;
; Configuration string: "STXXYY"
; ST: (4:4) Reserved:ID
; XX: Screen X origin
; YY: Screen Y origin
;
WGCreateCheckbox:
	SAVE_AXY
	SAVE_ZPS

	ldy #0
	jsr	scanHex8

	and #%00001111	; Find our new view record
	asl
	asl
	asl
	asl				; Records are 8 bytes wide
	tax

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen X
	inx

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen Y
	inx

	lda	#1
	sta	WG_VIEWRECORDS,x	; Initialize screen width
	inx
	sta	WG_VIEWRECORDS,x	; Initialize screen height
	inx

	lda #VIEW_STYLE_CHECK
	sta	WG_VIEWRECORDS,x	; Style
	inx

	lda	#0					; Initialize scrolling
	sta	WG_VIEWRECORDS,x
	inx
	sta	WG_VIEWRECORDS,x
	inx

	lda	#0
	sta	WG_VIEWRECORDS,x	; Initialize view width
	inx
	sta	WG_VIEWRECORDS,x	; Initialize view height
	inx

	lda	#%00000000			; Initialize state
	sta	WG_VIEWRECORDS,x
	inx
	sta	WG_VIEWRECORDS,x	; Initialize callback
	inx
	sta	WG_VIEWRECORDS,x

WGCreateCheckbox_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCreateButton
; Creates a new button
; PARAM0: Pointer to ASCII configuration string (LSB)
; PARAM1: Pointer to ASCII configuration string (MSB)
;
; Configuration string: "STXXYYBW"
; ST: (4:4) Reserved:ID
; XX: Screen X origin
; YY: Screen Y origin
; BW: Button width
WGCreateButton:
	SAVE_AXY
	SAVE_ZPS

	ldy #0
	jsr	scanHex8

	and #%00001111	; Find our new view record
	asl
	asl
	asl
	asl				; Records are 8 bytes wide
	tax

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen X
	inx

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen Y
	inx

	jsr	scanHex8
	sta	WG_VIEWRECORDS,x	; Screen width
	inx

	lda #1
	sta	WG_VIEWRECORDS,x	; Initialize screen height
	inx

	lda #VIEW_STYLE_BUTTON
	sta	WG_VIEWRECORDS,x	; Style
	inx

	lda	#0					; Initialize scrolling
	sta	WG_VIEWRECORDS,x
	inx
	sta	WG_VIEWRECORDS,x
	inx

	lda	#0
	sta	WG_VIEWRECORDS,x	; Initialize view width
	inx
	sta	WG_VIEWRECORDS,x	; Initialize view height
	inx

	lda	#%00000000			; Initialize state
	sta	WG_VIEWRECORDS,x
	inx
	sta	WG_VIEWRECORDS,x	; Initialize callback
	inx
	sta	WG_VIEWRECORDS,x
	inx

	lda	#0
	sta	WG_VIEWRECORDS,x	; Initialize title
	inx
	sta	WG_VIEWRECORDS,x	; Initialize title

WGCreateButton_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPaintView
; Paints the current view
;
WGPaintView:
	SAVE_AY
	SAVE_ZPP
	SAVE_ZPS

	LDY_ACTIVEVIEW
	lda WG_VIEWRECORDS+4,y	; Cache style information
	sta SCRATCH0

	lda	WG_VIEWRECORDS+0,y	; Fetch the geometry
	sta PARAM0
	lda	WG_VIEWRECORDS+1,y
	sta PARAM1
	lda	WG_VIEWRECORDS+2,y
	sta PARAM2
	lda	WG_VIEWRECORDS+3,y
	sta PARAM3

	jsr WGStrokeRect		; Draw outline

	lda SCRATCH0
	cmp #VIEW_STYLE_CHECK
	beq WGPaintView_check
	cmp #VIEW_STYLE_BUTTON
	beq	WGPaintView_button
	bra WGPaintView_done

WGPaintView_check:
	lda	WG_VIEWRECORDS+9,y	; Render checkbox state
	beq WGPaintView_done

	lda WG_VIEWRECORDS+0,y
	sta	WG_CURSORX
	lda WG_VIEWRECORDS+1,y
	sta	WG_CURSORY
	lda WG_VIEWRECORDS+9,y
	and #$80
	bne WGPaintView_checkSelected
	lda #'D'
	bra WGPaintView_checkPlot

WGPaintView_checkSelected:
	lda #'E'

WGPaintView_checkPlot:
	jsr WGPlot
	bra WGPaintView_done

WGPaintView_button:
	jsr	paintButton

WGPaintView_done:
	RESTORE_ZPS
	RESTORE_ZPP
	RESTORE_AY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; paintButton
; Paints the contents of a button
; Y: Index into view records of button to paint
;
paintButton:
	SAVE_AX
	SAVE_ZPS

	lda WG_VIEWRECORDS+13,y	; Prep the title string
	sta PARAM0
	lda WG_VIEWRECORDS+12,y
	sta PARAM1

	jsr WGStrLen			; Compute centering offset for title
	lsr
	sta SCRATCH1
	lda WG_VIEWRECORDS+2,y
	lsr
	sec
	sbc SCRATCH1
	sta SCRATCH1			; Cache this for left margin rendering

	lda #0					; Position and print title
	sta	WG_LOCALCURSORX
	lda #0
	sta	WG_LOCALCURSORY
	jsr WGSyncGlobalCursor

	lda WG_VIEWRECORDS+9,y	; Is button highlighted?
	and #$80
	bne paintButton_titleSelected
	jsr WGNormal
	lda #' '+$80
	bra paintButton_titleMarginLeft

paintButton_titleSelected:
	jsr WGInverse
	lda #' '

paintButton_titleMarginLeft:
	ldx #0

paintButton_titleMarginLeftLoop:
	cpx	SCRATCH1
	bcs paintButton_title	; Left margin finished
	jsr WGPlot
	inc WG_CURSORX
	inc WG_LOCALCURSORX
	inx
	jmp paintButton_titleMarginLeftLoop

paintButton_title:
	jsr WGPrint
	ldx WG_VIEWRECORDS+2,y
	stx SCRATCH1			; Loop until right edge of button is reached
	ldx WG_LOCALCURSORX

paintButton_titleMarginRightLoop:
	cpx	SCRATCH1
	bcs paintButton_done	; Right margin finished
	jsr WGPlot
	inc WG_CURSORX
	inc WG_LOCALCURSORX
	inx
	jmp paintButton_titleMarginRightLoop

paintButton_done:
	RESTORE_ZPS
	RESTORE_AX
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGEraseView
; Erases the current view (including decoration)
;
WGEraseView:
	SAVE_AY
	SAVE_ZPP

	LDY_ACTIVEVIEW

	lda	WG_VIEWRECORDS,y	; Fetch the record
	dec
	sta PARAM0
	iny
	lda	WG_VIEWRECORDS,y
	dec
	sta PARAM1
	iny
	lda	WG_VIEWRECORDS,y
	inc
	inc
	sta PARAM2
	iny
	lda	WG_VIEWRECORDS,y
	inc
	inc
	sta PARAM3

	ldx	#' '+$80
	jsr WGFillRect

WGEraseView_done:
	RESTORE_ZPP
	RESTORE_AY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGEraseViewContents
; Erases the contents of the current view (interior contents only)
;
WGEraseViewContents:
	SAVE_AXY
	SAVE_ZPP

	LDY_ACTIVEVIEW

	lda	WG_VIEWRECORDS,y	; Fetch the record
	sta PARAM0
	iny
	lda	WG_VIEWRECORDS,y
	sta PARAM1
	iny
	lda	WG_VIEWRECORDS,y
	sta PARAM2
	iny
	lda	WG_VIEWRECORDS,y
	sta PARAM3

	ldx	#' '+$80
	jsr WGFillRect

WGEraseViewContents_done:
	RESTORE_ZPP
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSelectView
; Selects the active view
; A: ID
;
WGSelectView:
	SAVE_AXY
	sta	WG_ACTIVEVIEW

	; Initialize cursor to local origin
	lda #0
	sta WG_LOCALCURSORX
	sta WG_LOCALCURSORY

	jsr	cacheClipPlanes		; View changed, so clipping cache is stale

WGSelectView_done:
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewSetTitle
; Sets the title of the active view
; PARAM0: Null-terminated string pointer (LSB)
; PARAM1: Null-terminated string pointer (MSB)
WGViewSetTitle:
	SAVE_AXY

	LDY_ACTIVEVIEW
	lda PARAM0
	sta WG_VIEWRECORDS+13,y
	lda PARAM1
	sta WG_VIEWRECORDS+12,y

WGViewSetTitle_done:
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSetCursor
; Sets the current local view cursor
; X: X
; Y: Y
;
WGSetCursor:
	stx	WG_LOCALCURSORX
	sty	WG_LOCALCURSORY
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSyncGlobalCursor
; Synchronizes the global cursor with the current local view's
; cursor
;
WGSyncGlobalCursor:
	SAVE_AY

	; X
	LDY_ACTIVEVIEW

	clc						; Transform to viewspace
	lda WG_LOCALCURSORX
	adc	WG_VIEWRECORDS,y

	iny
	iny
	iny
	iny
	iny
	clc
	adc	WG_VIEWRECORDS,y	; Transform to scrollspace
	sta WG_CURSORX

	; Y
	LDY_ACTIVEVIEW
	iny

	clc						; Transform to viewspace
	lda WG_LOCALCURSORY
	adc	WG_VIEWRECORDS,y

	iny
	iny
	iny
	iny
	iny
	clc
	adc	WG_VIEWRECORDS,y	; Transform to scrollspace
	sta WG_CURSORY

WGSyncGlobalCursor_done:
	RESTORE_AY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGScrollX
; Scrolls the current view horizontally
; A: New scroll amount
; Side effects: Clobbers A
;
WGScrollX:
	phy
	pha
	LDY_ACTIVEVIEW
	iny
	iny
	iny
	iny
	iny
	pla
	sta	WG_VIEWRECORDS,y
	jsr	cacheClipPlanes		; Scroll offset changed, so clipping cache is stale

WGScrollX_done:
	ply
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGScrollY
; Scrolls the current view vertically
; A: New scroll amount
; Side effects: Clobbers A
;
WGScrollY:
	phy
	pha
	LDY_ACTIVEVIEW
	pla
	iny
	iny
	iny
	iny
	iny
	iny
	sta	WG_VIEWRECORDS,y

	jsr	cacheClipPlanes		; Scroll offset changed, so clipping cache is stale

WGScrollY_done:
	ply
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; cacheClipPlanes
; Internal routine to cache the clipping planes for the view
;
cacheClipPlanes:
	SAVE_AY

	; Compute clip planes in view space
	LDY_ACTIVEVIEW

	iny						; Left edge
	iny
	iny
	iny
	iny
	lda	WG_VIEWRECORDS,y
	eor #$ff
	inc
	sta	WG_VIEWCLIP+0

	dey						; Right edge
	dey
	dey
	clc
	adc	WG_VIEWRECORDS,y
	sta	WG_VIEWCLIP+2

	iny						; Right span (distance from window edge to view edge, in viewspace
	iny
	iny
	iny
	iny
	lda	WG_VIEWRECORDS,y
	sec
	sbc	WG_VIEWCLIP+2
	sta	WG_VIEWCLIP+4
	
	dey						; Top edge
	lda	WG_VIEWRECORDS,y
	eor #$ff
	inc
	sta	WG_VIEWCLIP+1

	dey						; Bottom edge
	dey
	dey
	clc
	adc	WG_VIEWRECORDS,y
	sta	WG_VIEWCLIP+3

	RESTORE_AY
	rts


