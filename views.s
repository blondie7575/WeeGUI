;
;  views.s
;  Management routines for GUI views
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


WG_FEATURE_UP = %00010000
WG_FEATURE_DN = %00100000
WG_FEATURE_LF = %00110000
WG_FEATURE_RT = %01000000


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
	sta	WG_VIEWRECORDS+0,x	; Screen X

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+1,x	; Screen Y

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+2,x	; Screen Width

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+3,x	; Screen Height

	pla
	sta	WG_VIEWRECORDS+4,x	; Style

	stz	WG_VIEWRECORDS+5,x	; Initialize scrolling
	stz	WG_VIEWRECORDS+6,x

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+7,x	; View Width

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+8,x	; View Height

	stz WG_VIEWRECORDS+9,x	; Initialize state
	stz WG_VIEWRECORDS+10,x	; Initialize callback
	stz WG_VIEWRECORDS+11,x
	stz WG_VIEWRECORDS+12,x	; Initialize title
	stz WG_VIEWRECORDS+13,x

	pla
	jsr WGSelectView		; Leave this as the active view

WGCreateView_done:
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
	sta	WG_VIEWRECORDS+0,x	; Screen X

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+1,x	; Screen Y

	lda	#1
	sta	WG_VIEWRECORDS+2,x	; Initialize screen width
	sta	WG_VIEWRECORDS+3,x	; Initialize screen height
	sta	WG_VIEWRECORDS+7,x	; Initialize view width
	sta	WG_VIEWRECORDS+8,x	; Initialize view height

	lda #VIEW_STYLE_CHECK
	sta	WG_VIEWRECORDS+4,x	; Style

	stz	WG_VIEWRECORDS+5,x	; Initialize scrolling
	stz	WG_VIEWRECORDS+6,x

	stz WG_VIEWRECORDS+9,x	; Initialize state
	stz WG_VIEWRECORDS+10,x	; Initialize callback
	stz WG_VIEWRECORDS+11,x

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+12,x	; Title
	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+13,x

	pla
	jsr WGSelectView		; Leave this as the active view

WGCreateCheckbox_done:
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCreateProgress
; Creates a new progress bar
; PARAM0: Pointer to configuration struct (LSB)
; PARAM1: Pointer to configuration struct (MSB)
;
; Configuration struct:
; ID: View ID (0-f)
; XX: Screen X origin
; YY: Screen Y origin
; PW: Progress width
;
WGCreateProgress:
	SAVE_AXY

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
	sta	WG_VIEWRECORDS+0,x	; Screen X

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+1,x	; Screen Y

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+2,x	; Screen width
	sta	WG_VIEWRECORDS+7,x	; View width

	lda	#1
	sta	WG_VIEWRECORDS+3,x	; Screen height
	sta	WG_VIEWRECORDS+8,x	; View height

	lda #VIEW_STYLE_PROGRESS
	sta	WG_VIEWRECORDS+4,x	; Style

	stz	WG_VIEWRECORDS+5,x	; Initialize scrolling
	stz	WG_VIEWRECORDS+6,x

	stz WG_VIEWRECORDS+9,x	; Initialize state
	stz WG_VIEWRECORDS+10,x	; Initialize callback
	stz WG_VIEWRECORDS+11,x

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+12,x	; Title
	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+13,x

	pla
	jsr WGSelectView		; Leave this as the active view

WGCreateProgress_done:
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSetState
; Sets state field in view record
; PARAM0: Value
;
WGSetState:
	SAVE_AXY

	LDY_ACTIVEVIEW

	lda WG_VIEWRECORDS+9,y
	and #$80
	sta SCRATCH0
	lda PARAM0
	and #$7F
	ora	SCRATCH0
	sta	WG_VIEWRECORDS+9,y	; State (preserving bit 7)

