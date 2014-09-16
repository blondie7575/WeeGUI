;
;  switches.s
;  Softswitches for Apple ][
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


PAGE2			= $c01c ; Read bit 7
PAGE2OFF		= $c054 ; Read/Write
PAGE2ON			= $c055 ; Read/Write

COL80			= $c01f	; Read bit 7
COL80OFF		= $c00c	; Write
COL80ON			= $c00d ; Write

STORE80			= $c018	; Read bit 7
STORE80OFF		= $c000 ; Write
STORE80ON		= $c001 ; Write

TEXT			= $c01a ; Read bit 7
TEXTOFF			= $c050 ; Read/Write
TEXTON			= $C051 ; Read/Write

KBD				= $c000 ; Read
KBDSTRB			= $c010	; Read/Write

RDVBLBAR		= $C019	; Read bit 7 (active low)

OURCH			= $057b ; 80 col cursor position (H)
OURCV			= $05fb ; 80 col cursor position (V)
