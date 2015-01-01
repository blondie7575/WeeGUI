;
;  zeropage.s
;  Zero page information
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


; Reserved locations

INVERSE			= $32	; Text output state
CH				= $24	; Cursor X pos
CV				= $25	; Cursor Y pos
BASL			= $28	; Current video memory line
BASH			= $29	; Current video memory line
A1L				= $3c	; AUXMOVE source address start LSB
A1H				= $3d	; AUXMOVE source address start MSB
A2L				= $3e	; AUXMOVE source address end LSB
A2H				= $3f	; AUXMOVE source address end MSB
A4L				= $42	; AUXMOVE dest address LSB
A4H				= $43	; AUXMOVE dest address MSB

; Zero page locations we use (unused by Monitor, Applesoft, or ProDOS)
PARAM0			= $06
PARAM1			= $07
PARAM2			= $08
PARAM3			= $09
SCRATCH0		= $19
SCRATCH1		= $1a

; Special shared memory location
; Harded coded to here so that mouse driver can share it from main bank
WG_PENDINGACTIONCLICKX = $1b
WG_PENDINGACTIONCLICKY = $1c
