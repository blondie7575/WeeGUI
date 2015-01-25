;
;  applesoft.s
;  Applesoft API via the & extension point
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Applesoft ROM entry points and constants
;
LINNUML = $0050			; Scratch pad for calculating line numbers (LSB)
LINNUMH = $0051			; Scratch pad for calculating line numbers (MSB)
CURLINL = $0075			; Current line number (LSB)
CURLINH = $0076			; Current line number (MSB)
CHRGET = $00b1			; Advances text point and gets character in A
CHRGOT = $00b7			; Returns character at text pointer in A
TXTPTRL = $00b8			; Current location in BASIC listing (LSB)
TXTPTRH = $00b9			; Current location in BASIC listing (MSB)
VARPNT = $0083			; Return value for PTRGET

FAC = $009d				; Floating point accumulator

AMPVECTOR = $03f5		; Ampersand entry vector
ERROR = $d412			; Reports error in X
NEWSTT = $d7d2			; Advance to next Applesoft statement
GOTO = $d93e			; Entry point of Applesoft GOTO
LINGET = $da0c			; Read a line number (16-bit integer) into LINNUM
FRMNUM = $dd67			; Evaluate an expression as a number and store in FAC
CHKCOM = $debe			; Validates current character is a ',', then gets it
SYNCHR = $dec0			; Validates current character is what's in A
AYINT = $e10c			; Convert FAC to 8-bit signed integer
GETBYT = $e6f8			; Gets an integer at text pointer, stores in X
GETNUM = $e746			; Gets an 8-bit, stores it X, skips past a comma
PTRGET = $dfe3			; Finds the Applesoft variable in memory at text pointer

TOKEN_GOSUB = $b0		; Applesoft's token for GOSUB
TOKEN_HOME = $97		; Applesoft's token for HOME
TOKEN_PRINT = $ba		; Applesoft's token for PRINT
TOKEN_MINUS = $c9		; Applesoft's token for a minus sign
TOKEN_DRAW = $94		; Applesoft's token for DRAW
TOKEN_PLOT = $8d		; Applesoft's token for PLOT
TOKEN_GET = $be			; Applesoft's token for GET

ERR_UNDEFINEDFUNC = 224
ERR_SYNTAX = 16
ERR_ENDOFDATA = 5
ERR_TOOLONG = 176

MAXCMDLEN = 6


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGInitApplesoft
; Sets up Applesoft API
;
WGInitApplesoft:
	pha

	lda #$4c					; Patch in our jump vector for &
	sta AMPVECTOR
	lda #<WGAmpersand
	sta AMPVECTOR+1
	lda #>WGAmpersand
	sta AMPVECTOR+2

	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand
; The entry point from Applesoft. Applesoft text pointer
; will be positioned two after the '&', and accumulator will
; contain first character after the '&'
; Side effects: Clobbers All registers,S0
;
WGAmpersand:
	tsx					; Start by caching a valid stack state to return to Applesoft,
	stx WG_STACKPTR		; in case we need to do so in a hurry

	sta SCRATCH0

	ldy #0
	ldx SCRATCH0

WGAmpersand_parseLoop:
	txa
	beq WGAmpersand_matchStart	; Check for end-of-statement (CHRGET handles : and EOL)
	cmp #'('
	beq WGAmpersand_matchStart

	sta WGAmpersandCommandBuffer,y

	jsr CHRGET
	tax

	iny
	cpy #MAXCMDLEN+1
	bne WGAmpersand_parseLoop

WGAmpersand_parseFail:
	ldx #ERR_UNDEFINEDFUNC
	jsr ERROR
	bra WGAmpersand_done

WGAmpersand_matchStart:
	lda #0
	sta WGAmpersandCommandBuffer,y	; Null terminate the buffer for matching

	ldy #0
	ldx #0						; Command buffer now contains our API call
	phx							; We stash the current command number on the stack

