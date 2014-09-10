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
CHRGET = $00b1
ERROR = $d412

ERR_UNDEFINEDFUNC = 224

ERR_SYNTAX = 16

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

	ldy #0
	ldx SCRATCH0

WGAmpersand_parseLoop:
	txa
	beq WGAmpersand_parseMatchStart	; Check for end-of-statement
	cmp #':'
	beq WGAmpersand_parseMatchStart

	sta WGAmpersandCommandBuffer,y

	jsr CHRGET
	tax

	iny
	cpy #14
	bne WGAmpersand_parseLoop

WGAmpersand_parseMatchStart:
	ldy #0
	ldx #0						; Command buffer now contains our API call
	phx							; We stash the current command number on the stack

WGAmpersand_parseMatchLoop:
	lda WGAmpersandCommandBuffer,y
	beq WGAmpersand_parseMatchFound	; Made it to the end
	cmp WGAmpersandCommandTable,x
	bne WGAmpersand_parseMatchNext	; Not this one

	iny
	inx
	bra WGAmpersand_parseMatchLoop

WGAmpersand_parseMatchNext:
	pla				; Advance index to next commmand in table
	inc
	pha
	asl
	asl
	asl
	asl
	tax

	cpx #WGAmpersandCommandTableEnd-WGAmpersandCommandTable
	beq WGAmpersand_parseFail	; Hit the end of the table

	ldy #0
	bra WGAmpersand_parseMatchLoop

WGAmpersand_parseMatchFound:
	pla							; This is now the matching command number
	inc
	asl
	asl
	asl
	asl
	tay
	lda WGAmpersandCommandTable-2,y	; Prepare an indirect JSR to our command
	sta WGAmpersand_commandJSR+1
	lda WGAmpersandCommandTable-1,y
	sta WGAmpersand_commandJSR+2

	; Self modifying code:
WGAmpersand_commandJSR:
	jsr WGAmpersand_done			; Address here overwritten with command
	bra WGAmpersand_done

WGAmpersand_parseFail:
	pla					; We left command number on the stack while matching
	ldx #ERR_UNDEFINEDFUNC
	jsr ERROR

WGAmpersand_done:
	RESTORE_AXY
	rts




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ampersand API entry points
;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_view
; Create a view
;
WGAmpersand_VIEW:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGAmpersand_desk
; Render the desktop
;
WGAmpersand_DESK:
	jsr WGDesktop
	rts




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Applesoft API state
;

WGAmpersandCommandBuffer:
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


; Jump table for ampersand commands.
; Each row is 16 bytes (14 for name, 2 for address)
WGAmpersandCommandTable:
.byte "VIEW",0,0,0,0,0,0,0,0,0,0
.addr WGAmpersand_VIEW

.byte "DESK",0,0,0,0,0,0,0,0,0,0
.addr WGAmpersand_DESK


WGAmpersandCommandTableEnd:

