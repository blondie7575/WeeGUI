;
;  gui.s
;  Top level management routines
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


.org $7a00

; Common definitions

.include "zeropage.s"
.include "switches.s"
.include "macros.s"



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main entry point. BRUN will land here.
main:
	jsr WGInit

	; Copy ourselves into AUX Memory
	;
	lda #<main
	sta A1L
	lda #>main
	sta A1H
	lda #<WG_END
	sta A2L
	lda #>WG_END
	sta A2H
	lda #<main
	sta A4L
	lda #>main
	sta A4H
	sec
	jsr AUXMOVE

	tsx			; Firmware convention requires saving the stack pointer before any XFERs
	stx $0100
	ldx #$ff
	stx $0101

	rts



; This is the non-negotiable entry point used by applications Don't move it!
WeeGUI				= $300
WeeGUIMouse			= $9344
WGDISPATCH			= WeeGUI + (WGEntryPointTable-WGDispatch)
WGDISPATCHRETURN	= WeeGUI + (WGDispatchMAIN-WGDispatch)
WGCALLBACKRETURN	= WeeGUI + (WGCallbackReturn-WGDispatch)

WGFirstMouseDispatch	= 62	; Special cases for the dispatcher above this value
WGEnableMouseDispatch	= 62
WGDisableMouseDispatch	= 64
WGPointerDirtyDispatch	= 66


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDispatch
; The dispatcher for calling the assembly-language API from assembly programs.
; This routine gets copied into $300 for use by main bank programs and Applesoft
; X: API call number
; P0-3,Y: Parameters to call, as needed
;
WGDispatch:
	; Check some special cases
	cpx #WGFirstMouseDispatch
	bcs WGDispatch_mouse

	lda WGDISPATCH,x		; Set up to transfer control into AUX memory
	sta XFERL
	lda WGDISPATCH+1,x
	sta XFERH

	tsx			; Firmware convention requires saving the stack pointer before XFER
	stx $0100

	lda #>WGDispatchReturn		; Give our routine somewhere to come back to
	pha
	lda #<WGDispatchReturn
	pha

	sec			; Transfer control to the routine in AUX memory
	clv
	jmp XFER

WGDispatch_mouse:
	lda WG_MOUSELOADED
	beq WGDispatch_mouseLoadDriver

WGDispatch_mouseDispatch:
	txa			; Transfer control to mouse driver
	sec
	sbc #WGFirstMouseDispatch
	tax
	jsr WeeGUIMouse

WGDispatch_done:
	rts

WGDispatch_mouseLoadDriver:
	phx
	lda #1
	sta WG_MOUSELOADED

	; BLOAD the mouse driver
	ldx #0
	ldy #0
@0:	lda bloadCmdLine,x
	beq @1
	sta INBUF,y
	inx
	iny
	bra @0
@1:	jsr DOSCMD
	plx
	bra WGDispatch_mouseDispatch

bloadCmdLine:
.byte "BLOAD mouse",$8d,0

WGDispatchMAIN:
	rts

; Entry point jump table - WGDISPATCH points here after this is copied to $300
WGEntryPointTable:
.addr WGClearScreen
.addr WGDesktop
.addr WGSetCursor
.addr WGSetGlobalCursor
.addr WGSyncGlobalCursor
.addr WGPlot
.addr WGPrint
.addr WGFillRect
.addr WGStrokeRect
.addr WGFancyRect
.addr WGPaintView
.addr WGViewPaintAll
.addr WGEraseViewContents
.addr WGCreateView
.addr WGCreateCheckbox
.addr WGCreateButton
.addr WGViewSetTitle
.addr WGViewSetAction
.addr WGSelectView
.addr WGViewFromPoint
.addr WGViewFocus
.addr WGViewUnfocus
.addr WGViewFocusNext
.addr WGViewFocusPrev
.addr WGViewFocusAction
.addr WGPendingViewAction
.addr WGScrollX
.addr WGScrollXBy
.addr WGScrollY
.addr WGScrollYBy


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCallbackReturn
; This is an anchor point in MAIN memory that user callbacks
; RTS back to. From here, we transfer control safely back to aux
; memory so that WeeGUI can resume.
;
WGCallbackReturn:
	nop						; Needed because RTS will skip one instruction, per usual
	lda #<WGCallbackAUX		; Set up to transfer control into AUX memory
	sta XFERL
	lda #>WGCallbackAUX
	sta XFERH
	sec						; Transfer control to the routine in AUX memory
	clv
	jmp XFER


; This is the end of what is copied into $300 in MAIN memory
WGDispatchEnd:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDispatchReturn
; This is an anchor point in AUX memory that WeeGUI subroutines
; RTS back to. From here, we transfer control safely back to main
; memory so the caller can resume.
;
WGDispatchReturn:
	nop						; Needed because RTS will skip one instruction, per usual
	lda #<WGDISPATCHRETURN		; Set up to transfer control into MAIN memory
	sta XFERL
	lda #>WGDISPATCHRETURN
	sta XFERH
	clc						; Transfer control to the routine in MAIN memory
	clv
	jmp XFER


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCallback
; Calls a user's routine in MAIN memory
; XFERL: Pointer in main memory (LSB)
; XFERH: Pointer in main memory (MSB)
WGCallback:
	lda #>WGCALLBACKRETURN		; Give user's routine somewhere to come back to
	pha
	lda #<WGCALLBACKRETURN
	pha

	clc						; Transfer control to the user's routine in MAIN memory
	clv
	jmp XFER

WGCallbackAUX:
	nop
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGInit
; Initialization. Should be called once at app startup
; Side effects: Clobbers all registers
;
WGInit:
	; Copy dispatcher to $300
	;
	ldx #WGDispatchEnd-WGDispatch

WGInit_copyLoop:
	lda WGDispatch-1,x
	sta WeeGUI-1,x
	dex
	bne WGInit_copyLoop

	jsr WG80
	jsr WGInitApplesoft

	ldy #15			; Clear our block allocators
WGInit_clearMemLoop:
	tya
	asl
	asl
	asl
	asl
	tax
	lda #0
	sta WG_STRINGS,x
	dey
	bpl WGInit_clearMemLoop

	lda #$ff
	sta WG_PENDINGACTIONCLICKX
	sta WG_FOCUSVIEW

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WG80
; Enables 80 column mode (and enhanced video firmware)
;
WG80:
	pha

	lda	#$a0
	jsr	$c300
	
	SETSWITCH	TEXTON
	SETSWITCH	PAGE2OFF
	SETSWITCH	COL80ON
	SETSWITCH	STORE80ON

	pla
	rts


; Code modules
.include "utility.s"
.include "painting.s"
.include "rects.s"
.include "views.s"
.include "applesoft.s"
.include "memory.s"

WG_END:					; The absolute end of our memory footprint. Nothing past this point!


; Suppress some linker warnings - Must be the last thing in the file
.SEGMENT "ZPSAVE"
.SEGMENT "EXEHDR"
.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "LOWCODE"

