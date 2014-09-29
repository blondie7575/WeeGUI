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
MOUSE_CLAMPL = $04f8
MOUSE_CLAMPH = $05f8

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
; versions. This macro abstracts this for us.
; NOTE: Clobbers X and Y registers!
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

	; Find slot number and calculate the various indirections needed
	jsr WGFindMouse
	bcs WGEnableMouse_Error

	; Install our interrupt handler via ProDOS (play nice!)
	jsr PRODOS_MLI
	.byte ALLOC_INTERRUPT
	.addr WG_PRODOS_ALLOC
	bne WGEnableMouse_Error		; ProDOS will return here with Z clear on error

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

	cli					; Once all setup is done, it's safe to enable interrupts
	bra WGEnableMouse_done

WGEnableMouse_Error:
	lda #0
	sta WG_MOUSEACTIVE

WGEnableMouse_done:
	pla
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WGDisableMouse
; Shuts off the mouse when we're done with it
;
WGDisableMouse:
	pha

	lda WG_MOUSEACTIVE			; Never activated the mouse
	beq WGDisableMouse_done

	lda MOUSEMODE_OFF
	CALLMOUSE SETMOUSE

	lda #0
	sta WG_MOUSEACTIVE

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

	ldx #5

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
	lda #0
	sta WG_MOUSE_SLOT
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
	SETSWITCH	PAGE2OFF	; Turn this off so we don't mess up page 4 screen holes!

	CALLMOUSE SERVEMOUSE
	bcs WGMouseInterruptHandler_disregard

	jsr WGUndrawPointer			; Erase the old mouse pointer

	; Read the mouse state. Note that interrupts need to remain
	; off until after the data is copied.
	sei
	CALLMOUSE READMOUSE

	; Read mouse position and transform it into screen space
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

	lda MOUSTAT,x			; Read status bits first, because READMOUSE clears them
	sta WG_MOUSE_STAT

	cli						; Once we've read all the state, we can re-enable interrupts

	lda WG_MOUSE_STAT				; Check for rising edge of button state
	and #MOUSTAT_MASK_DOWN
	beq WGMouseInterruptHandler_intDone
	and #MOUSTAT_MASK_WASDOWN
	bne WGMouseInterruptHandler_intDone

WGMouseInterruptHandler_button:


WGMouseInterruptHandler_intDone:
	jsr WGDrawPointer				; Redraw the pointer

	RESTORE_AXY

	clc								; Notify ProDOS this was our interrupt
	rts

WGMouseInterruptHandler_disregard:
	; Carry will still be set here, to notify ProDOS that
	; this interrupt was not ours
	rts



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
WG_MOUSE_STAT:
.byte 0

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


