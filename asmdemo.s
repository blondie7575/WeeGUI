;
;  asmdemo.s
;  WeeGUI sample application
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2015 One Girl, One Laptop Productions. All rights reserved.
;


.include "WeeGUI_MLI.s"


.org $6000

INBUF			= $0200
DOSCMD			= $be03
KBD				= $c000
KBDSTRB			= $c010


main:

	; BRUN the GUI library
	ldx #0
	ldy #0
@0:	lda brunCmdLine,x
	beq @1
	sta INBUF,y
	inx
	iny
	bra @0
@1:	jsr DOSCMD


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #WGDesktop
	jsr WeeGUI
	
	lda #<progressData
	sta PARAM0
	lda #>progressData
	sta PARAM1
	ldx #WGCreateProgress
	jsr WeeGUI

	ldx #WGPaintView
	jsr WeeGUI

	ldx #WGExit
	jsr WeeGUI

	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

progressData:
	.byte 0,20,5,30

brunCmdLine:
	.byte "BRUN weegui",$8d,0

; Suppress some linker warnings - Must be the last thing in the file
.SEGMENT "ZPSAVE"
.SEGMENT "EXEHDR"
.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "LOWCODE"
