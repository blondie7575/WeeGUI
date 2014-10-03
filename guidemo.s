;
;  guidemo.s
;  AssemblyTest
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


.org $6000

; Reserved locations
PARAM0			= $06
PARAM1			= $07
PARAM2			= $08
PARAM3			= $09


; WeeGUI entry points
WeeGUI = $4004

WGClearScreen = 0
WGDesktop = 2
WGPlot = 4
WGSetCursor = 6
WGSetGlobalCursor = 8


; Sample code
main:
	ldx #WGClearScreen
	jsr WeeGUI

	ldx #WGDesktop
	jsr WeeGUI

	lda #40
	sta PARAM0
	lda #12
	sta PARAM1
	ldx #WGSetGlobalCursor
	jsr WeeGUI

	lda #'Q'+$80
	ldx #WGPlot
	jsr WeeGUI

	rts

.if 0
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
	lda #10
	sta PARAM0
	lda #15
	sta PARAM1
	jsr WGSetCursor
	CALL16 WGPrint,testStr

	bra testPaintContents_done
;;


	ldy #0
testPaintContents_loop:
	ldx #0
	stx PARAM0
	sty PARAM1
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

	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

.endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Suppress some linker warnings - Must be the last thing in the file
.SEGMENT "ZPSAVE"
.SEGMENT "EXEHDR"
.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "LOWCODE"