WGSetState_done:
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
	sta	WG_VIEWRECORDS+0,x	; Screen X

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+1,x	; Screen Y

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+2,x	; Screen width
	sta	WG_VIEWRECORDS+7,x	; View width

	lda #1
	sta	WG_VIEWRECORDS+3,x	; Initialize screen height
	sta	WG_VIEWRECORDS+8,x	; Initialize view height

	lda #VIEW_STYLE_BUTTON
	sta	WG_VIEWRECORDS+4,x	; Style

	stz	WG_VIEWRECORDS+5,x	; Initialize scrolling
	stz	WG_VIEWRECORDS+6,x
	stz WG_VIEWRECORDS+9,x	; Initialize state

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+10,x	; Callback
	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+11,x

	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+12,x	; Title
	iny
	lda (PARAM0),y
	sta	WG_VIEWRECORDS+13,x

	pla
	jsr WGSelectView		; Leave this as the active view

WGCreateButton_done:
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDeleteView
; Deletes the current view and removes it from the screen
;
WGDeleteView:
	SAVE_AY

	LDY_ACTIVEVIEW
	lda WG_VIEWRECORDS+2,y
	beq WGDeleteView_done	; Not an allocated view

	jsr WGEraseView

	lda #0
	sta WG_VIEWRECORDS+2,y	; 0 width indicates unused view
	jsr WGViewPaintAll

WGDeleteView_done:
	RESTORE_AY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPaintView
; Paints the current view
;
WGPaintView:
	SAVE_AXY
	SAVE_ZPP

	LDY_ACTIVEVIEW

	lda WG_VIEWRECORDS+4,y	; Cache style information
	and #$f					; Mask off flag bits
	beq WGPaintView_done	; If it's a stealth view, we're done
	pha

	lda	WG_VIEWRECORDS+0,y	; Fetch the geometry
	sta PARAM0
	lda	WG_VIEWRECORDS+1,y
	sta PARAM1
	lda	WG_VIEWRECORDS+2,y
	sta PARAM2
	lda	WG_VIEWRECORDS+3,y
	sta PARAM3

	pla						; Draw outline
	cmp #VIEW_STYLE_FANCY
	beq WGPaintView_decorated

	jsr WGStrokeRect

	cmp #VIEW_STYLE_CHECK
	beq WGPaintView_check
	cmp #VIEW_STYLE_BUTTON
	beq	WGPaintView_button
	cmp #VIEW_STYLE_PROGRESS
	beq WGPaintView_progress
	bra WGPaintView_done

WGPaintView_decorated:
	jsr WGFancyRect
	jsr paintWindowTitle
	bra WGPaintView_done
	
WGPaintView_check:
	jsr paintCheck
	bra WGPaintView_done

WGPaintView_progress:
	jsr paintProgress
	bra WGPaintView_done

WGPaintView_button:
	jsr	paintButton

WGPaintView_done:
	jsr WGPointerDirty		; The pointer BG may now be stale

	RESTORE_ZPP
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; paintCheck
; Paints the contents of a checkbox
; Y: Index into view records of checkbox to paint
; Side effects: Clobbers all registers,P0,P1
paintCheck:
	lda WG_VIEWRECORDS+0,y		; Position cursor
	sta	WG_CURSORX
	lda WG_VIEWRECORDS+1,y
	sta	WG_CURSORY

	lda	WG_VIEWRECORDS+9,y		; Determine our visual state
	and #$80
	bne paintCheck_selected

	lda	WG_VIEWRECORDS+9,y
	ror
	bcc paintCheck_unselectedUnchecked

	lda #'D'
	bra paintCheck_plot

paintCheck_unselectedUnchecked:
	lda #' '+$80
	bra paintCheck_plot

paintCheck_selected:
	lda	WG_VIEWRECORDS+9,y
	ror
	bcc paintCheck_selectedUnchecked

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

	lda WG_VIEWRECORDS+4,y			; Raw or Apple format title?
	and #VIEW_STYLE_RAWTITLE
	bne paintCheck_titleRawLoop

paintCheck_titleLoop:
	lda (PARAM0),y
	beq paintCheck_done
	ora #$80
	jsr WGPlot
	inc WG_CURSORX
	iny
	bra paintCheck_titleLoop

paintCheck_titleRawLoop:
	lda (PARAM0),y
	beq paintCheck_done
	jsr WGPlot
	inc WG_CURSORX
	iny
	bra paintCheck_titleLoop

paintCheck_done:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; paintProgress
; Paints the contents of a progress bar
; Y: Index into view records of progress bar to paint
; Side effects: Clobbers all registers,P0,P1
paintProgress:
	lda WG_VIEWRECORDS+1,y		; Top edge
	sta	PARAM1

	lda #1
	sta PARAM3

	lda	WG_VIEWRECORDS+9,y		; Progress value as width
	sta PARAM2
	beq paintProgress_noFill	; skip if nothing to draw

	lda WG_VIEWRECORDS+0,y		; Left edge
	sta PARAM0
	phy
	ldy #$20					; inverse space
	jsr WGFillRect
	ply

paintProgress_noFill:
	lda WG_VIEWRECORDS+2,y		; full width
	sec
	sbc WG_VIEWRECORDS+9,y		; Progress value
	beq paintProgress_done		; skip if nothing to draw
	sta PARAM2

	lda WG_VIEWRECORDS+0,y		; left edge
	clc
	adc WG_VIEWRECORDS+9,y		; Progress value
	sta PARAM0

	ldy #$A0					; space
	jsr WGFillRect

paintProgress_done:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; paintButton
; Paints the contents of a button
; Y: Index into view records of button to paint
; Side effects: Clobbers all registers,P0,P1,S1
paintButton:
	lda INVERSE			; Preserve INVERSE state during this
	pha

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
	pha
	lda WG_VIEWRECORDS+4,y			; Raw or Apple format title?
	and #VIEW_STYLE_RAWTITLE
	beq paintButton_titleApple
	bit paintButton_doneRTS		; Set overflow

paintButton_titleApple:
	pla
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
	pla						; Restore inverse state
	sta INVERSE

paintButton_doneRTS:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; paintWindowTitle
; Paints the title of a fancy window
; Y: Index into view records of view title to paint
; Side effects: Clobbers all registers,P0,P1,S1
paintWindowTitle:
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
	clc
	adc WG_VIEWRECORDS+0,y
	sta	WG_CURSORX		; Position cursor
	lda WG_VIEWRECORDS+1,y
	dec
	sta WG_CURSORY

	ldy #0

	lda WG_VIEWRECORDS+4,y			; Raw or Apple format title?
	and #VIEW_STYLE_RAWTITLE
	bne paintWindowTitleRawLoop

paintWindowTitleLoop:
	lda (PARAM0),y
	beq paintWindowTitle_done
	ora #$80
	jsr	WGPlot				; Draw the character
	iny
	inc WG_CURSORX			; Advance cursors
	bra paintWindowTitleLoop

paintWindowTitleRawLoop:
	lda (PARAM0),y
	beq paintWindowTitle_done
	jsr	WGPlot				; Draw the character
	iny
	inc WG_CURSORX			; Advance cursors
	bra paintWindowTitleRawLoop

paintWindowTitle_done:
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

	ldy	#' '+$80
	jsr WGFillRect

WGEraseViewContents_done:
	RESTORE_ZPP
	RESTORE_AY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSelectView
; Selects the active view
; A: ID
;
WGSelectView:
	sta	WG_ACTIVEVIEW

	; Initialize cursor to local origin
	stz WG_LOCALCURSORX
	stz WG_LOCALCURSORY

	jsr	cacheClipPlanes		; View changed, so clipping cache is stale

WGSelectView_done:
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

	jsr unfocusCurrent

	pla
	sta WG_FOCUSVIEW			; Focus on our current selection
	jsr focusCurrent

	RESTORE_AY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFocusQuiet
; Shifts focus to the selected view without redrawing anything
; Side effects: Changes selected view, repaints some views
;
WGViewFocusQuiet:
	pha

	lda WG_ACTIVEVIEW			; Stash current selection
	sta WG_FOCUSVIEW			; Focus on our current selection

	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewUnfocus
; Unfocuses all views
; Side effects: Changes selected view, repaints some views
;
WGViewUnfocus:
	pha

	jsr unfocusCurrent

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

	jsr unfocusCurrent

WGViewFocusNext_loop:
	lda	WG_FOCUSVIEW			; Increment and wrap
	inc
	cmp #16
	beq WGViewFocusNext_wrap
	sta WG_FOCUSVIEW

	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+2,y
	beq WGViewFocusNext_loop

WGViewFocusNext_wantFocus:		; Does this view accept focus?
	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+4,y
	and #$f						; Mask off flag bits
	cmp #VIEW_STYLE_TAKESFOCUS
	bcc WGViewFocusNext_loop

WGViewFocusNext_focus:
	jsr focusCurrent

	RESTORE_AY
	rts

WGViewFocusNext_wrap:
	stz	WG_FOCUSVIEW
	bra WGViewFocusNext_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFocusPrev
; Shifts focus to the prev view
; Side effects: Changes selected view, repaints some views
;
WGViewFocusPrev:
	SAVE_AXY

	jsr unfocusCurrent

WGViewFocusPrev_loop:
	ldx	WG_FOCUSVIEW			; Decrement and wrap
	dex
	bmi WGViewFocusPrev_wrap

WGViewFocusPrev_findLoop:
	stx WG_FOCUSVIEW
	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+2,y
	beq WGViewFocusPrev_loop

WGViewFocusPrev_wantFocus:		; Does this view accept focus?
	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+4,y
	and #$f						; Mask off flag bits
	cmp #VIEW_STYLE_TAKESFOCUS
	bcc WGViewFocusPrev_loop

WGViewFocusPrev_focus:
	jsr focusCurrent

	RESTORE_AXY
	rts

WGViewFocusPrev_wrap:
	ldx #$f
	bra WGViewFocusPrev_findLoop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unfocusCurrent
; Unfocuses current view, if any
; Side effects: Clobbers A,
;               Leaves Y pointed at current focus view record
;               Changes active view selection
unfocusCurrent:
	lda WG_FOCUSVIEW
	bmi unfocusCurrentDone		; No current focus

	LDY_FOCUSVIEW				; Unfocus current view
	lda WG_VIEWRECORDS+9,y
	and #%01111111
	sta WG_VIEWRECORDS+9,y

	lda WG_FOCUSVIEW
	jsr WGSelectView
	jsr WGPaintView

unfocusCurrentDone:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; focusCurrent
; Sets focus to desired view, and repaints
; Side effects: Clobbers A
focusCurrent:
	lda	WG_FOCUSVIEW
	jsr WGSelectView

	LDY_ACTIVEVIEW

	lda WG_VIEWRECORDS+4,y
	and #$f						; Mask off flag bits
	cmp #VIEW_STYLE_TAKESFOCUS
	bcc focusCurrent_done

	lda WG_VIEWRECORDS+9,y
	ora #%10000000
	sta WG_VIEWRECORDS+9,y

	jsr WGPaintView

focusCurrent_done:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFocusAction
; Performs the action of the focused view
; WG_GOSUB : Set if the caller should perform an Applesoft GOSUB
; Side effects: Changes selected view, Repaints some views
;
WGViewFocusAction:
	SAVE_AXY

	lda WG_FOCUSVIEW
	bmi WGViewFocusAction_done

	LDY_FOCUSVIEW
	lda WG_VIEWRECORDS+4,y		; What kind of view is it?
	and #$f						; Mask off flag bits

	cmp #VIEW_STYLE_CHECK
	beq WGViewFocusAction_toggleCheckbox
	bra WGViewFocusAction_buttonClick	; Everything else treated like a button

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
	sta WG_GOSUBLINE
	lda WG_VIEWRECORDS+11,y
	sta WG_GOSUBLINE+1

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
	RESTORE_AXY
WGViewFocusAction_knownRTS:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPendingViewAction
; Performs the action of the pending view, if any
; Global flag set if the caller should perform an Applesoft GOSUB
; Side effects: Changes selected view, Repaints some views
;
WGPendingViewAction:
	SAVE_AY

	lda WG_MOUSECLICK_X
	bmi WGPendingViewAction_done

	sta PARAM0
	lda WG_MOUSECLICK_Y
	sta PARAM1
	jsr WGViewFromPoint
	sta WG_PENDINGACTIONVIEW
	cmp #$ff
	beq WGPendingViewAction_done

	and #$f					; Select view in question
	jsr WGSelectView
	LDY_ACTIVEVIEW

	lda WG_VIEWRECORDS+4,y
	and #$f
	cmp #VIEW_STYLE_FANCY				; Filter out fancy views with high-nybble of 0
	bne WGPendingViewAction_chkCallback	; This prevents unnecessary redraws when clicking
	lda WG_PENDINGACTIONVIEW			; in the content area
	and #$f0
	beq WGPendingViewAction_done

WGPendingViewAction_chkCallback:
;	lda WG_VIEWRECORDS+10,y			; Optimization- only process things that can be clicked
;	bne WGPendingViewAction_hasCallback
;	lda WG_VIEWRECORDS+11,y
;	beq WGPendingViewAction_done

WGPendingViewAction_hasCallback:
	lda WG_PENDINGACTIONVIEW
	and #$f0				; Check for window features
	beq WGPendingViewAction_content

	cmp #WG_FEATURE_UP
	beq WGPendingViewAction_up
	cmp #WG_FEATURE_DN
	beq WGPendingViewAction_down
	cmp #WG_FEATURE_LF
	beq WGPendingViewAction_left
	cmp #WG_FEATURE_RT
	bne WGPendingViewAction_done

	lda #$FF					; Right arrow
	jsr WGScrollXBy
	jsr WGViewFocus
	jsr WGViewFocusAction	; Trigger application to redraw contents

WGPendingViewAction_done:		; Located here for branch range
	lda #$ff
	sta WG_PENDINGACTIONVIEW
	sta WG_MOUSECLICK_X

	RESTORE_AY
	rts

WGPendingViewAction_up:
	lda #1					; Up arrow
	jsr WGScrollYBy
	jsr WGViewFocusQuiet
	jsr WGViewFocusAction	; Trigger application to redraw contents
	bra WGPendingViewAction_done

WGPendingViewAction_down:
	lda #$FF					; Down arrow
	jsr WGScrollYBy
	jsr WGViewFocusQuiet
	jsr WGViewFocusAction	; Trigger application to redraw contents
	bra WGPendingViewAction_done

WGPendingViewAction_left:
	lda #1					; Left arrow
	jsr WGScrollXBy
	jsr WGViewFocusQuiet
	jsr WGViewFocusAction	; Trigger application to redraw contents
	bra WGPendingViewAction_done

WGPendingViewAction_content:
	jsr WGViewFocus
	jsr WGViewFocusAction
	jsr delayShort
	jsr WGViewUnfocus

	jsr WGPointerDirty		; If we redrew anything, the pointer BG will be stale
	bra WGPendingViewAction_done




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPendingClick
; Returns the mouse click that is currently pending
; OUT X,Y : Mouse coordinates, or $ff in X if none
;
WGPendingClick:
	ldx WG_MOUSECLICK_X
	bmi WGPendingClick_done
	ldy WG_MOUSECLICK_Y

WGPendingClick_done:
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewSetTitle
; Sets the title of the active view
; PARAM0: Null-terminated string pointer (LSB)
; PARAM1: Null-terminated string pointer (MSB)
WGViewSetTitle:
	SAVE_AY

	LDY_ACTIVEVIEW
	lda PARAM0
	sta WG_VIEWRECORDS+12,y
	lda PARAM1
	sta WG_VIEWRECORDS+13,y

WGViewSetTitle_done:
	RESTORE_AY
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
; WGViewSetRawTitle
; Sets the raw title flag of the active view
; PARAM0: Flag to set
WGViewSetRawTitle:
	SAVE_AY

	LDY_ACTIVEVIEW
	lda PARAM0
	asl		; Shifts need to match VIEW_STYLE_RAWTITLE
	asl
	asl
	asl
	asl
	asl
	eor WG_VIEWRECORDS+4,y
	sta WG_VIEWRECORDS+4,y

WGViewSetRawTitle_done:
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
	bpl WGSetCursor_StoreX
	lda #0					; Prevent negatives

WGSetCursor_StoreX:
	sta	WG_LOCALCURSORX
	lda PARAM1
	bpl WGSetCursor_StoreY
	lda #0					; Prevent negatives

WGSetCursor_StoreY:
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

	LDY_ACTIVEVIEW

	; Sync X
	clc						; Transform to viewspace
	lda WG_LOCALCURSORX
	adc	WG_VIEWRECORDS+0,y

	clc
	adc	WG_VIEWRECORDS+5,y	; Transform to scrollspace
	sta WG_CURSORX

	; Sync Y
	clc						; Transform to viewspace
	lda WG_LOCALCURSORY
	adc	WG_VIEWRECORDS+1,y

	clc
	adc	WG_VIEWRECORDS+6,y	; Transform to scrollspace
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
	pla
	bmi WGScrollX_Store
	lda #0					; Prevent positive scroll values

WGScrollX_Store:
	sta	WG_VIEWRECORDS+5,y
	jsr	cacheClipPlanes		; Scroll offset changed, so clipping cache is stale

WGScrollX_done:
	ply
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGScrollXBy
; Scrolls the current view horizontally by a delta
; A: Scroll delta
; Side effects: Clobbers A,S0
;
WGScrollXBy:
	SAVE_XY
	tax

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
	beq @0					; Clamp if needed
	bpl WGScrollXBy_clampRight
@0:	sta WG_VIEWRECORDS+5,y
	bra WGScrollXBy_done

WGScrollXBy_clampRight:
	lda #0
	sta WG_VIEWRECORDS+5,y

WGScrollXBy_done:
	RESTORE_XY
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
	bmi WGScrollY_Store
	lda #0					; Prevent positive scroll values

WGScrollY_Store:
	sta	WG_VIEWRECORDS+6,y
	jsr	cacheClipPlanes		; Scroll offset changed, so clipping cache is stale

WGScrollY_done:
	ply
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGScrollYBy
; Scrolls the current view horizontally by a delta
; A: Scroll delta
; Side effects: Clobbers A,S0
;
WGScrollYBy:
	SAVE_XY
	tax

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
	beq @0					; Clamp if needed
	bpl WGScrollYBy_clampBottom	
@0:	sta WG_VIEWRECORDS+6,y
	bra WGScrollYBy_done

WGScrollYBy_clampBottom:
	lda #0
	sta WG_VIEWRECORDS+6,y

WGScrollYBy_done:
	RESTORE_XY
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSetContentWidth
; Sets the content width of the current view
; A: New width
;
WGSetContentWidth:
	phy
	pha

	LDY_ACTIVEVIEW
	pla

	sta	WG_VIEWRECORDS+7,y
	jsr	cacheClipPlanes		; Content width changed, so clipping cache is stale

	ply
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGSetContentHeight
; Sets the content width of the current view
; A: New height
;
WGSetContentHeight:
	phy
	pha

	LDY_ACTIVEVIEW
	pla

	sta	WG_VIEWRECORDS+8,y
	jsr	cacheClipPlanes		; Content height changed, so clipping cache is stale

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
	sta WG_ACTIVEVIEW

	LDY_ACTIVEVIEW
	lda WG_VIEWRECORDS+2,y		; Valid view?
	beq WGViewPaintAll_next

	jsr WGEraseViewContents
	jsr WGPaintView

WGViewPaintAll_next:
	inx
	cpx #16
	bne WGViewPaintAll_loop

WGViewPaintAll_done:
	lda #$FF
	jsr WGSelectView

	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGViewFromPoint
; Finds a view containing the given point
; PARAM0:X
; PARAM1:Y
; OUT A: View ID (or high bit set if no match)
; For Fancy Views, Upper nibble returned indicates feature hit:
; 0000 : Content region
; 0001 : Scroll arrow up
; 0010 : Scroll arrow down
; 0011 : Scroll arrow left
; 0100 : Scroll arrow right
WGViewFromPoint:
	SAVE_XY
	SAVE_ZPS

	ldx #$f		; Scan views backwards, because controls are usually at the end

WGViewFromPoint_loop:
	txa
	LDY_AVIEW

	lda WG_VIEWRECORDS+2,y
	beq WGViewFromPoint_loopNext	; Not an allocated view

	lda WG_VIEWRECORDS+4,y			; Fancy views are handled differently
	and #$f
	cmp #VIEW_STYLE_FANCY
	beq WGViewFromPoint_loopFancy

	lda WG_VIEWRECORDS+2,y
	sta SCRATCH0
	lda WG_VIEWRECORDS+3,y
	sta SCRATCH1
	bra WGViewFromPoint_loopCheckBounds
	
WGViewFromPoint_loopFancy:
	lda WG_VIEWRECORDS+2,y			; Include scrollbars
	inc
	sta SCRATCH0
	lda WG_VIEWRECORDS+3,y
	inc
	sta SCRATCH1

WGViewFromPoint_loopCheckBounds:
	lda PARAM0						; Check left edge
	cmp WG_VIEWRECORDS+0,y
	bcc WGViewFromPoint_loopNext

	lda PARAM1						; Check top edge
	cmp WG_VIEWRECORDS+1,y
	bcc WGViewFromPoint_loopNext

	lda WG_VIEWRECORDS+0,y			; Check right edge
	clc
	adc SCRATCH0
	cmp PARAM0
	bcc WGViewFromPoint_loopNext
	beq WGViewFromPoint_loopNext

	lda WG_VIEWRECORDS+1,y			; Check bottom edge
	clc
	adc SCRATCH1
	cmp PARAM1
	bcc WGViewFromPoint_loopNext
	beq WGViewFromPoint_loopNext

	; Found a match (in X)
	lda WG_VIEWRECORDS+4,y
	and #$f							; Mask off flag bits
	cmp #VIEW_STYLE_FANCY
	bne WGViewFromPoint_matchDone

	; For fancy views, check scrollbars as well
	lda WG_VIEWRECORDS+0,y			; Right scroll bar?
	clc
	adc SCRATCH0
	dec
	cmp PARAM0
	bne WGViewFromPoint_checkBottomScroll

	lda PARAM1						; Up arrow?
	cmp WG_VIEWRECORDS+1,y
	bne WGViewFromPoint_checkDownArrow
	txa
	ora #WG_FEATURE_UP
	bra WGViewFromPoint_matchFancyDone

WGViewFromPoint_loopNext:			; Inserted here for branch range
	dex
	bmi WGViewFromPoint_noMatch
	bra WGViewFromPoint_loop

WGViewFromPoint_checkDownArrow:
	lda WG_VIEWRECORDS+1,y			; Down arrow?
	clc
	adc SCRATCH1
	dec
	dec
	cmp PARAM1
	bne WGViewFromPoint_matchDone
	txa
	ora #WG_FEATURE_DN
	bra WGViewFromPoint_matchFancyDone

WGViewFromPoint_checkBottomScroll:
	lda WG_VIEWRECORDS+1,y			; Bottom scroll bar?
	clc
	adc SCRATCH1
	dec
	cmp PARAM1
	bne WGViewFromPoint_matchDone
	lda PARAM0						; Left arrow?
	cmp WG_VIEWRECORDS+0,y
	bne WGViewFromPoint_checkRightArrow
	txa
	ora #WG_FEATURE_LF
	bra WGViewFromPoint_matchFancyDone

WGViewFromPoint_checkRightArrow:
	lda WG_VIEWRECORDS+0,y			; Right arrow?
	clc
	adc SCRATCH0
	dec
	dec
	cmp PARAM0
	bne WGViewFromPoint_matchDone
	txa
	ora #WG_FEATURE_RT

WGViewFromPoint_matchFancyDone:
	tax

WGViewFromPoint_matchDone:
	RESTORE_ZPS
	txa
	RESTORE_XY
	rts

WGViewFromPoint_noMatch:
	RESTORE_ZPS
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

	lda	WG_VIEWRECORDS+5,y	; Left edge
	eor #$ff
	inc
	sta	WG_VIEWCLIP+0

	clc
	adc	WG_VIEWRECORDS+2,y	; Right edge
	sta	WG_VIEWCLIP+2

	lda	WG_VIEWRECORDS+7,y	; Right span (distance from window edge to view edge, in viewspace
	sec
	sbc	WG_VIEWCLIP+2
	sta	WG_VIEWCLIP+4
	
	lda	WG_VIEWRECORDS+6,y	; Top edge
	eor #$ff
	inc
	sta	WG_VIEWCLIP+1

	clc
	adc	WG_VIEWRECORDS+3,y	; Bottom edge
	sta	WG_VIEWCLIP+3

	RESTORE_AY
	rts


