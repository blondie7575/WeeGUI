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
TXTPTR = $00b8	; (and $b9)		; Current location in BASIC listing
ERROR = $d412			; Reports error in X
CHKCOM = $debe			; Validates current character is a ',', then gets it
GETBYT = $e6f8			; Gets an integer at text pointer, stores in X
GETNUM = $e746			; Gets an 8-bit, stores it X, skips past a comma

ERR_UNDEFINEDFUNC = 224
ERR_SYNTAX = 16
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
	beq WGAmpersand_parseFail	; Check for end-of-statement (CHRGET handles : and EOL)
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
; WGAmpersand_VIEW
; Create a view
;
WGAmpersand_VIEW:
	jsr WGAmpersandStrArguments

	jsr WGCreateView
	jsr WGPaintView
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_DESK
; Render the desktop
;
WGAmpersand_DESK:
	jsr WGDesktop
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
WGAmpersandCommandTable:
.byte "VIEW",0,0,0,0,0,0,0,0,0,0
.addr WGAmpersand_VIEW

.byte "DESK",0,0,0,0,0,0,0,0,0,0
.addr WGAmpersand_DESK


WGAmpersandCommandTableEnd:

