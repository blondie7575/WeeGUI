;===============================
; Polled GS Mouse driver
; by John Brooks 3/6/1988
;
; Modified 3/4/2018 for:
;  1) 65816 emulation mode
;  2) Cvt pixel pos to 80-col txt pos
;  3) Add comments
;
; Modified 2018/05/03
; by Peter Ferrie for:
;  1) CC65 compatible
;  2) extensions for WeeGUI
;===============================

.setcpu "65816"

IoMouseStatus = $C027
IoMouseData = $C024

;-------------------------------
; If GS mouse state has changed
; then update:
;  MousePixX,Y
;  MouseTxtX,Y
;  MouseDownX,Y
;
; Entry: e=1, DP=$0000
;  Exit: e=1, DP=$0000, AXY=?
;-------------------------------
GsPollMouse:
	lda IoMouseStatus ;Any new mouse data?
	bpl GS_Mouse_Exit
	and #2 ;If data reg is misaligned, realign with deltaX=2
	bne GS_Mouse_OnlyY
	lda IoMouseData ;Read deltaX
GS_Mouse_OnlyY:
	jsr WGUndrawPointer			; Erase the old mouse pointer
	ldy IoMouseData ;Read deltaY
	clc
	xce ;65816 native mode
GS_Mouse_CheckX:
	rep #$30 ;16-bit A,X,Y
	.a16
	.i16
	ldx #MousePixX
	jsr GS_Mouse_AddDelta ;Cvt to signed word, add to pixPos & range clamp
	sta MouseTxtX-MousePixX,x ;16-bit store overwrites Y
GS_Mouse_CheckY:
	tya ;a=DeltaY
	inx
	inx ;x=MousePixY ptr
	jsr GS_Mouse_AddDelta ;Cvt to signed word, add to pixPos & range clamp
	sep #$21 ;8-bit acc, set carry
	.a8
	sta MouseTxtY-MousePixY,x

	tya
	eor MouseBtn0-MousePixY,x ;Detect button0 up/down
	bpl GS_Mouse_NoDownEdge
	eor MouseBtn0-MousePixY,x ;Remove old button0
	sta MouseBtn0-MousePixY,x ;Save new button0
	bmi GS_Mouse_NoDownEdge
	ldy MouseTxtX-MousePixY,x
	sty MouseDownX ;Set WG_MOUSECLICK_X & WG_MOUSECLICK_Y
GS_Mouse_NoDownEdge:
	xce ;65816 emulation mode: 8-bit A,X,Y
	jmp WGDrawPointer				; Redraw the pointer

;-------------------------------

GS_Mouse_AddDelta:
	.a16
	.i16
	ora #$ff80 ;Extend neg 6-bit delta in anticipation of delta
	bit #$0040 ;Check sign of delta
	bne GS_Mouse_GotDelta
GS_Mouse_Pos:
	and #$003f ;Strip b7 button state from positive 6-bit delta
GS_Mouse_GotDelta:
	clc
	adc 0,x ;Apply delta to X or Y pixel position
	bpl GS_Mouse_NoMinClamp
	tdc ;Clamp neg position to zero
GS_Mouse_NoMinClamp:
	cmp MouseMaxX-MousePixX,x
	bcc GS_Mouse_NoMaxClamp
	lda MouseMaxX-MousePixX,x
	dec
GS_Mouse_NoMaxClamp:
	sta 0,x ;Store mouse pixel position
	lsr ;TextPos = PixelPos / 8
	lsr
	lsr
GS_Mouse_Exit:
	rts
	.a8
	.i8

GsDisableMouse:
	pla
	pla					; discard return address
	stz WG_MOUSEACTIVE
	jsr WGUndrawPointer			; Be nice if we're disabled during a program
	pla
	rts

;-------------------------------
