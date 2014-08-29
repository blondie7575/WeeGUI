;
;  gui.s
;  AssemblyTest
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


.org $6000

; Reserved locations


; Constants


; ROM entry points


; WeeGUI entry points

GUI_MAIN = $4000


; Main

main:
	jmp GUI_MAIN



