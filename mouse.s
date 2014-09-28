;
;  mouse.s
;  Routines for handling the mouse
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mouse firmware ROM entry points and constants
;
SETMOUSE = $c412		; Indirect
SERVEMOUSE = $c413		; Indirect
READMOUSE = $c414		; Indirect
CLEARMOUSE = $c415		; Indirect
POSMOUSE = $c416		; Indirect
CLAMPMOUSE = $c417		; Indirect
HOMEMOUSE = $c418		; Indirect
INITMOUSE = $c419		; Indirect

MOUSTAT = $0778			; + Slot Num
MOUSE_XL = $0478		; + Slot Num
MOUSE_XH = $0578		; + Slot Num
MOUSE_YL = $04f8		; + Slot Num
MOUSE_YH = $05f8		; + Slot Num
MOUSE_CLAMPL = $04f8
MOUSE_CLAMPH = $05f8

MOUSTAT_MASK_BUTTONINT = %00000100
MOUSTAT_MASK_MOVEINT = %00000010
MOUSTAT_MASK_DOWN = %10000000
MOUSTAT_MASK_HELD = %01000000
MOUSTAT_MASK_MOVED = %00100000

MOUSEMODE_OFF = $00		; Mouse off
MOUSEMODE_PASSIVE = $01	; Passive mode (polling only)
MOUSEMODE_MOVEINT = $03	; Interrupts on movement
MOUSEMODE_BUTINT = $05	; Interrupts on button
MOUSEMODE_COMBINT = $07	; Interrupts on movement and button


.macro CALLMOUSE name	; Mouse firmware is all indirectly called, because
	pha
	lda name			; it moved around a lot in different Apple ][ ROM
	sta WG_MOUSE_JUMPL	; versions. This macro abstracts this for us.

	pla
	php					; Note that mouse firmware is not re-entrant,
	sei					; so we must disable interrupts inside them

	phx
	phy
	jsr WGEnableMouse_CallFirmware
	ply
	plx

	plp

.endmacro


CH_MOUSEPOINTER = 'B'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGEnableMouse
; Prepares the mouse for use
;
WGEnableMouse:
	pha

	; Find slot number and calculate the various indirections needed
	lda #$4
	sta WG_MOUSE_SLOT
	lda #$c0
	ora WG_MOUSE_SLOT
	sta WG_MOUSE_JUMPH
	lda WG_MOUSE_SLOT
	asl
	asl
	asl
	asl
	sta WG_MOUSE_SLOTSHIFTED

	; Install our interrupt handler
	lda #<WGMouseInterruptHandler
	sta IRQVECTORL
	lda #>WGMouseInterruptHandler
	sta IRQVECTORH

	; Initialize the mouse
	lda #0
	sta WG_MOUSEPOS_X
	sta WG_MOUSEPOS_Y
	sta WG_MOUSEBG
	
	CALLMOUSE INITMOUSE
	bcs WGEnableMouse_Error	; Firmware sets carry if mouse is not available

	CALLMOUSE CLEARMOUSE

	lda #MOUSEMODE_COMBINT
	CALLMOUSE SETMOUSE

	; Scale the mouse's range into something ease to do math with,
	; while retaining as much range of motion and precision as possible
	lda #$80			; 640 horizontally
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

	lda #1
	sta WG_MOUSEACTIVE

	cli
	bra WGEnableMouse_done

WGEnableMouse_Error:
	lda #0
	sta WG_MOUSEACTIVE

WGEnableMouse_done:
	pla
	rts

WGEnableMouse_CallFirmware:
	ldx WG_MOUSE_JUMPH
	ldy WG_MOUSE_SLOTSHIFTED
	jmp (WG_MOUSE_JUMPL)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDisableMouse
; Shuts off the mouse when we're done with it
;
WGDisableMouse:
	pha

	lda MOUSEMODE_OFF
	CALLMOUSE SETMOUSE

	lda #0
	sta WG_MOUSEACTIVE

	pla
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGMouseInterruptHandler
; Handles interrupts that may be related to the mouse
;
WGMouseInterruptHandler:
	SAVE_AXY
	SETSWITCH	PAGE2OFF	; Turn this off so we don't mess up page 4 screen holes!

	CALLMOUSE SERVEMOUSE
	bcs WGMouseInterruptHandler_disregard

	CALLMOUSE READMOUSE

	jsr WGUndrawPointer			; Prepare to move the pointer

	; Read mouse position and divide by 16 to get into our screen space
	ldx WG_MOUSE_SLOT
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

	lda MOUSTAT,x
	and #MOUSTAT_MASK_DOWN
	bne WGMouseInterruptHandler_button

	bra WGMouseInterruptHandler_intDone

WGMouseInterruptHandler_button:
	jsr BELL

WGMouseInterruptHandler_intDone:
	jsr WGDrawPointer				; Redraw the pointer

	RESTORE_AXY

WGMouseInterruptHandler_disregard:
	rti



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGUndrawPointer
; Unplots the mouse pointer at current location
; Side effects: Clobbers BASL,BASH
;
WGUndrawPointer:
	SAVE_AXY

	lda WG_MOUSEBG
	beq WGUndrawPointer_done	; Mouse pointer has never rendered

	ldx	WG_MOUSEPOS_Y
	cpx #24
	bcs WGUndrawPointer_done

	lda TEXTLINES_L,x	; Compute video memory address of point
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda	WG_MOUSEPOS_X
	cmp #80
	bcs WGUndrawPointer_done

	lsr
	clc
	adc	BASL
	sta BASL
	lda	#$0
	adc BASH
	sta BASH

	lda	WG_MOUSEPOS_X		; X even?
	and	#$01
	bne	WGUndrawPointer_xOdd

	SETSWITCH	PAGE2ON		; Restore the background
	ldy	#$0
	lda	WG_MOUSEBG
	sta	(BASL),y
	bra WGUndrawPointer_done

WGUndrawPointer_xOdd:
	SETSWITCH	PAGE2OFF	; Restore the background
	ldy	#$0
	lda	WG_MOUSEBG
	sta	(BASL),y

WGUndrawPointer_done:
	SETSWITCH	PAGE2OFF	; Turn this off so we don't mess up page 4 screen holes!
	RESTORE_AXY
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDrawPointer
; Plots the mouse pointer at current location
; Side effects: Clobbers BASL,BASH
;
WGDrawPointer:
	SAVE_AXY

	ldx	WG_MOUSEPOS_Y
	cpx #24
	bcs WGDrawPointer_done

	lda TEXTLINES_L,x	; Compute video memory address of point
	sta BASL
	lda TEXTLINES_H,x
	sta BASH

	lda	WG_MOUSEPOS_X
	cmp #80
	bcs WGDrawPointer_done

	lsr
	clc
	adc	BASL
	sta BASL
	lda	#$0
	adc BASH
	sta BASH

	lda	WG_MOUSEPOS_X		; X even?
	and	#$01
	bne	WGDrawPointer_xOdd

	SETSWITCH	PAGE2ON
	ldy	#$0
	lda (BASL),y			; Save background
	sta WG_MOUSEBG
	lda	#CH_MOUSEPOINTER	; Draw the pointer
	sta	(BASL),y
	bra WGDrawPointer_done

WGDrawPointer_xOdd:
	SETSWITCH	PAGE2OFF
	ldy	#$0
	lda (BASL),y			; Save background
	sta WG_MOUSEBG
	lda	#CH_MOUSEPOINTER	; Draw the pointer
	sta	(BASL),y

WGDrawPointer_done:
	SETSWITCH	PAGE2OFF	; Turn this off so we don't mess up page 4 screen holes!
	RESTORE_AXY
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mouse API state
;
WG_MOUSEACTIVE:
.byte 0

WG_MOUSEPOS_X:
.byte 39
WG_MOUSEPOS_Y:
.byte 11

WG_MOUSEBG:
.byte 0

WG_MOUSE_JUMPL:
.byte 0
WG_MOUSE_JUMPH:
.byte 0
WG_MOUSE_SLOT:
.byte 0
WG_MOUSE_SLOTSHIFTED:
.byte 0
