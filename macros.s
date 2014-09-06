;
;  macros.s
;  Generally useful macros for 6502 code
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


; Macros

.macro SETSWITCH name		; Sets the named softswitch (assumes write method)
	sta name
.endmacro


.macro SAVE_AXY				; Saves all registers
	pha
	txa
	pha
	tya
	pha
.endmacro


.macro RESTORE_AXY			; Restores all registers
	pla
	tay
	pla
	tax
	pla
.endmacro


.macro SAVE_AY				; Saves accumulator and Y index
	pha
	tya
	pha
.endmacro


.macro RESTORE_AY			; Restores accumulator and Y index
	pla
	tay
	pla
.endmacro


.macro SAVE_AX				; Saves accumulator and X index
	pha
	txa
	pha
.endmacro


.macro RESTORE_AX			; Restores accumulator and X index
	pla
	tax
	pla
.endmacro


.macro SAVE_ZPP				; Saves Zero Page locations we use for parameters
	lda	PARAM0
	pha
	lda PARAM1
	pha
	lda PARAM2
	pha
	lda PARAM3
	pha
.endmacro


.macro RESTORE_ZPP			; Restores Zero Page locations we use for parameters
	pla
	sta PARAM3
	pla
	sta PARAM2
	pla
	sta PARAM1
	pla
	sta PARAM0
.endmacro


.macro SAVE_ZPS				; Saves Zero Page locations we use for scratch
	lda	SCRATCH0
	pha
	lda SCRATCH1
	pha
.endmacro


.macro RESTORE_ZPS			; Restores Zero Page locations we use for scratch
	pla
	sta	SCRATCH1
	pla
	sta	SCRATCH0
.endmacro


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Rendering macros
;

.macro LDY_ACTIVEVIEW
	lda WG_ACTIVEVIEW	; Find our new view record
	asl
	asl
	asl
	asl				; Records are 16 bytes wide
	tay
.endmacro


.macro LDX_ACTIVEVIEW
	lda WG_ACTIVEVIEW	; Find our new view record
	asl
	asl
	asl
	asl				; Records are 16 bytes wide
	tax
.endmacro


.macro LDY_FOCUSVIEW
	lda WG_FOCUSVIEW	; Find our new view record
	asl
	asl
	asl
	asl				; Records are 16 bytes wide
	tay
.endmacro


.macro VBL_SYNC				; Synchronize with vertical blanking
	lda #$80
macroWaitVBLToFinish:
	bit	RDVBLBAR
	bmi	macroWaitVBLToFinish
macroWaitVBLToStart:
	bit	RDVBLBAR
	bpl	macroWaitVBLToStart
.endmacro
