;
;  guidemo.s
;  WeeGUI sample application
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


.include "WeeGUI_MLI.s"


.org $6000

INBUF			= $0200
DOSCMD			= $be03
KBD				= $c000
KBDSTRB			= $c010


.macro WGCALL16 func,addr
	lda #<addr
	sta PARAM0
	lda #>addr
	sta PARAM1
	ldx #func
	jsr WeeGUI
.endmacro


; Sample code
main:

	; BRUN the GUI library
	ldx #0
	ldy #0
@0:	lda bloadCmdLine,x
	beq @1
	sta INBUF,y
	inx
	iny
	bra @0
@1:	jsr DOSCMD


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Show off some WeeGUI features

	;jmp	tortureTestPrint
	jmp	tortureTestRects
	ldx #WGClearScreen
	jsr WeeGUI

	ldx #WGEnableMouse
	jsr WeeGUI

	ldx #WGDesktop
	jsr WeeGUI

	WGCALL16 WGCreateView,testView
	WGCALL16 WGViewSetAction,testPaintContentsClick
	WGCALL16 WGViewSetTitle,testTitle0
	WGCALL16 WGCreateCheckbox,testCheck
	WGCALL16 WGCreateButton,testButton1
	WGCALL16 WGCreateButton,testButton2

	ldx #WGViewPaintAll
	jsr WeeGUI

	lda #0
	ldx #WGSelectView
	jsr WeeGUI

;	jsr testPaintContents

keyLoop:
	ldx #WGPendingViewAction
	jsr WeeGUI

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
	ldx #WGViewFocusNext
	jsr WeeGUI
	jmp keyLoop

keyLoop_focusPrev:
	ldx #WGViewFocusPrev
	jsr WeeGUI
	jmp keyLoop

keyLoop_toggle:
	ldx #WGViewFocusAction
	jsr WeeGUI
	jmp keyLoop

keyLoop_leftArrow:
	lda #1
	ldx #WGScrollXBy
	jsr WeeGUI
	jsr testPaintContents
	jmp keyLoop

keyLoop_rightArrow:
	lda #-1
	ldx #WGScrollXBy
	jsr WeeGUI
	jsr testPaintContents
	jmp keyLoop

keyLoop_upArrow:
	lda #1
	ldx #WGScrollYBy
	jsr WeeGUI
	jsr testPaintContents
	jmp keyLoop

keyLoop_downArrow:
	lda #-1
	ldx #WGScrollYBy
	jsr WeeGUI
	jsr testPaintContents
	jmp keyLoop

keyLoop_focusOkay:
	lda #2
	ldx #WGSelectView
	jsr WeeGUI
	ldx #WGViewFocus
	jsr WeeGUI
	jmp keyLoop

keyLoop_quit:
	ldx #WGDisableMouse
	jsr WeeGUI
	ldx #WGExit
	jsr WeeGUI
	
	rts

testPaintContentsClick:
;	brk

testPaintContents:
	lda #0
	ldx #WGSelectView
	jsr WeeGUI
	ldx #WGEraseViewContents
	jsr WeeGUI

	stz PARAM0
	stz PARAM1
	ldx #WGSetCursor
	jsr WeeGUI

;	ldy #0
;testPaintContents_loop:
;	ldx #0
;	stx PARAM0
;	sty PARAM1
;	ldx #WGSetCursor
;	jsr WeeGUI

;	tya
;	clc
;	adc #'A'
;	sta testStr3
;
;	WGCALL16 WGPrint,testStr3
;
;	iny
;	cpy #25
;	bne testPaintContents_loop

	WGCALL16 WGPrint,testStr

testPaintContents_done:
	rts



testCallback:
	jsr $ff3a		; boop!
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bloadCmdLine:
	.byte "BRUN weegui",$8d,0

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
	.byte "@ABCDEFGHIJKLMNOPQ",13,"RSTUVWXYZ[\]^_ !",34,"#$%&'()*+,-./0123456789:;<=>?`abcdefghijklmno"
testStr2:
	.byte "pqrstuvwxyz",0;//{|}~",$ff,0
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.include "unit_test.s"



; Suppress some linker warnings - Must be the last thing in the file
.SEGMENT "ZPSAVE"
.SEGMENT "EXEHDR"
.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "LOWCODE"
