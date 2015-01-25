;
;  gui.s
;  Top level management routines
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


.org $7e00

; Common definitions

.include "zeropage.s"
.include "switches.s"
.include "macros.s"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main entry point. BRUN will land here.
main:
	jsr WGInit
	rts				; Don't add any bytes here!


; This is the non-negotiable entry point used by applications Don't move it!
; $7e04



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDispatch
; The dispatcher for calling the assembly-language API from assembly programs
; X: API call number
; P0-3,Y: Parameters to call, as needed
WGDispatch:
	jmp (WGEntryPointTable,x)

; Entry point jump table
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
.addr WGPendingView
.addr WGScrollX
.addr WGScrollXBy
.addr WGScrollY
.addr WGScrollYBy
.addr WGEnableMouse
.addr WGDisableMouse
.addr WGDeleteView
.addr WGEraseView
.addr WGExit


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGInit
; Initialization. Should be called once at app startup
WGInit:
	SAVE_AXY

    ; Reserve our memory in the ProDOS allocator bitmap
	;
	; See section 5.1.4 in the ProDOS 8 Technical Reference Manual
	; for an explanation of these values. We're reserving memory
	; pages $7e-$95 so that ProDOS won't use our memory for file
	; buffers, or allow Applesoft to step on us
	;
	; Byte in System Bitmap : Bit within byte
	;   0f:001
	;   0f:000
	;   10:111 .. 10:000
	;   11:111 .. 11:000
	;   12:111
	;	12:110
	;	12:101
	;	12:100
	;	12:011
	;	12:010
	lda #%00000011
	tsb	MEMBITMAP + $0f
	lda #$ff
	tsb	MEMBITMAP + $10
	tsb	MEMBITMAP + $11
	lda #%11111100
	tsb	MEMBITMAP + $12

	jsr WG80				; Enter 80-col text mode
	jsr WGInitApplesoft		; Set up Applesoft API

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
	sta WG_PENDINGACTIONVIEW
	sta WG_FOCUSVIEW
	
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGInit
; Cleanup Should be called once at app shutdown
WGExit:
	pha

	lda #CHAR_NORMAL
	sta INVERSE

	; Remove ourselves from ProDOS memory map
	lda #%00000011
	trb	MEMBITMAP + $0f
	lda #$ff
	trb	MEMBITMAP + $10
	trb	MEMBITMAP + $11
	lda #%11111100
	trb	MEMBITMAP + $12

	pla
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WG80
; Enables 80 column mode (and enhanced video firmware)
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
.include "mouse.s"
.include "applesoft.s"
.include "memory.s"



; Suppress some linker warnings - Must be the last thing in the file
.SEGMENT "ZPSAVE"
.SEGMENT "EXEHDR"
.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "LOWCODE"