WGAmpersand_matchLoop:
	lda WGAmpersandCommandBuffer,y
	beq WGAmpersand_matchPossible
	cmp WGAmpersandCommandTable,x
	bne WGAmpersand_matchNext	; Not this one

	iny
	inx
	bra WGAmpersand_matchLoop

WGAmpersand_matchPossible:
	lda WGAmpersandCommandTable,x
	beq WGAmpersand_matchFound		; Got one!

WGAmpersand_matchNext:
	pla				; Advance index to next commmand in table
	inc
	pha
	asl
	asl
	asl
	tax

	cpx #WGAmpersandCommandTableEnd-WGAmpersandCommandTable
	beq WGAmpersand_matchFail	; Hit the end of the table

	ldy #0
	bra WGAmpersand_matchLoop

WGAmpersand_matchFound:
	pla							; This is now the matching command number
	inc
	asl
	asl
	asl
	tay
	lda WGAmpersandCommandTable-2,y	; Prepare an indirect JSR to our command
	sta WGAmpersand_commandJSR+1	; Self-modifying code!
	lda WGAmpersandCommandTable-1,y
	sta WGAmpersand_commandJSR+2

	; Self-modifying code!
WGAmpersand_commandJSR:
	jsr WGAmpersand_done			; Address here overwritten with command
	bra WGAmpersand_done

WGAmpersand_matchFail:
	pla					; We left command number on the stack while matching
	ldx #ERR_UNDEFINEDFUNC
	jsr ERROR

WGAmpersand_done:
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandBeginArguments
; Begins reading an ampersand argument list
; Side effects: Clobbers all registers
WGAmpersandBeginArguments:
	pha

	lda #'('
	jsr SYNCHR			; Expect opening parenthesis

	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandNextArgument
; Prepares for the next argument in the list
; Side effects: Clobbers all registers
WGAmpersandNextArgument:
	jsr CHRGOT
	jsr CHKCOM			; Verify parameter separator
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandEndArguments
; Finishes reading an ampersand argument list
; Side effects: Clobbers all registers
WGAmpersandEndArguments:
	pha

	lda #')'
	jsr SYNCHR			; Expect closing parenthesis

	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandIntArgument
; Reads an integer argument for the current command
; OUT A : The argument
; Side effects: Clobbers all registers
WGAmpersandIntArgument:
	jsr CHRGOT
	cmp #TOKEN_MINUS
	beq WGAmpersandIntArgument_signed

	jsr GETBYT
	txa
	rts

WGAmpersandIntArgument_signed:
	jsr CHRGET
	jsr GETBYT
	txa
	eor #$ff
	inc
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandAddrArgument
; Reads a 16-bit pointer (or integer) argument for the current command
; OUT X : The argument (LSB)
; OUT Y : The argument (MSB)
; Side effects: Clobbers all registers
WGAmpersandAddrArgument:
	jsr CHRGOT
	jsr LINGET

	ldx LINNUML
	ldy LINNUMH
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandStrArgument
; Reads a string argument for the current command in PARAM0/1.
; This string is copied into privately allocated memory.
; OUT X : Pointer to a stored copy of the string (LSB)
; OUT Y : Pointer to a stored copy of the string (MSB)
; Side effects: Clobbers P0/P1 and all registers
WGAmpersandStrArgument:
	lda #'"'
	jsr SYNCHR			; Expect opening quote

	lda TXTPTRL			; Allocate for, and copy the string at TXTPTR
	sta PARAM0
	lda TXTPTRH
	sta PARAM1
	lda #'"'			; Specify quote as our terminator
	jsr WGStoreStr

WGAmpersandStrArgument_loop:
	jsr CHRGET								; Consume the string for Applesoft
	beq WGAmpersandStrArgument_done
	cmp #'"'								; Check for closing quote
	bne WGAmpersandStrArgument_loop

