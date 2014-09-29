;
;  memory.s
;  Memory mapping information
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


; Constants

CHAR_NORMAL = $ff
CHAR_INVERSE = $3f
CHAR_FLASH = $7f

VIEW_STYLE_PLAIN = $00
VIEW_STYLE_FANCY = $01
VIEW_STYLE_CHECK = $02
VIEW_STYLE_BUTTON = $03

VIEW_STYLE_TAKESFOCUS = $02	; Styles >= this one are selectable

VIEW_STYLE_APPLESOFT = $80	; High nybble flag bit for views created from Applesoft

IRQVECTORL = $03fe
IRQVECTORH = $03ff


; ROM entry points

COUT			= $fded
BASCALC			= $fbc1
PRBYTE			= $fdda
RDKEY			= $fd0c
BELL			= $fbdd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System state
;
WG_CURSORX:				; In screenspace
.byte	0
WG_CURSORY:
.byte	0

WG_LOCALCURSORX:		; In current viewspace
.byte	0
WG_LOCALCURSORY:
.byte	0

WG_ACTIVEVIEW:
.byte 0

WG_FOCUSVIEW:
.byte 0

WG_PENDINGACTIONVIEW:
.byte 0

WG_VIEWCLIP:
	; X0,Y0,X1,Y1. Edges of current window, in view space, right span
.byte 0,0,0,0,0

WG_VIEWRECORDS:
	; 0  1       2             3           4       5         6          7           8         9        10         11        12      13
	; X, Y, Screen Width, Screen Height, Style, X Offset, Y Offset, View Width, View Height, State, CallbackL, CallbackH, TitleL, TitleH
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

WG_STRINGS:			; Fixed-size block allocator for strings (view titles, mainly)
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

WG_SCRATCHA:
.byte 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Lookup tables
;

; Video memory
TEXTLINES_H:
.byte	$04	;0
.byte	$04	;1
.byte	$05	;2
.byte	$05	;3
.byte	$06	;4
.byte	$06	;5
.byte	$07	;6
.byte	$07	;7
.byte	$04	;8
.byte	$04	;9
.byte	$05	;10
.byte	$05	;11
.byte	$06	;12
.byte	$06	;13
.byte	$07	;14
.byte	$07	;15
.byte	$04	;16
.byte	$04	;17
.byte	$05	;18
.byte	$05	;19
.byte	$06	;20
.byte	$06	;21
.byte	$07	;22
.byte	$07	;23

TEXTLINES_L:
.byte	$00	;0
.byte	$80	;1
.byte	$00	;2
.byte	$80	;3
.byte	$00	;4
.byte	$80	;5
.byte	$00	;6
.byte	$80	;7
.byte	$28	;8
.byte	$a8	;9
.byte	$28	;10
.byte	$a8	;11
.byte	$28	;12
.byte	$a8	;13
.byte	$28	;14
.byte	$a8	;15
.byte	$50	;16
.byte	$d0	;17
.byte	$50	;18
.byte	$d0	;19
.byte	$50	;20
.byte	$d0	;21
.byte	$50	;22
.byte	$d0	;23

