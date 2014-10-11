;
;  views.s
;  Management routines for GUI views
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCreateView
; Creates and selects a new view
; PARAM0: Pointer to configuration struct (LSB)
; PARAM1: Pointer to configuration struct (MSB)
;
; Configuration struct:
; ID: View ID (0-f)
; ST: Style
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
	lda (PARAM0),y	; Find our new view record
	pha				; Cache view ID so we can select when we're done

	asl
	asl
	asl
	asl				; Records are 8 bytes wide
	tax

	iny
	lda (PARAM0),y
	pha				; Cache style byte for later

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Screen X
	inx

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Screen Y
	inx

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Screen Width
	inx

	iny
	lda (PARAM0),y
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

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; View Width
	inx

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; View Height

	lda #0
	inx						; Initialize state
	sta WG_VIEWRECORDS,x
	inx
	sta WG_VIEWRECORDS,x	; Initialize callback
	inx
	sta WG_VIEWRECORDS,x
	inx
	sta WG_VIEWRECORDS,x	; Initialize title
	inx
	sta WG_VIEWRECORDS,x

	pla
	jsr WGSelectView		; Leave this as the active view

WGCreateView_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCreateCheckbox
; Creates a new checkbox
; PARAM0: Pointer to configuration struct (LSB)
; PARAM1: Pointer to configuration struct (MSB)
;
; Configuration struct:
; ID: View ID (0-f)
; XX: Screen X origin
; YY: Screen Y origin
; SL: String pointer (LSB)
; SH: String pointer (MSB)
;
WGCreateCheckbox:
	SAVE_AXY
	SAVE_ZPS

	ldy #0
	lda (PARAM0),y	; Find our new view record
	pha				; Cache view ID so we can select when we're done

	asl
	asl
	asl
	asl				; Records are 16 bytes wide
	tax

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Screen X
	inx

	iny
	lda (PARAM0),y
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
	inx

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Title
	inx
	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x
	inx

	pla
	jsr WGSelectView		; Leave this as the active view

WGCreateCheckbox_done:
	RESTORE_ZPS
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCreateButton
; Creates a new button
; PARAM0: Pointer to configuration struct (LSB)
; PARAM1: Pointer to configuration struct (MSB)
;
; Configuration struct:
; ID: View ID (0-f)
; XX: Screen X origin
; YY: Screen Y origin
; BW: Button width
; PL: Action callback (LSB)
; PH: Action callback (MSB)
; SL: Title string pointer (LSB)
; SH: Title string pointer (MSB)
WGCreateButton:
	SAVE_AXY
	SAVE_ZPS

	ldy #0
	lda (PARAM0),y	; Find our new view record
	pha				; Cache view ID so we can select when we're done

	asl
	asl
	asl
	asl				; Records are 16 bytes wide
	tax

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Screen X
	inx

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Screen Y
	inx

	iny
	lda (PARAM0),y
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

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Callback
	inx
	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x
	inx

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x	; Title
	inx
	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS,x
	inx

	pla
	jsr WGSelectView		; Leave this as the active view

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
	and #$f					; Mask off flag bits
	sta SCRATCH0

	lda	WG_VIEWRECORDS+0,y	; Fetch the geometry
	sta PARAM0
	lda	WG_VIEWRECORDS+1,y
	sta PARAM1
	lda	WG_VIEWRECORDS+2,y
	sta PARAM2
	lda	WG_VIEWRECORDS+3,y
	sta PARAM3

	lda SCRATCH0					; Draw outline
	cmp #VIEW_STYLE_FANCY
	beq WGPaintView_decorated

	jsr WGStrokeRect

	lda SCRATCH0
	cmp #VIEW_STYLE_CHECK
	beq WGPaintView_check
	cmp #VIEW_STYLE_BUTTON
	beq	WGPaintView_button
	bra WGPaintView_done

WGPaintView_decorated:
	jsr WGFancyRect
	jsr paintWindowTitle
	bra WGPaintView_done
	
WGPaintView_check:
	jsr paintCheck
	bra WGPaintView_done

WGPaintView_button:
	jsr	paintButton

WGPaintView_done:
	RESTORE_ZPS
	RESTORE_ZPP
	RESTORE_AY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; paintCheck
; Paints the contents of a checkbox
; Y: Index into view records of checkbox to paint
; Side effects: Clobbers S0,P0,P1, all registers
paintCheck:
	lda WG_VIEWRECORDS+0,y		; Position cursor
	sta	WG_CURSORX
	lda WG_VIEWRECORDS+1,y
	sta	WG_CURSORY

	lda	WG_VIEWRECORDS+9,y		; Determine our visual state
	and #$80
	bne paintCheck_selected

	lda	WG_VIEWRECORDS+9,y
	and #$01
	beq paintCheck_unselectedUnchecked

	lda #'D'
	bra paintCheck_plot

paintCheck_unselectedUnchecked:
	lda #' '+$80
	bra paintCheck_plot

paintCheck_selected:
	lda	WG_VIEWRECORDS+9,y
	and #$01
	beq paintCheck_selectedUnchecked

	lda #'E'
	bra paintCheck_plot

paintCheck_selectedUnchecked:
	lda #' '

paintCheck_plot:				; Paint our state
	jsr WGPlot

	inc WG_CURSORX				; Prepare for title
	inc WG_CURSORX
	lda #CHAR_NORMAL
	sta INVERSE

	lda WG_VIEWRECORDS+12,y
	sta PARAM0
	lda WG_VIEWRECORDS+13,y
	sta PARAM1
	ldy #0

paintCheck_titleLoop:
	lda (PARAM0),y
	beq paintCheck_done
	ora #$80
	jsr WGPlot
	inc WG_CURSORX
	iny
	bra paintCheck_titleLoop

paintCheck_done:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; paintButton
; Paints the contents of a button
; Y: Index into view records of button to paint
;
paintButton:
	SAVE_AX
	SAVE_ZPS

	lda WG_VIEWRECORDS+12,y	; Prep the title string
	sta PARAM0
	lda WG_VIEWRECORDS+13,y
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
	lda #CHAR_NORMAL
	sta INVERSE
	lda #' '+$80
	bra paintButton_titleMarginLeft

paintButton_titleSelected:
	lda #CHAR_INVERSE
	sta INVERSE
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
; paintWindowTitle
; Paints the title of a fancy window
; Y: Index into view records of view title to paint
;
paintWindowTitle:
	SAVE_AX
	SAVE_ZPS

	lda WG_VIEWRECORDS+12,y	; Prep the title string
	sta PARAM0
	lda WG_VIEWRECORDS+13,y
	sta PARAM1
	bne paintWindowTitle_compute

paintWindowTitle_checkNull:
	lda PARAM0
	beq paintWindowTitle_done

paintWindowTitle_compute:
	jsr WGStrLen			; Compute centering offset for title
	lsr
	sta SCRATCH1
	lda WG_VIEWRECORDS+2,y
	lsr
	sec
	sbc SCRATCH1
	sta	WG_LOCALCURSORX		; Position cursor
	lda #-1
	sta WG_LOCALCURSORY
	jsr WGSyncGlobalCursor

	ldy #0
paintWindowTitleLoop:
	lda (PARAM0),y
	beq paintWindowTitle_done
	ora #%10000000
	jsr	WGPlot				; Draw the character
	iny
	inc WG_CURSORX			; Advance cursors
	bra paintWindowTitleLoop

paintWindowTitle_done:
	RESTORE_ZPS
	RESTORE_AX
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGEraseView
; Erases the current view (including decoration)
;
WGEraseView:
	SAVE_AXY
	SAVE_ZPP

	LDY_ACTIVEVIEW

	lda	WG_VIEWRECORDS+0,y
	dec
	sta PARAM0

	lda	WG_VIEWRECORDS+1,y
	dec
	sta PARAM1

	lda	WG_VIEWRECORDS+2,y
	inc
	inc
	sta PARAM2

	lda	WG_VIEWRECORDS+3,y
	inc
	inc
	sta PARAM3

	ldy	#' '+$80
	jsr WGFillRect

WGEraseView_done:
	RESTORE_ZPP
	RESTORE_AXY
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

	ldy	#' '+$80
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
	sta	WG_ACTIVEVIEW
	pha

	; Initialize cursor to local origin
	lda #0
	sta WG_LOCALCURSORX
	sta WG_LOCALCURSORY

	jsr	cacheClipPlanes		; View changed, so clipping cache is stale

WGSelectView_done:
	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFocus
; Shifts focus to the selected view
; Side effects: Changes selected view, repaints some views
;
WGViewFocus:
	SAVE_AY

	lda WG_ACTIVEVIEW			; Stash current selection
	pha

	lda WG_FOCUSVIEW
	bmi WGViewFocus_noCurrent

	LDY_FOCUSVIEW				; Unfocus current view
	lda WG_VIEWRECORDS+9,y
	and #%01111111
	sta WG_VIEWRECORDS+9,y

	lda WG_FOCUSVIEW
	jsr WGSelectView
	jsr WGPaintView

WGViewFocus_noCurrent:
	pla
	sta WG_FOCUSVIEW			; Focus on our original selection
	jsr WGSelectView

	LDY_FOCUSVIEW

	lda WG_VIEWRECORDS+9,y		; Change state and repaint to reflect it
	ora #%10000000
	sta WG_VIEWRECORDS+9,y

	jsr WGPaintView

	RESTORE_AY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewUnfocus
; Unfocuses all views
; Side effects: Changes selected view, repaints some views
;
WGViewUnfocus:
	pha

	lda WG_FOCUSVIEW
	bmi WGViewUnfocus_done

	LDY_FOCUSVIEW				; Unfocus current view
	lda WG_VIEWRECORDS+9,y
	and #%01111111
	sta WG_VIEWRECORDS+9,y

	lda WG_FOCUSVIEW
	jsr WGSelectView
	jsr WGPaintView

	lda #$ff
	sta WG_FOCUSVIEW

WGViewUnfocus_done:
	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFocusNext
; Shifts focus to the next view
; Side effects: Changes selected view, repaints some views
;
WGViewFocusNext:
	SAVE_AY

	lda WG_FOCUSVIEW
	bmi WGViewFocusNext_loop

	LDY_FOCUSVIEW				; Unfocus current view
	lda WG_VIEWRECORDS+9,y
	and #%01111111
	sta WG_VIEWRECORDS+9,y

	lda WG_FOCUSVIEW
	jsr WGSelectView
	jsr WGPaintView

WGViewFocusNext_loop:
	inc	WG_FOCUSVIEW			; Increment and wrap
	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+2,y
	bne WGViewFocusNext_wantFocus
	lda #0
	sta	WG_FOCUSVIEW

WGViewFocusNext_wantFocus:		; Does this view accept focus?
	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+4,y
	and #$f						; Mask off flag bits
	cmp #VIEW_STYLE_TAKESFOCUS
	bcc WGViewFocusNext_loop

WGViewFocusNext_focus:
	lda	WG_FOCUSVIEW			; Change state and repaint to reflect it
	jsr WGSelectView

	lda WG_VIEWRECORDS+9,y
	ora #%10000000
	sta WG_VIEWRECORDS+9,y

	jsr WGPaintView

	RESTORE_AY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFocusPrev
; Shifts focus to the prev view
; Side effects: Changes selected view, repaints some views
;
WGViewFocusPrev:
	SAVE_AXY

	lda WG_FOCUSVIEW
	bmi WGViewFocusPrev_hadNone

	LDY_FOCUSVIEW				; Unfocus current view
	lda WG_VIEWRECORDS+9,y
	and #%01111111
	sta WG_VIEWRECORDS+9,y

	lda WG_FOCUSVIEW
	jsr WGSelectView
	jsr WGPaintView

WGViewFocusPrev_loop:
	dec	WG_FOCUSVIEW			; Decrement and wrap
	bpl WGViewFocusPrev_wantFocus

WGViewFocusPrev_hadNone:
	ldx #$f
WGViewFocusPrev_findEndLoop:
	stx WG_FOCUSVIEW
	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+2,y
	bne WGViewFocusPrev_wantFocus
	dex
	bra WGViewFocusPrev_findEndLoop

WGViewFocusPrev_wantFocus:		; Does this view accept focus?
	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+4,y
	and #$f						; Mask off flag bits
	cmp #VIEW_STYLE_TAKESFOCUS
	bcc WGViewFocusPrev_loop

WGViewFocusPrev_focus:
	lda	WG_FOCUSVIEW			; Change state and repaint to reflect it
	jsr WGSelectView

	LDY_FOCUSVIEW

	lda WG_VIEWRECORDS+9,y
	ora #%10000000
	sta WG_VIEWRECORDS+9,y

	jsr WGPaintView

	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFocusAction
; Performs the action of the focused view
; WG_GOSUB : Set if the caller should perform an Applesoft GOSUB
; Side effects: Changes selected view, Repaints some views
;
WGViewFocusAction:
	SAVE_AY

	lda WG_FOCUSVIEW
	bmi WGViewFocusAction_done

	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+4,y		; What kind of view is it?
	and #$f						; Mask off flag bits

	cmp #VIEW_STYLE_CHECK
	beq WGViewFocusAction_toggleCheckbox
	cmp #VIEW_STYLE_BUTTON
	beq WGViewFocusAction_buttonClick

	bra WGViewFocusAction_done

WGViewFocusAction_toggleCheckbox:
	lda WG_VIEWRECORDS+9,y		; Change the checkbox's state and redraw
	eor #%00000001
	sta WG_VIEWRECORDS+9,y
	lda WG_FOCUSVIEW
	jsr WGSelectView
	jsr WGPaintView
	; Fall through so checkboxes can have callbacks too

	; NOTE: Self-modifying code ahead!
WGViewFocusAction_buttonClick:
	lda WG_VIEWRECORDS+4,y				; Are we an Applesoft button?
	and #VIEW_STYLE_APPLESOFT
	bne WGViewFocusAction_buttonClickApplesoft

	lda WG_VIEWRECORDS+11,y				; Do we have a callback?
	beq WGViewFocusAction_done
	sta WGViewFocusAction_userJSR+2		; Modify code below so we can JSR to user's code
	lda WG_VIEWRECORDS+10,y
	sta WGViewFocusAction_userJSR+1

WGViewFocusAction_userJSR:
	jsr WGViewFocusAction_done			; Overwritten with user's function pointer
	bra WGViewFocusAction_done

WGViewFocusAction_buttonClickApplesoft:
	lda #0
	sta WG_GOSUB
	lda WG_VIEWRECORDS+10,y				; Do we have a callback?
	beq WGViewFocusAction_mightBeZero

WGViewFocusAction_buttonClickApplesoftNotZero:
	sta PARAM0
	lda WG_VIEWRECORDS+11,y
	sta PARAM1

WGViewFocusAction_buttonClickApplesoftGosub:
	; Caller needs to handle Applesoft Gosub, so signal with a flag and return
	lda #1
	sta WG_GOSUB
	bra WGViewFocusAction_done

WGViewFocusAction_mightBeZero:
	lda WG_VIEWRECORDS+11,y
	beq WGViewFocusAction_done
	lda WG_VIEWRECORDS+10,y
	bra WGViewFocusAction_buttonClickApplesoftNotZero

WGViewFocusAction_done:
	RESTORE_AY
WGViewFocusAction_knownRTS:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPendingViewAction
; Performs the action of the pending view, if any
; Global flag set if the caller should perform an Applesoft GOSUB
; Side effects: Changes selected view, Repaints some views
;
WGPendingViewAction:
	pha
	lda WG_PENDINGACTIONVIEW
	bmi WGPendingViewAction_done

	jsr WGUndrawPointer
	
	jsr WGSelectView
	jsr WGViewFocus
	jsr WGViewFocusAction
	jsr delayShort
	jsr WGViewUnfocus

	jsr WGDrawPointer		; Leave pointer hidden, but ensure
	jsr WGUndrawPointer		; Background is correct when it moves next

	lda #$ff
	sta WG_PENDINGACTIONVIEW

WGPendingViewAction_done:
	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPendingView
; Returns the view that is currently pending
; OUT A : Pending view ID, or $ff if none
;
WGPendingView:
	lda WG_PENDINGACTIONVIEW
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
	sta WG_VIEWRECORDS+12,y
	lda PARAM1
	sta WG_VIEWRECORDS+13,y

WGViewSetTitle_done:
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewSetAction
; Sets the callback action of the active view
; PARAM0: Null-terminated function pointer (LSB)
; PARAM1: Null-terminated function pointer (MSB)
WGViewSetAction:
	SAVE_AY

	LDY_ACTIVEVIEW
	lda PARAM0
	sta WG_VIEWRECORDS+10,y
	lda PARAM1
	sta WG_VIEWRECORDS+11,y

WGViewSetAction_done:
	RESTORE_AY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSetCursor
; Sets the current local view cursor
; PARAM0: X
; PARAM1: Y
;
WGSetCursor:
	pha

	lda PARAM0
	sta	WG_LOCALCURSORX
	lda PARAM1
	sta	WG_LOCALCURSORY

	pla
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSetGlobalCursor
; Sets the current global cursor
; PARAM0: X
; PARAM1: Y
;
WGSetGlobalCursor:
	pha

	lda PARAM0
	sta	WG_CURSORX
	lda PARAM1
	sta	WG_CURSORY

	pla
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
; WGScrollXBy
; Scrolls the current view horizontally by a delta
; A: Scroll delta
; Side effects: Clobbers A
;
WGScrollXBy:
	phy
	phx
	tax

	SAVE_ZPS

	LDY_ACTIVEVIEW

	txa
	bpl WGScrollXBy_contentRight

	lda WG_VIEWRECORDS+2,y	; Compute left limit
	sec
	sbc WG_VIEWRECORDS+7,y
	sta SCRATCH0

	txa						; Compute new scroll value
	clc
	adc WG_VIEWRECORDS+5,y
	cmp SCRATCH0				; Clamp if needed
	bmi WGScrollXBy_clampLeft
	sta WG_VIEWRECORDS+5,y
	bra WGScrollXBy_done

