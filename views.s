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
; WGPaintView
; Paints the current view
;
WGPaintView:
	SAVE_AY
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

	jsr WGStrokeRect

WGPaintView_done:
	RESTORE_ZPP
	RESTORE_AY
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
; A: Delta to scroll
; Side effects: Clobbers A
;
WGScrollX:
	phy
	pha
	LDY_ACTIVEVIEW
	pla
	iny
	iny
	iny
	iny
	iny
	clc
	adc	WG_VIEWRECORDS,y
	sta	WG_VIEWRECORDS,y

	jsr	cacheClipPlanes		; Scroll offset changed, so clipping cache is stale

WGScrollX_done:
	ply
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGScrollY
; Scrolls the current view vertically
; A: Delta to scroll
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
	clc
	adc	WG_VIEWRECORDS,y
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


