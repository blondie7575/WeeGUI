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

; Zero page locations we use (unused by Monitor, Applesoft, or ProDOS)
PARAM0			= $06
PARAM1			= $07
PARAM2			= $08
PARAM3			= $09
SCRATCH0		= $19
SCRATCH1		= $1a
