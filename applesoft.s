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

AMPVECTOR = $03f5		; Ampersand entry vector
ERROR = $d412			; Reports error in X
NEWSTT = $d7d2			; Advance to next Applesoft statement
GOTO = $d93e			; Entry point of Applesoft GOTO
LINGET = $da0c			; Read a line number (16-bit integer) into LINNUM
CHKCOM = $debe			; Validates current character is a ',', then gets it
SYNCHR = $dec0			; Validates current character is what's in A
GETBYT = $e6f8			; Gets an integer at text pointer, stores in X
GETNUM = $e746			; Gets an 8-bit, stores it X, skips past a comma

TOKEN_GOSUB = $b0		; Applesoft's token for GOSUB
TOKEN_HOME = $97		; Applesoft's token for HOME

ERR_UNDEFINEDFUNC = 224
ERR_SYNTAX = 16
ERR_ENDOFDATA = 5
ERR_TOOLONG = 176

MAXCMDLEN = 14


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
; Side effects: Clobbers S0
;
WGAmpersand:

	tsx					; Start by caching a valid stack state to return to Applesoft,
	stx WG_STACKPTR		; in case we need to do so in a hurry

	sta SCRATCH0
	SAVE_AXY
	SAVE_ZPP

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
	cpy #MAXCMDLEN
	bne WGAmpersand_parseLoop

WGAmpersand_parseFail:
	ldx #ERR_SYNTAX
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
	RESTORE_ZPP
	RESTORE_AXY
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
	jsr GETBYT
	txa
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandAddrArgument
; Reads a 16-bit pointer (or integer) argument for the current command
; OUT X : The argument (LSB)
; OUT Y : The argument (MSB)
; Side effects: Clobbers all registers
WGAmpersandAddrArgument:
	jsr LINGET
	ldx LINNUML
	ldy LINNUMH
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersandStrArgument
; Reads a string argument for the current command in PARAM0/1
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
	jsr CHRGET								; Consume the rest of the string
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
; WGAmpersandStructArgument
; Buffers integer arguments for current command into a struct
; TXTPTR: Start of argument list (after opening parenthesis)
; OUT PARAM0/1 : Pointer to struct containing int values
WGAmpersandStructArgument:
	SAVE_AXY

	ldy #0
	phy					; Can't rely on Applesoft routines to be register-safe

	lda #'('
	jsr SYNCHR			; Expect opening parenthesis

WGAmpersandStructArguments_loop:
	jsr CHRGOT
	cmp #'"'			; Check for string pointer
	beq WGAmpersandStructArguments_string

	jsr GETBYT
	txa
	ply
	sta WGAmpersandCommandBuffer,y
	phy

WGAmpersandStructArguments_nextParam:
	jsr CHRGOT
	cmp #')'			; All done!
	beq WGAmpersandStructArguments_cleanup
	jsr CHKCOM			; Verify parameter separator

	ply
	iny
	phy
	cpy #WGAmpersandCommandBufferEnd-WGAmpersandCommandBuffer	; Check for too many arguments
	bne WGAmpersandStructArguments_loop

WGAmpersandStructArguments_fail:
	ldx #ERR_TOOLONG
	jsr ERROR
	bra WGAmpersandStructArguments_done

WGAmpersandStructArguments_string:
	jsr CHRGET								; Consume opening quote
	lda TXTPTRL								; Allocate for, and copy the string at TXTPTR
	sta PARAM0
	lda TXTPTRH
	sta PARAM1
	lda #'"'								; Specify quote as our terminator
	jsr WGStoreStr

	ply										; Store returned string pointer in our struct
	lda PARAM1
	sta WGAmpersandCommandBuffer,y
	iny
	lda PARAM0
	sta WGAmpersandCommandBuffer,y
	iny
	phy

WGAmpersandStructArguments_stringLoop:
	jsr CHRGET								; Consume the rest of the string
	beq WGAmpersandStructArguments_stringLoopDone
	cmp #'"'								; Check for closing quote
	beq WGAmpersandStructArguments_stringLoopDone
	bra WGAmpersandStructArguments_stringLoop

WGAmpersandStructArguments_stringLoopDone:
	jsr CHRGET								; Consume closing quote
	bra WGAmpersandStructArguments_nextParam

WGAmpersandStructArguments_cleanup:
	jsr CHRGET								; Consume closing parenthesis

WGAmpersandStructArguments_done:
	ply

	lda #<WGAmpersandCommandBuffer
	sta PARAM0
	lda #>WGAmpersandCommandBuffer
	sta PARAM1

	RESTORE_AXY
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
; WGAmpersand_WINDOW
; Create a view
; &WINDOW(id,style,x,y,width,height,canvas width,canvas height)
WGAmpersand_WINDOW:
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

	lda #<WGAmpersandCommandBuffer
	sta PARAM0
	lda #>WGAmpersandCommandBuffer
	sta PARAM1

	jsr WGCreateView
	jsr WGEraseView
	jsr WGPaintView
	jsr WGBottomCursor
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_CHKBOX
; Create a checkbox
; &CHKBOX(id,x,y)
WGAmpersand_CHKBOX:
	jsr WGAmpersandBeginArguments

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+0
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+1
	jsr WGAmpersandNextArgument

	jsr WGAmpersandIntArgument
	sta WGAmpersandCommandBuffer+2

	jsr WGAmpersandEndArguments

	lda #<WGAmpersandCommandBuffer
	sta PARAM0
	lda #>WGAmpersandCommandBuffer
	sta PARAM1

	jsr WGCreateCheckbox

	LDY_ACTIVEVIEW				; Flag this as an Applesoft-created view
	lda #VIEW_STYLE_APPLESOFT
	ora WG_VIEWRECORDS+4,y

	jsr WGPaintView
	jsr WGBottomCursor

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_BUTTN
; Create a button
; &BUTTN(id,x,y,width,"title")
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

	lda #<WGAmpersandCommandBuffer
	sta PARAM0
	lda #>WGAmpersandCommandBuffer
	sta PARAM1
	jsr WGCreateButton

	LDY_ACTIVEVIEW				; Flag this as an Applesoft-created view
	lda #VIEW_STYLE_APPLESOFT
	ora WG_VIEWRECORDS+4,y

	lda WGAmpersandCommandBuffer+6	; Set the button text
	sta PARAM0
	lda WGAmpersandCommandBuffer+7
	sta PARAM1

	jsr WGViewSetTitle

	jsr WGPaintView
	jsr WGBottomCursor

	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_SELECT
; Select a view
; &SELECT(id)
WGAmpersand_SELECT:
	jsr WGAmpersandBeginArguments
	jsr WGAmpersandIntArgument

	jsr WGSelectView

	jsr WGAmpersandEndArguments
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_FOCUS
; Focuses selected view
; &FOCUS
WGAmpersand_FOCUS:
	jsr WGViewFocus
	jsr WGBottomCursor
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_FOCUSN
; Focuses next view
; &FOCUSN
WGAmpersand_FOCUSN:
	jsr WGViewFocusNext
	jsr WGBottomCursor
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_FOCUSP
; Focuses previous view
; &FOCUSN
WGAmpersand_FOCUSP:
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

	bvs WGAmpersand_ACTGosub
	rts

WGAmpersand_ACTGosub:
	jmp WGGosub			; No coming back from an Applesoft GOSUB!


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
; PARAM0: Line number (LSB)
; PARAM1: Line number (MSB)
;
WGGosub:
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
	lda PARAM0
	sta LINNUML
	lda PARAM1
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


; Jump table for ampersand commands.
; Each row is 16 bytes (14 for name, 2 for address)
;
; Note the strange byte values amidst some strings- this is because
; all text is tokenized before we receive it, so reserved words may
; be compressed
;
WGAmpersandCommandTable:

.byte TOKEN_HOME,0,0,0,0,0,0,0,0,0,0,0,0,0
.addr WGAmpersand_HOME

.byte "DESK",0,0,0,0,0,0,0,0,0,0
.addr WGAmpersand_DESK

.byte "WINDOW",0,0,0,0,0,0,0,0
.addr WGAmpersand_WINDOW

.byte "CHKBOX",0,0,0,0,0,0,0,0
.addr WGAmpersand_CHKBOX

.byte "BUTTN",0,0,0,0,0,0,0,0,0
.addr WGAmpersand_BUTTN

.byte "SELECT",0,0,0,0,0,0,0,0
.addr WGAmpersand_SELECT

.byte "FOCUS",0,0,0,0,0,0,0,0,0
.addr WGAmpersand_FOCUS

.byte "FOCUSN",0,0,0,0,0,0,0,0
.addr WGAmpersand_FOCUSN

.byte "FOCUSP",0,0,0,0,0,0,0,0
.addr WGAmpersand_FOCUSP

.byte "ACT",0,0,0,0,0,0,0,0,0,0,0
.addr WGAmpersand_ACT

.byte TOKEN_GOSUB,0,0,0,0,0,0,0,0,0,0,0,0,0		; For internal testing of the procedural gosub
.addr WGAmpersand_GOSUB


WGAmpersandCommandTableEnd:

