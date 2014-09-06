;
;  gui.s
;  AssemblyTest
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


.org $4000


; Common definitions

.include "switches.s"
.include "macros.s"


; Main

main:
	jsr WGInit
	jsr WG80
	;jmp	tortureTestPrint
	;jmp	tortureTestRects

	jsr WGClearScreen

	lda	#<testView
	sta	PARAM0
	lda	#>testView
	sta	PARAM1
	jsr	WGCreateView

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

;	ldx	#5
;	ldy	#0
;	jsr	WGSetCursor

;	lda	#0
;	jsr	WGScrollX
;	lda	#-2
;	jsr	WGScrollY

;	lda WG_VIEWCLIP+0
;	jsr PRBYTE
;	lda WG_VIEWCLIP+1
;	jsr PRBYTE
;	lda WG_VIEWCLIP+2
;	jsr PRBYTE
;	lda WG_VIEWCLIP+3
;	jsr PRBYTE
;	lda WG_VIEWCLIP+4
;	jsr PRBYTE

;	lda WG_VIEWRECORDS+0
;	jsr PRBYTE
;	lda WG_VIEWRECORDS+1
;	jsr PRBYTE
;	lda WG_VIEWRECORDS+2
;	jsr PRBYTE
;	lda WG_VIEWRECORDS+3
;	jsr PRBYTE
;	lda WG_VIEWRECORDS+4
;	jsr PRBYTE
;	lda WG_VIEWRECORDS+5
;	jsr PRBYTE
;	lda WG_VIEWRECORDS+6
;	jsr PRBYTE
;	lda WG_VIEWRECORDS+7
;	jsr PRBYTE
;	lda WG_VIEWRECORDS+8
;	jsr PRBYTE

;	lda	#<testStr
;	sta	PARAM0
;	lda #>testStr
;	sta PARAM1
;	jsr WGPrint

;	lda	#1
;	sta PARAM0
;	lda	#1
;	sta	PARAM1
;	lda #2
;	sta	PARAM2
;	lda	#2
;	sta	PARAM3
;	ldx	#'Q'+$80
;	jsr	WGFillRect
;	jsr	WGStrokeRect
;	jmp loop
;	jsr	waitForKey

;	jmp tortureTestRects

keyLoop:
	lda KBD
	bpl keyLoop
	sta KBDSTRB

	and #%01111111
	cmp #9
	beq keyLoop_focusNext
	cmp #13
	beq keyLoop_toggle
	cmp #32
	beq keyLoop_toggle

	jmp keyLoop

keyLoop_focusNext:
	jsr WGViewFocusNext
	jmp keyLoop

keyLoop_toggle:
	jsr WGViewFocusAction
	jmp keyLoop
	
	rts			; This seems to work for returning to BASIC.SYSTEM, but I don't think it's right
	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGInit
; Initialization. Should be called once at app startup
WGInit:
	pha

	lda	#0
	sta WG_FOCUSVIEW

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
.include "views.s"
.include "unit_test.s"
.include "memory.s"


testView:
	.byte "0007033e133e7e"	; 0, 7,3,62,19,62,126

testCheck:
	.byte "011004"

testButton1:
	.byte "02230a0f"

testButton2:
	.byte "03230d0f"

testStr:
;	.byte "This is a test of the emergency broadcast system.",0; If this had been a real emergency, you would be dead now.",0	; 107 chars
	.byte "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_ !",34,"#$%&'()*+,-./0123456789:;<=>?`abcdefghijklmno",0
testStr2:
	.byte "pqrstuvwxyz{|}~",$ff,0
testTitle1:
	.byte "Okay",0
testTitle2:
	.byte "Cancel",0