WGAmpersandStrArgument_done:
	lda #'"'
	jsr SYNCHR			; Expect closing quote

	ldx PARAM0
	ldy PARAM1
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandTempStrArgument
; Reads a string argument for the current command in PARAM0/1.
; This string is pointed to IN PLACE, and NOT copied.
; OUT X : Pointer to a stored copy of the string (LSB)
; OUT Y : Pointer to a stored copy of the string (MSB)
; OUT A : String length
; Side effects: Clobbers P0/P1 and all registers
WGAmpersandTempStrArgument:
	lda #'"'
	jsr SYNCHR			; Expect opening quote

	lda TXTPTRL			; Grab current TXTPTR
	sta PARAM0
	lda TXTPTRH
	sta PARAM1

WGAmpersandTempStrArgument_loop:
	jsr CHRGET								; Consume the string for Applesoft
	beq WGAmpersandTempStrArgument_done
	cmp #'"'								; Check for closing quote
	bne WGAmpersandTempStrArgument_loop

WGAmpersandTempStrArgument_done:
	lda #'"'
	jsr SYNCHR			; Expect closing quote

	; Compute the 8-bit distance TXTPTR moved. Note that we can't simply
	; count in the above loop, because CHRGET will skip ahead unpredictable
	; amounts
	sec
	lda TXTPTRL
	sbc PARAM0
	dec

	ldx PARAM0			; Return results
	ldy PARAM1
;	pla

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ampersand API entry points
;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_HOME
; Clears the screen
; &HOME
WGAmpersand_HOME:
	jsr WGClearScreen
	jsr WGBottomCursor

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_DESK
; Render the desktop
; &DESK
WGAmpersand_DESK:
	jsr WGDesktop
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_WINDW
; Create a view
; &WINDW(id,style,x,y,width,height,canvas width,canvas height)
WGAmpersand_WINDW:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+0
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	ora #VIEW_STYLE_APPLESOFT		; Flag this as an Applesoft-created view
	sta WGAmpersandCommandBuffer+1
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+2
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+3
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+4
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+5
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+6
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+7

	jsr WGAmpersandEndArguments

	CALL16 WGCreateView,WGAmpersandCommandBuffer

	jsr WGEraseViewContents
	jsr WGPaintView
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_CHKBX
; Create a checkbox
; &CHKBX(id,x,y,"title")
WGAmpersand_CHKBX:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+0
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+1
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+2
	jsr WGAmpersandNextArgument

	jsr WGAmpersandStrArgument
	stx	WGAmpersandCommandBuffer+3
	sty WGAmpersandCommandBuffer+4

	jsr WGAmpersandEndArguments

	CALL16 WGCreateCheckbox,WGAmpersandCommandBuffer

	LDY_ACTIVEVIEW				; Flag this as an Applesoft-created view
	lda #VIEW_STYLE_APPLESOFT
	ora WG_VIEWRECORDS+4,y
	sta WG_VIEWRECORDS+4,y
	
	jsr WGPaintView
	jsr WGBottomCursor

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_BUTTN
; Create a button
; &BUTTN(id,x,y,width,lineNum,"title")
WGAmpersand_BUTTN:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+0
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+1
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+2
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+3
	jsr WGAmpersandNextArgument

	jsr WGAmpersandAddrArgument
	stx	WGAmpersandCommandBuffer+4
	sty WGAmpersandCommandBuffer+5
	jsr WGAmpersandNextArgument

	jsr WGAmpersandStrArgument
	stx	WGAmpersandCommandBuffer+6
	sty WGAmpersandCommandBuffer+7

	jsr WGAmpersandEndArguments

	CALL16 WGCreateButton,WGAmpersandCommandBuffer

	LDY_ACTIVEVIEW				; Flag this as an Applesoft-created view
	lda #VIEW_STYLE_APPLESOFT
	ora WG_VIEWRECORDS+4,y
	sta WG_VIEWRECORDS+4,y

	jsr WGPaintView
	jsr WGBottomCursor

	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_SEL
; Select a view
; &SEL(id)
WGAmpersand_SEL:
	jsr WGAmpersandBeginArguments
	jsr WGAmpersandIntArgument

	jsr WGSelectView

	jsr WGAmpersandEndArguments
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_FOC
; Focuses selected view
; &FOC
WGAmpersand_FOC:
	jsr WGViewFocus
	jsr WGBottomCursor
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_FOCN
; Focuses next view
; &FOCN
WGAmpersand_FOCN:
	jsr WGViewFocusNext
	jsr WGBottomCursor
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_FOCP
; Focuses previous view
; &FOCP
WGAmpersand_FOCP:
	jsr WGViewFocusPrev
	jsr WGBottomCursor
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_ACT
; Takes action on focused view
; &ACT
WGAmpersand_ACT:
	jsr WGViewFocusAction
	jsr WGBottomCursor

	lda WG_GOSUB
	bne WGAmpersand_ACTGosub
	rts

WGAmpersand_ACTGosub:
	jmp WGGosub			; No coming back from an Applesoft GOSUB!


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_STACT
; Sets the callback for the selected view
; &STACT(lineNum)
WGAmpersand_STACT:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandAddrArgument
	stx	PARAM0
	sty PARAM1

	jsr WGAmpersandEndArguments

	jsr WGViewSetAction
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_TITLE
; Sets the title for the selected view
; &TITLE("title")
WGAmpersand_TITLE:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandStrArgument
	stx	PARAM0
	sty PARAM1

	jsr WGAmpersandEndArguments

	jsr WGViewSetTitle
	jsr WGPaintView

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_CURSR
; Sets the cursor position in selected viewspace
; &CURSR(x,y)
WGAmpersand_CURSR:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	sta PARAM0
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta PARAM1

	jsr WGAmpersandEndArguments

	jsr WGSetCursor

	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_PRINT
; Prints a string in the selected view at the local cursor
; &PRINT("string")
WGAmpersand_PRINT:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandTempStrArgument
	stx	PARAM0
	sty PARAM1
	pha

	jsr WGAmpersandEndArguments

	; We're pointing to the string directly in the Applesoft
	; source, so we need to NULL-terminate it for printing. In
	; order to avoid copying the whole thing, we'll do something
	; kinda dirty here.
	pla
	tay
	lda (PARAM0),y		; Cache the byte at the end of the string
	pha

	lda #0
	sta (PARAM0),y		; Null-terminate the string in-place

	jsr WGPrint

	pla
	sta (PARAM0),y		; Put original byte back

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_SCR
; Sets scroll position of selected view
; &SCR(x,y)
WGAmpersand_SCR:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	pha
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	pha

	jsr WGAmpersandEndArguments

	pla
	jsr WGScrollY
	pla
	jsr WGScrollX

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_SCRBY
; Adjusts scroll position of selected view by a delta
; &SCRBY(x,y)
WGAmpersand_SCRBY:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	pha
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	pha

	jsr WGAmpersandEndArguments

	pla
	jsr WGScrollYBy
	pla
	jsr WGScrollXBy

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_GOSUB
; A custom gosub, because we can. Only for testing at the moment
; &GOSUB
WGAmpersand_GOSUB:
	lda #$e8
	sta PARAM0
	lda #$03
	sta PARAM1
	jmp WGGosub


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_ERASE
; Erases the contents of the selected view
; &ERASE
WGAmpersand_ERASE:
	jsr WGEraseViewContents
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_FILL
; Fills a rectangle with a character
; &FILL(x,y,width,height,char)
WGAmpersand_FILL:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	sta PARAM0
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta PARAM1
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta PARAM2
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta PARAM3
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	ora #$80					; Convert to Apple format
	pha

	jsr WGAmpersandEndArguments
	ply

	jsr WGFillRect
	jsr WGBottomCursor

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_DRAW
; Strokes a rectangle with a character
; &DRAW(x,y,width,height)
WGAmpersand_DRAW:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	sta PARAM0
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta PARAM1
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta PARAM2
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta PARAM3

	jsr WGAmpersandEndArguments

	jsr WGStrokeRect
	jsr WGBottomCursor

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_PNT
; Repaints the selected view
; &PNT
WGAmpersand_PNT:
	jsr WGPaintView
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_PNTA
; Repaints all views
; &PNTA
WGAmpersand_PNTA:
	jsr WGViewPaintAll
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_PLOT
; Plots a single character (in Apple format)
; &PLOT(x,y,value)
WGAmpersand_PLOT:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	sta WG_CURSORX
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WG_CURSORY
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	pha

	jsr WGAmpersandEndArguments

	pla
	jsr WGPlot
	jsr WGBottomCursor
	
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_MOUSE
; Enable or disable the mouse
; &MOUSE(enable)
WGAmpersand_MOUSE:
	jsr WGAmpersandBeginArguments
	jsr WGAmpersandIntArgument

	pha
	jsr WGAmpersandEndArguments

	pla
	beq WGAmpersand_MOUSEoff
	jsr WGEnableMouse
	rts

WGAmpersand_MOUSEoff:
	jsr WGDisableMouse
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_PDACT
; Performs any pending view action
; &PDACT
WGAmpersand_PDACT:
	lda WG_PENDINGACTIONVIEW
	bmi WGAmpersand_PDACTdone

	jsr WGPendingViewAction
	jsr WGBottomCursor

WGAmpersand_PDACTdone:
	lda WG_GOSUB
	bne WGAmpersand_PDACTGosub
	rts

WGAmpersand_PDACTGosub:
	jmp WGGosub			; No coming back from an Applesoft GOSUB!



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_GET
; A non-blocking version of Applesoft GET. Returns 0 if no key
; is pending
; &GET(A$)

WGAmpersand_GET:
	jsr WGAmpersandBeginArguments

	jsr PTRGET
	lda KBD
	bpl WGAmpersand_GETnone		; No key pending

	sta KBDSTRB					; Clear strobe and high bit
	and #%01111111
	bra WGAmpersand_GETstore

WGAmpersand_GETnone:
	lda #0

WGAmpersand_GETstore:
	ldy #0

	sta WG_KEYBUFFER			; Store the key
	lda #1						; Create an Applesoft string record in the
	sta (VARPNT),y				; variable's location
	iny
	lda #<WG_KEYBUFFER
	sta (VARPNT),y
	iny
	lda #>WG_KEYBUFFER
	sta (VARPNT),y

	jsr WGAmpersandEndArguments
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_KILL
; Deletes the selected view
; &KILL
WGAmpersand_KILL:
	jsr WGDeleteView
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_WIPE
; Erases all of the selected view
; &WIPE
WGAmpersand_WIPE:
	jsr WGEraseView
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_EXIT
; Shuts down WeeGUI
; &EXIT
WGAmpersand_EXIT:
	jsr WGExit
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGBottomCursor
; Leave the cursor state in a place that Applesoft is happy with
;
WGBottomCursor:
	SAVE_AY

	lda #0
	sta CH
	sta OURCH
	lda #23
	sta CV
	sta OURCV

	lda TEXTLINES_H+23
	sta BASH
	lda TEXTLINES_L+23
	sta BASL

	RESTORE_AY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGGosub
; Performs an Applesoft GOSUB to a line number
; WG_GOSUBLINE:	Line number (LSB)
; WG_GOSUBLINE+1: Line number (MSB)
;
WGGosub:
	lda #0
	sta WG_GOSUB		; Clear the flag

	; Can't come back from what we're about to do, so cleanup from the
	; original Ampersand entry point now!  This is some seriously voodoo
	; shit we're gonna pull here.
	ldx WG_STACKPTR
	txs

	; Fake an Applesoft GOSUB by pushing the same stuff it would do
	lda TXTPTRH
	pha
	lda TXTPTRL
	pha
	lda CURLINH
	pha
	lda CURLINL
	pha
	lda #TOKEN_GOSUB
	pha

	; Here's the tricky bit- we jump into Applesoft's GOTO
	; just after the part where it reads the line number. This
	; allows us to piggy back on the hard work of finding the
	; line number in the Applesoft source code, and storing
	; it in the TXTPTR (thus performing the jump portion of
	; a GOSUB). Since GOSUB normally falls through into GOTO,
	; by faking the setup portion of the GOSUB, then leaving
	; the state as GOTO expects it, we can fake the entire
	; process to GOSUB to a line number we specify
	lda WG_GOSUBLINE
	sta LINNUML
	lda WG_GOSUBLINE+1
	sta LINNUMH

	jsr GOTO+3

	; The goto has pointed the interpreter at the subroutine,
	; so now advance to the next statement to continue executing.
	; We'll never regain control, which is why we had to clean
	; up from the ampersand entry before we got here.
	jmp NEWSTT



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Applesoft API state
;

WGAmpersandCommandBuffer:
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
WGAmpersandCommandBufferEnd:
.byte 0			; Make sure this last byte is always kept as a terminator

WG_STACKPTR:	; A place to save the stack pointer for tricky Applesoft manipulation
.byte 0

WG_KEYBUFFER:	; A phony string buffer for non-blocking GET
.byte 0


; Jump table for ampersand commands.
; Each row is 8 bytes (5 for name, NULL terminator, 2 for address)
;
; Note the strange constants in place of some strings- this is because
; all text is tokenized before we receive it, so reserved words may
; be compressed
;
WGAmpersandCommandTable:

.byte TOKEN_HOME,0,0,0,0,0
.addr WGAmpersand_HOME

.byte "DESK",0,0
.addr WGAmpersand_DESK

.byte "WINDW",0
.addr WGAmpersand_WINDW

.byte "CHKBX",0
.addr WGAmpersand_CHKBX

.byte "BUTTN",0
.addr WGAmpersand_BUTTN

.byte "SEL",0,0,0
.addr WGAmpersand_SEL

.byte "FOC",0,0,0
.addr WGAmpersand_FOC

.byte "FOCN",0,0
.addr WGAmpersand_FOCN

.byte "FOCP",0,0
.addr WGAmpersand_FOCP

.byte "ACT",0,0,0
.addr WGAmpersand_ACT

.byte "STACT",0
.addr WGAmpersand_STACT

.byte "TITLE",0
.addr WGAmpersand_TITLE

.byte "CURSR",0
.addr WGAmpersand_CURSR

.byte "SCR",0,0,0
.addr WGAmpersand_SCR

.byte "SCRBY",0
.addr WGAmpersand_SCRBY

.byte "ERASE",0
.addr WGAmpersand_ERASE

.byte TOKEN_PRINT,0,0,0,0,0
.addr WGAmpersand_PRINT

.byte "FILL",0,0
.addr WGAmpersand_FILL

.byte TOKEN_DRAW,0,0,0,0,0
.addr WGAmpersand_DRAW

.byte "PNT",0,0,0
.addr WGAmpersand_PNT

.byte "PNTA",0,0
.addr WGAmpersand_PNTA

.byte TOKEN_PLOT,0,0,0,0,0
.addr WGAmpersand_PLOT

.byte "MOUSE",0
.addr WGAmpersand_MOUSE

.byte "PDACT",0
.addr WGAmpersand_PDACT

.byte TOKEN_GET,0,0,0,0,0
.addr WGAmpersand_GET

.byte "KILL",0,0
.addr WGAmpersand_KILL

.byte "WIPE",0,0
.addr WGAmpersand_WIPE

.byte "EXIT",0,0
.addr WGAmpersand_EXIT

;.byte TOKEN_GOSUB,0,0,0,0,0,0,0,0,0,0,0,0,0		; For internal testing of the procedural gosub
;.addr WGAmpersand_GOSUB


WGAmpersandCommandTableEnd:

