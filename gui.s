;
;  gui.s
;  Top level management routines
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


.org $4000


; Common definitions

.include "zeropage.s"
.include "switches.s"
.include "macros.s"

; Main

main:
	jsr WGInit
	jsr WG80

	rts
	;jmp	tortureTestPrint
	;jmp	tortureTestRects

	jsr WGDesktop

	CALL16 WGCreateView,testView
	CALL16 WGViewSetTitle,testTitle0
	CALL16 WGCreateCheckbox,testCheck
	CALL16 WGCreateButton,testButton1
	CALL16 WGCreateButton,testButton2

	jsr WGViewPaintAll

	lda #0
	jsr WGSelectView

;	ldx	#5
;	ldy	#0
;	jsr	WGSetCursor

;	lda	#0
;	jsr	WGScrollX

;	lda	#-17
;	jsr	WGScrollY

;	jsr testPaintContents

	jsr WGEnableMouse

keyLoop:
	jsr WGPendingViewAction

	lda KBD
	bpl keyLoop
	sta KBDSTRB

	and #%01111111
	cmp #9
	beq keyLoop_focusNext
	cmp #27
	beq keyLoop_focusPrev
	cmp #13
	beq keyLoop_toggle
	cmp #32
	beq keyLoop_toggle
	cmp #'o'
	beq	keyLoop_focusOkay
	cmp #8
	beq	keyLoop_leftArrow
	cmp #21
	beq	keyLoop_rightArrow
	cmp #11
	beq	keyLoop_upArrow
	cmp #10
	beq	keyLoop_downArrow
	cmp #113
	beq	keyLoop_quit

	jmp keyLoop

keyLoop_focusNext:
	jsr WGViewFocusNext
	jmp keyLoop

keyLoop_focusPrev:
	jsr WGViewFocusPrev
	jmp keyLoop

keyLoop_toggle:
	jsr WGViewFocusAction
	jmp keyLoop

keyLoop_leftArrow:
	lda #1
	jsr WGScrollXBy
	jsr testPaintContents
	jmp keyLoop

keyLoop_rightArrow:
	lda #-1
	jsr WGScrollXBy
	jsr testPaintContents
	jmp keyLoop

keyLoop_upArrow:
	lda #1
	jsr WGScrollYBy
	jsr testPaintContents
	jmp keyLoop

keyLoop_downArrow:
	lda #-1
	jsr WGScrollYBy
	jsr testPaintContents
	jmp keyLoop

keyLoop_focusOkay:
	lda #2
	jsr WGSelectView
	jsr WGViewFocus
	jmp keyLoop

keyLoop_quit:
	jsr WGDisableMouse
	rts			; This seems to work for returning to BASIC.SYSTEM, but I don't know if it's right

testPaintContents:
	SAVE_AXY

	lda #0
	jsr WGSelectView
	jsr WGEraseViewContents


;;
	jsr WGNormal
	ldx #10
	ldy #15
	jsr WGSetCursor
	CALL16 WGPrint,testStr

	bra testPaintContents_done
;;


	ldy #0
testPaintContents_loop:
	ldx #0
	jsr WGSetCursor

	tya
	clc
	adc #'A'
	sta testStr3

	CALL16 WGPrint,testStr3

	iny
	cpy #25
	bne testPaintContents_loop

testPaintContents_done:
	RESTORE_AXY
	rts

testCallback:
	jsr $ff3a
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGInit
; Initialization. Should be called once at app startup
WGInit:
	SAVE_AXY

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
	sta WG_PENDINGACTIONVIEW
	sta WG_FOCUSVIEW
	
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WG80
; Enables 80 column mode (and enhanced video firmware)
WG80:
	pha

;	lda #3
;	jsr $fe95

	lda	#$a0
	jsr	$c300
	
	SETSWITCH	TEXTON
	SETSWITCH	PAGE2OFF
	SETSWITCH	COL80ON
	SETSWITCH	STORE80ON

	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; waitForKey
; Spinlocks until a key is pressed
waitForKey:
	lda	KBDSTRB
	bpl waitForKey
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read80ColSwitch
; Returns value of the 80 col switch on //c and //c+ machines
; OUT A: Switch state (non-zero=80 cols)
; NOTE: Untested
read80ColSwitch:
	lda $c060
	bpl read80ColSwitch_40
	lda #$1
	rts

read80ColSwitch_40:
	lda #$0
	rts


; Code modules
.include "utility.s"
.include "painting.s"
.include "rects.s"
.include "views.s"
.include "mouse.s"
.include "applesoft.s"
.include "unit_test.s"
.include "memory.s"


testView:
	.byte 0,1,7,3,62,18,62,40

testCheck:
	.byte 1,16,4
	.addr testTitle3

testButton1:
	.byte 2,35,10,15
	.addr testCallback
	.addr testTitle1

testButton2:
	.byte 3,35,13,15
	.addr 0
	.addr testTitle2

testStr:
;	.byte "This is a test of the emergency broadcast system.",0; If this had been a real emergency, you would be dead now.",0	; 107 chars
	.byte "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_ !",34,"#$%&'()*+,-./0123456789:;<=>?`abcdefghijklmno",0
testStr2:
	.byte "pqrstuvwxyz{|}~",$ff,0
testStr3:
	.byte "x",0

testTitle0:
	.byte "Nifty Window",0
testTitle1:
	.byte "Okay",0
testTitle2:
	.byte "Cancel",0
testTitle3:
	.byte "More Magic",0




; Suppress some linker warnings - Must be the last thing in the file
.SEGMENT "ZPSAVE"
.SEGMENT "EXEHDR"
.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "LOWCODE"

