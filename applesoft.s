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
WG_AMPVECTOR = $03f5
CHRGET = $00b1			; Advances text point and gets character in A
CHRGOT = $00b7			; Returns character at text pointer in A
SYNCHR = $dec0			; Validates current character is what's in A
TXTPTRL = $00b8			; Current location in BASIC listing (LSB)
TXTPTRH = $00b9			; Current location in BASIC listing (MSB)
ERROR = $d412			; Reports error in X
CHKCOM = $debe			; Validates current character is a ',', then gets it
GETBYT = $e6f8			; Gets an integer at text pointer, stores in X
GETNUM = $e746			; Gets an 8-bit, stores it X, skips past a comma

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
	sta WG_AMPVECTOR
	lda #<WGAmpersand
	sta WG_AMPVECTOR+1
	lda #>WGAmpersand
	sta WG_AMPVECTOR+2

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
	beq WGAmpersand_matchFound		; Got one!
	cmp WGAmpersandCommandTable,x
	bne WGAmpersand_matchNext	; Not this one

	iny
	inx
	bra WGAmpersand_matchLoop

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
; WGAmpersandIntArguments
; Buffers integer arguments for the current command in PARAMx
; TXTPTR: Start of argument list (after opening parenthesis)
; OUT PARAMx : The arguments
WGAmpersandIntArguments:
	SAVE_AXY

	ldy #0
	phy					; Can't rely on Applesoft routines to be register-safe

	lda #'('
	jsr SYNCHR			; Expect opening parenthesis

WGAmpersandIntArguments_loop:
	jsr GETBYT
	txa
	ply
	sta PARAM0,y
	phy

	jsr CHRGOT
	cmp #')'			; All done!
	beq WGAmpersandIntArguments_cleanup
	jsr CHKCOM			; Verify parameter separator

	ply
	iny
	phy
	cpy #4				 ; Check for too many arguments
	bne WGAmpersandIntArguments_loop

WGAmpersandIntArguments_fail:
	ldx #ERR_TOOLONG
	jsr ERROR
	bra WGAmpersandIntArguments_done

WGAmpersandIntArguments_cleanup:
	jsr CHRGET			; Consume closing parenthesis

WGAmpersandIntArguments_done:
	ply
	RESTORE_AXY
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
; WGAmpersandStrArgument
; Buffers a string argument for the current command in PARAM0/1
; TXTPTR: Start of argument list (after opening parenthesis)
; OUT PARAM0/1 : The argument
WGAmpersandStrArguments:
	SAVE_AXY

	ldy #0
	phy					; Can't rely on Applesoft routines to be register-safe

	lda #'('
	jsr SYNCHR			; Expect opening parenthesis

WGAmpersandStrArguments_loop:
	jsr CHRGOT
	beq WGAmpersandStrArguments_tooShort
	cmp #')'
	beq WGAmpersandStrArguments_cleanup

	ply
	sta WGAmpersandCommandBuffer,y
	iny
	phy
	cpy #WGAmpersandCommandBufferEnd-WGAmpersandCommandBuffer
	beq WGAmpersandStrArguments_tooLong

	jsr CHRGET
	bra WGAmpersandStrArguments_loop

WGAmpersandStrArguments_tooLong:
	ldx #ERR_TOOLONG
	jsr ERROR
	bra WGAmpersandStrArguments_done

WGAmpersandStrArguments_tooShort:
	ldx #ERR_SYNTAX
	jsr ERROR
	bra WGAmpersandStrArguments_done

WGAmpersandStrArguments_cleanup:
	jsr CHRGET			; Consume closing parenthesis

WGAmpersandStrArguments_done:
	ply					; Null-terminate result
	lda #0
	sta WGAmpersandCommandBuffer,y

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
	jsr WGAmpersandStructArgument
	jsr WGCreateView
	jsr WGPaintView
	jsr WGBottomCursor

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_CHECKBOX
; Create a checkbox
; &CHECKBOX(id,x,y)
WGAmpersand_CHECKBOX:
	jsr WGAmpersandStructArgument
	jsr WGCreateCheckbox
	jsr WGPaintView
	jsr WGBottomCursor

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_BUTTON
; Create a button
; &BUTTON(id,x,y,width,"title")
WGAmpersand_BUTTON:
	jsr WGAmpersandStructArgument
	jsr WGCreateButton

	lda WGAmpersandCommandBuffer+4
	sta PARAM0
	lda WGAmpersandCommandBuffer+5
	sta PARAM1
	jsr WGViewSetTitle

	jsr WGPaintView
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
; Applesoft API state
;

WGAmpersandCommandBuffer:
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
WGAmpersandCommandBufferEnd:
.byte 0			; Make sure this last byte is always kept as a terminator


; Jump table for ampersand commands.
; Each row is 16 bytes (14 for name, 2 for address)
;
; Note the strange byte values amidst some strings- this is because
; all text is tokenized before we receive it, so reserved words may
; be compressed
;
WGAmpersandCommandTable:

.byte $97,0,0,0,0,0,0,0,0,0,0,0,0,0		; HOME
.addr WGAmpersand_HOME

.byte "DESK",0,0,0,0,0,0,0,0,0,0
.addr WGAmpersand_DESK

.byte "WINDOW",0,0,0,0,0,0,0,0
.addr WGAmpersand_WINDOW

.byte "CHECKBOX",0,0,0,0,0,0
.addr WGAmpersand_CHECKBOX

.byte "BUT",$c1,"N",0,0,0,0,0,0,0,0,0		; BUTTON
.addr WGAmpersand_BUTTON


WGAmpersandCommandTableEnd:

