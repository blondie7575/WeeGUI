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

	lda	#<testView
	sta	PARAM0
	lda	#>testView
	sta	PARAM1
	jsr	WGCreateView

	lda #<testTitle0
	sta PARAM0
	lda #>testTitle0
	sta PARAM1
	jsr WGViewSetTitle

	lda	#<testCheck
	sta	PARAM0
	lda	#>testCheck
	sta	PARAM1
	jsr	WGCreateCheckbox

	lda	#<testButton1
	sta	PARAM0
	lda	#>testButton1
	sta	PARAM1
	jsr	WGCreateButton

	lda #<testTitle1
	sta PARAM0
	lda #>testTitle1
	sta PARAM1
	jsr WGViewSetTitle

	lda #<testCallback
	sta PARAM0
	lda #>testCallback
	sta PARAM1
	jsr WGViewSetAction

	lda	#<testButton2
	sta	PARAM0
	lda	#>testButton2
	sta	PARAM1
	jsr	WGCreateButton

	lda #<testTitle2
	sta PARAM0
	lda #>testTitle2
	sta PARAM1
	jsr WGViewSetTitle

	jsr WGViewPaintAll
;	jsr testPaintContents

;	ldx	#5
;	ldy	#0
;	jsr	WGSetCursor

;	lda	#0
;	jsr	WGScrollX
;	lda	#-2
;	jsr	WGScrollY


keyLoop:
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

	rts			; This seems to work for returning to BASIC.SYSTEM, but I don't think it's right

testPaintContents:
	SAVE_AXY

	lda #0
	jsr WGSelectView
	jsr WGEraseViewContents


;;
	jsr WGNormal
	ldx #0
	ldy #4
	jsr WGSetCursor
	lda #<testStr
	sta PARAM0
	lda #>testStr
	sta PARAM1
	jsr WGPrint
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

	lda #<testStr3
	sta PARAM0
	lda #>testStr3
	sta PARAM1
	jsr WGPrint

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
	pha

	jsr WGInitApplesoft

	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WG80
; Enables 80 column mode (and enhanced video firmware)
WG80:
	lda	#$a0
	jsr	$c300
	SETSWITCH	TEXTON
	SETSWITCH	PAGE2OFF
	SETSWITCH	COL80ON
	SETSWITCH	STORE80ON
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
.include "applesoft.s"
.include "unit_test.s"
.include "memory.s"


testView:
	.byte 0,1,7,3,62,18,80,25

testCheck:
	.byte 1,16,4

testButton1:
	.byte 2,35,10,15

testButton2:
	.byte 3,35,13,15

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




; Suppress some linker warnings - Must be the last thing in the file
.SEGMENT "ZPSAVE"
.SEGMENT "EXEHDR"
.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "LOWCODE"

