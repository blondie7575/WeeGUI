;
;  mouse.s
;  Routines for handling the mouse
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ProDOS ROM entry points and constants
;
PRODOS_MLI = $bf00

ALLOC_INTERRUPT = $40
DEALLOC_INTERRUPT = $41


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mouse firmware ROM entry points and constants
;

; These mouse firmware entry points are offsets from the firmware
; entry point of the slot, and also indirect.
SETMOUSE = $12
SERVEMOUSE = $13
READMOUSE = $14
CLEARMOUSE = $15
POSMOUSE = $16
CLAMPMOUSE = $17
HOMEMOUSE = $18
INITMOUSE = $19

MOUSTAT = $0778			; + Slot Num
MOUSE_XL = $0478		; + Slot Num
MOUSE_XH = $0578		; + Slot Num
MOUSE_YL = $04f8		; + Slot Num
MOUSE_YH = $05f8		; + Slot Num
MOUSE_CLAMPL = $04f8	; Upper mouse clamp (LSB). Slot independent.
MOUSE_CLAMPH = $05f8	; Upper mouse clamp (MSB). Slot independent.
MOUSE_ZEROL = $0478		; Zero value of mouse (LSB). Slot independent.
MOUSE_ZEROH = $0578		; Zero value of mouse (MSB). Slot independent.

MOUSTAT_MASK_BUTTONINT = %00000100
MOUSTAT_MASK_MOVEINT = %00000010
MOUSTAT_MASK_DOWN = %10000000
MOUSTAT_MASK_WASDOWN = %01000000
MOUSTAT_MASK_MOVED = %00100000

MOUSEMODE_OFF = $00		; Mouse off
MOUSEMODE_PASSIVE = $01	; Passive mode (polling only)
MOUSEMODE_MOVEINT = $03	; Interrupts on movement
MOUSEMODE_BUTINT = $05	; Interrupts on button
MOUSEMODE_COMBINT = $07	; Interrupts on movement and button


; Mouse firmware is all indirectly called, because
; it moved around a lot in different Apple ][ ROM
; versions. This macro helps abstracts this for us.
.macro CALLMOUSE name
	ldx #name
	jsr WGCallMouse
.endmacro


CH_MOUSEPOINTER = 'B'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGEnableMouse
; Prepares the mouse for use
;
WGEnableMouse:
	pha

	SETSWITCH PAGE2OFF

	; Find slot number and calculate the various indirections needed
	jsr WGFindMouse
	bcs WGEnableMouse_Error

	; Note if we're a //e or //c, because mouse tracking and interrupts are different
	lda $fbb3
	cmp #$06
	bne WGEnableMouse_Error		; II or II+? Sorry...
	lda $fbc0
	bne WGEnableMouse_IIe
	lda #1
	sta WG_APPLEIIC

WGEnableMouse_IIe:
	; Install our interrupt handler via ProDOS (play nice!)
	jsr PRODOS_MLI
	.byte ALLOC_INTERRUPT
	.addr WG_PRODOS_ALLOC
	bne WGEnableMouse_Error		; ProDOS will return here with Z clear on error

	; Initialize the mouse
	stz WG_MOUSEPOS_X
	stz WG_MOUSEPOS_Y
	stz WG_MOUSEBG

	CALLMOUSE INITMOUSE
	bcs WGEnableMouse_Error	; Firmware sets carry if mouse is not available

	CALLMOUSE CLEARMOUSE

	lda #MOUSEMODE_COMBINT		; Enable combination interrupt mode
	CALLMOUSE SETMOUSE

	; Set the mouse's zero postion to (1,1), since we're in text screen space
	stz MOUSE_ZEROH
	lda #0
	sta MOUSE_ZEROL
	lda #1
	CALLMOUSE CLAMPMOUSE
	lda #0
	CALLMOUSE CLAMPMOUSE

	; Scale the mouse's range into something easy to do math with,
	; while retaining as much range of motion and precision as possible
	lda WG_APPLEIIC
	bne WGEnableMouse_ConfigIIc

	lda #$7f			; 640 - 1 horizontally
	sta MOUSE_CLAMPL
	lda #$02
	sta MOUSE_CLAMPH
	lda #0
	CALLMOUSE CLAMPMOUSE

	lda #$e0			; 736 vertically
	sta MOUSE_CLAMPL
	lda #$02
	sta MOUSE_CLAMPH
	lda #1
	CALLMOUSE CLAMPMOUSE
	bra WGEnableMouse_Activate

WGEnableMouse_Error:
	stz WG_MOUSEACTIVE

WGEnableMouse_done:			; Exit point here for branch range
	pla
	rts

WGEnableMouse_ConfigIIc:	; //c's tracking is weird. Need to clamp to a much smaller range
	lda #$4f				; 80 - 1 horizontally
	sta MOUSE_CLAMPL
	lda #$00
	sta MOUSE_CLAMPH
	lda #0
	CALLMOUSE CLAMPMOUSE

	lda #$17			; 24 - 1 vertically
	sta MOUSE_CLAMPL
	lda #$00
	sta MOUSE_CLAMPH
	lda #1
	CALLMOUSE CLAMPMOUSE

WGEnableMouse_Activate:
	lda #1
	sta WG_MOUSEACTIVE

	cli					; Once all setup is done, it's safe to enable interrupts
	bra WGEnableMouse_done



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDisableMouse
; Shuts off the mouse when we're done with it
;
WGDisableMouse:
	pha

	SETSWITCH PAGE2OFF

	lda WG_MOUSEACTIVE			; Never activated the mouse
	beq WGDisableMouse_done

	lda MOUSEMODE_OFF
	CALLMOUSE SETMOUSE

	stz WG_MOUSEACTIVE

	; Remove our interrupt handler via ProDOS (done playing nice!)
	lda WG_PRODOS_ALLOC+1		; Copy interrupt ID that ProDOS gave us
	sta WG_PRODOS_DEALLOC+1

	jsr PRODOS_MLI
	.byte DEALLOC_INTERRUPT
	.addr WG_PRODOS_DEALLOC

	jsr WGUndrawPointer			; Be nice if we're disabled during a program

WGDisableMouse_done:
	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGCallMouse
; Calls a mouse firmware routine. Here's where we handle all
; the layers of indirection needed to call mouse firmware. The
; firmware moved in ROM several times over the life of the
; Apple ][, so it's kind of a hassle to call it.
; X: Name of routine (firmware offset constant)
; Side effects: Clobbers all registers
WGCallMouse:
	stx WGCallMouse+4	; Use self-modifying code to smooth out some indirection

	; This load address is overwritten by the above code, AND by the mouse set
	; up code, to make sure we have the right slot entry point and firmware
	; offset
	ldx $c400			; Self-modifying code!
	stx WG_MOUSE_JUMPL	; Get low byte of final jump from firmware

	php					; Note that mouse firmware is not re-entrant,
	sei					; so we must disable interrupts inside them

	jsr WGCallMouse_redirect
	plp					; Restore interrupts to previous state
	rts

WGCallMouse_redirect:
	ldx WG_MOUSE_JUMPH
	ldy WG_MOUSE_SLOTSHIFTED
	jmp (WG_MOUSE_JUMPL)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGFindMouse
; Figures out which slot (//e) or port (//c) the mouse is in.
; It moved around a lot over the years. Sets it to 0 if no mouse
; could be found
; OUT C: Set if no mouse could be found
WGFindMouse:
	SAVE_AX

	ldx #7

WGFindMouse_loop:
	txa							; Compute slot firmware locations for this loop
	ora #$c0
	sta WGFindMouse_loopModify+2		; Self-modifying code!
	sta WGFindMouse_loopModify+9
	sta WGFindMouse_loopModify+16
	sta WGFindMouse_loopModify+23
	sta WGFindMouse_loopModify+30

WGFindMouse_loopModify:
	; Check for the magic 5-byte pattern that gives away the mouse card
	lda $c005					; These addresses are modified in place on
	cmp #$38					; each loop iteration
	bne WGFindMouse_nextSlot
	lda $c007
	cmp #$18
	bne WGFindMouse_nextSlot
	lda $c00b
	cmp #$01
	bne WGFindMouse_nextSlot
	lda $c00c
	cmp #$20
	bne WGFindMouse_nextSlot
	lda $c0fb
	cmp #$d6
	bne WGFindMouse_nextSlot
	bra WGFindMouse_found

WGFindMouse_nextSlot:
	dex
	bmi WGFindMouse_none
	bra WGFindMouse_loop

WGFindMouse_found:
	; Found it! Now configure all our indirection lookups
	stx WG_MOUSE_SLOT
	lda #$c0
	ora WG_MOUSE_SLOT
	sta WG_MOUSE_JUMPH
	sta WGCallMouse+5			; Self-modifying code!
	txa
	asl
	asl
	asl
	asl
	sta WG_MOUSE_SLOTSHIFTED
	clc
	bra WGFindMouse_done

WGFindMouse_none:
	stz WG_MOUSE_SLOT
	sec

WGFindMouse_done:
	RESTORE_AX
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGMouseInterruptHandler
; Handles interrupts that may be related to the mouse
; This is a ProDOS-compliant interrupt handling routine, and
; should be installed and removed via ProDOS as needed.
; 
; IMPORTANT: This routine is NOT MLI-reentrant, which means MLI
; calls can NOT be made within this handler. See page 108 of the
; ProDOS 8 Technical Reference Manual if this feature needs to be
; added.
;
WGMouseInterruptHandler:
	cld						; ProDOS interrupt handlers must open with this
	SAVE_AXY

	CALLMOUSE SERVEMOUSE
	bcs WGMouseInterruptHandler_disregard

	php
	sei

	lda PAGE2			; Need to preserve text bank, because we may interrupt rendering
	pha
	SETSWITCH	PAGE2OFF

	ldx WG_MOUSE_SLOT
	lda MOUSTAT,x			; Check interrupt status bits first, because READMOUSE clears them
	and #MOUSTAT_MASK_BUTTONINT
	bne WGMouseInterruptHandler_button

	jsr WGUndrawPointer			; Erase the old mouse pointer

	; Read the mouse state. Note that interrupts need to remain
	; off until after the data is copied.
	CALLMOUSE READMOUSE

	ldx WG_MOUSE_SLOT
	lda MOUSTAT,x			; Movement/button status bits are now valid
	sta WG_MOUSE_STAT

	lda WG_APPLEIIC
	bne WGMouseInterruptHandler_IIc

	; Read mouse position and transform it into screen space
	lsr MOUSE_XH,x
	ror MOUSE_XL,x
	lsr MOUSE_XH,x
	ror MOUSE_XL,x
	lsr MOUSE_XH,x
	ror MOUSE_XL,x

	lda MOUSE_XL,x
	sta WG_MOUSEPOS_X

	lsr MOUSE_YH,x
	ror MOUSE_YL,x
	lsr MOUSE_YH,x
	ror MOUSE_YL,x
	lsr MOUSE_YH,x
	ror MOUSE_YL,x
	lsr MOUSE_YH,x
	ror MOUSE_YL,x
	lsr MOUSE_YH,x
	ror MOUSE_YL,x

	lda MOUSE_YL,x
	sta WG_MOUSEPOS_Y
	bra WGMouseInterruptHandler_draw

WGMouseInterruptHandler_IIc:		; IIc tracks much slower, so don't scale
	lda MOUSE_XL,x
	sta WG_MOUSEPOS_X
	lda MOUSE_YL,x
	sta WG_MOUSEPOS_Y

WGMouseInterruptHandler_draw:
	jsr WGDrawPointer				; Redraw the pointer
	bra WGMouseInterruptHandler_intDone

WGMouseInterruptHandler_disregard:
	; Carry will still be set here, to notify ProDOS that
	; this interrupt was not ours
	RESTORE_AXY
	rts

WGMouseInterruptHandler_button:
	CALLMOUSE READMOUSE
	ldx WG_MOUSE_SLOT
	lda MOUSTAT,x			; Movement/button status bits are now valid
	sta WG_MOUSE_STAT

	bit WG_MOUSE_STAT			; Check for rising edge of button state
	bpl WGMouseInterruptHandler_intDone
	bvs WGMouseInterruptHandler_intDone		; Held, so ignore (//c only, but more elegant code to leave in for both)

	; Button went down, so make a note of location for later
	lda WG_MOUSEPOS_X
	sta WG_MOUSECLICK_X
	lda WG_MOUSEPOS_Y
	sta WG_MOUSECLICK_Y

WGMouseInterruptHandler_intDone:
	pla						; Restore text bank
	bpl WGMouseInterruptHandler_intDoneBankOff
	SETSWITCH	PAGE2ON
	bra WGMouseInterruptHandler_done

WGMouseInterruptHandler_intDoneBankOff:
	SETSWITCH	PAGE2OFF

WGMouseInterruptHandler_done:
	RESTORE_AXY

	plp
	clc								; Notify ProDOS this was our interrupt
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGUndrawPointer
; Unplots the mouse pointer at current location
; Side effects: Clobbers BASL,BASH
;
WGUndrawPointer:
	pha
	lda #$80
	jsr renderPointer
	pla
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDrawPointer
; Plots the mouse pointer at current location
;
WGDrawPointer:
	pha
	lda #0
	jsr renderPointer
	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGPointerDirty
; Updates the background behind the mouse pointer without
; modifying it's current render state. Assumes pointer is not
; currently visible
;
WGPointerDirty:
	pha
	lda #%11000000
	jsr renderPointer
	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; renderPointer
; Performs mouse-pointer-related rendering
; A: 0=draw, %10000000=undraw, %11000000=recapture background
;
renderPointer:
	SAVE_AXY
	sta renderPointerMode
	lda BASL			; Need to preserve BAS, because we may interrupt rendering
	pha
	lda BASH
	pha
	lda PAGE2			; Need to preserve text bank, because we may interrupt rendering
	pha

	lda WG_MOUSEACTIVE
	beq renderPointer_done	; Mouse not enabled

	ldx	WG_MOUSEPOS_Y
	cpx #24
	bcs renderPointer_done	; Mouse out of range (vertically)

	lda TEXTLINES_L,x	; Compute video memory address of point
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda	WG_MOUSEPOS_X
	cmp #80
	bcs renderPointer_done	; Mouse out of range (horizontally)

	lsr
	clc
	adc	BASL
	sta BASL
	lda	#0
	adc BASH
	sta BASH

	lda	WG_MOUSEPOS_X		; X even?
	ror
	bcs	renderPointer_xOdd

	SETSWITCH	PAGE2ON

	bit renderPointerMode	; Draw or undraw?
	bpl renderPointer_draw
	bvc renderPointer_undraw

renderPointer_draw:
	lda (BASL)				; Save background
	cmp #CH_MOUSEPOINTER	; Make sure we never capture ourselves and leave a "stamp"
	beq renderPointer_drawSaved
	sta WG_MOUSEBG

renderPointer_drawSaved:
	bit renderPointerMode	; Recapture or draw?
	bvs renderPointer_done

	lda	#CH_MOUSEPOINTER	; Draw the pointer
	sta	(BASL)
	bra renderPointer_done

renderPointer_undraw:
	lda	WG_MOUSEBG
	beq	renderPointer_done	; No saved background yet
	sta	(BASL)
	bra renderPointer_done

renderPointer_xOdd:
	SETSWITCH	PAGE2OFF

	bit renderPointerMode	; Draw or undraw?
	bpl renderPointer_drawOdd
	bvc renderPointer_undraw

renderPointer_drawOdd:
	lda (BASL)				; Save background
	cmp #CH_MOUSEPOINTER	; Make sure we never capture ourselves and leave a "stamp"
	beq renderPointer_drawOddSaved
	sta WG_MOUSEBG

renderPointer_drawOddSaved:
	bit renderPointerMode	; Recapture or draw?
	bvs renderPointer_done

	lda	#CH_MOUSEPOINTER	; Draw the pointer
	sta	(BASL)
	bra renderPointer_done

renderPointer_done:
	pla						; Restore text bank
	bpl renderPointer_doneBankOff
	SETSWITCH	PAGE2ON
	bra renderPointer_doneBAS

renderPointer_doneBankOff:
	SETSWITCH	PAGE2OFF

renderPointer_doneBAS:
	pla						; Restore BAS
	sta BASH
	pla
	sta BASL

	RESTORE_AXY
	rts

renderPointerMode:
	.byte 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mouse API state
;
WG_MOUSEACTIVE:
.byte 0

WG_MOUSEPOS_X:
.byte 39
WG_MOUSEPOS_Y:
.byte 11
WG_MOUSE_STAT:
.byte 0
WG_MOUSEBG:
.byte 0
WG_APPLEIIC:
.byte 0
WG_MOUSE_JUMPL:
.byte 0
WG_MOUSE_JUMPH:
.byte 0
WG_MOUSE_SLOT:
.byte 0
WG_MOUSE_SLOTSHIFTED:
.byte 0

WG_MOUSECLICK_X:
.byte $ff
WG_MOUSECLICK_Y:
.byte 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ProDOS system call parameter blocks
;
WG_PRODOS_ALLOC:
	.byte 2
	.byte 0						; ProDOS returns an ID number for the interrupt here
	.addr WGMouseInterruptHandler

WG_PRODOS_DEALLOC:
	.byte 1
	.byte 0						; To be filled with ProDOS ID number