WGScrollXBy_clampLeft:
	lda SCRATCH0
	sta WG_VIEWRECORDS+5,y
	bra WGScrollXBy_done

WGScrollXBy_contentRight:
	clc						; Compute new scroll value
	adc WG_VIEWRECORDS+5,y
	cmp #0					; Clamp if needed
	beq @0
	bpl WGScrollXBy_clampRight
@0:	sta WG_VIEWRECORDS+5,y
	bra WGScrollXBy_done

WGScrollXBy_clampRight:
	lda #0
	sta WG_VIEWRECORDS+5,y

WGScrollXBy_done:
	RESTORE_ZPS
	plx
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
; WGScrollYBy
; Scrolls the current view horizontally by a delta
; A: Scroll delta
; Side effects: Clobbers A
;
WGScrollYBy:
	phy
	phx
	tax

	SAVE_ZPS

	LDY_ACTIVEVIEW

	txa
	bpl WGScrollYBy_contentDown

	lda WG_VIEWRECORDS+3,y	; Compute bottom limit
	sec
	sbc WG_VIEWRECORDS+8,y
	sta SCRATCH0

	txa						; Compute new scroll value
	clc
	adc WG_VIEWRECORDS+6,y
	cmp SCRATCH0				; Clamp if needed
	bmi WGScrollYBy_clampTop
	sta WG_VIEWRECORDS+6,y
	bra WGScrollYBy_done

WGScrollYBy_clampTop:
	lda SCRATCH0
	sta WG_VIEWRECORDS+6,y
	bra WGScrollYBy_done

WGScrollYBy_contentDown:
	clc						; Compute new scroll value
	adc WG_VIEWRECORDS+6,y
	cmp #0					; Clamp if needed
	beq @0
	bpl WGScrollYBy_clampBottom
@0:	sta WG_VIEWRECORDS+6,y
	bra WGScrollYBy_done

WGScrollYBy_clampBottom:
	lda #0
	sta WG_VIEWRECORDS+6,y

WGScrollYBy_done:
	RESTORE_ZPS
	plx
	ply
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewPaintAll
; Repaints all views
; Side effects: Changes selected view
;
WGViewPaintAll:
	SAVE_AXY

	ldx #0

WGViewPaintAll_loop:
	txa
	jsr WGSelectView

	LDY_ACTIVEVIEW
	lda WG_VIEWRECORDS+2,y		; Last view?
	beq WGViewPaintAll_done

	jsr WGEraseViewContents
	jsr WGPaintView
	inx
	bra WGViewPaintAll_loop

WGViewPaintAll_done:
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFromPoint
; Finds a view containing the given point
; PARAM0:X
; PARAM1:Y
; OUT A: View ID (or $ff if no match)
WGViewFromPoint:
	SAVE_XY

	ldx #$f		; Scan views backwards, because controls are usually at the end

WGViewFromPoint_loop:
	txa
	LDY_AVIEW

	lda WG_VIEWRECORDS+2,y
	beq WGViewFromPoint_loopNext	; Not an allocated view

	lda PARAM0						; Check left edge
	cmp WG_VIEWRECORDS+0,y
	bcc WGViewFromPoint_loopNext

	lda PARAM1						; Check top edge
	cmp WG_VIEWRECORDS+1,y
	bcc WGViewFromPoint_loopNext

	lda WG_VIEWRECORDS+0,y			; Check right edge
	clc
	adc WG_VIEWRECORDS+2,y
	cmp PARAM0
	bcc WGViewFromPoint_loopNext
	beq WGViewFromPoint_loopNext

	lda WG_VIEWRECORDS+1,y			; Check bottom edge
	clc
	adc WG_VIEWRECORDS+3,y
	cmp PARAM1
	bcc WGViewFromPoint_loopNext
	beq WGViewFromPoint_loopNext

	txa								; Found a match
	RESTORE_XY
	rts

WGViewFromPoint_loopNext:
	dex
	bmi WGViewFromPoint_noMatch
	bra WGViewFromPoint_loop

WGViewFromPoint_noMatch:
	lda #$ff
	RESTORE_XY
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


