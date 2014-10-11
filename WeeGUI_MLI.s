;
;  WeeGUI_MLI.s
;  Machine Language API for WeeGUI
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reserved zero page locations
;
PARAM0					= $06
PARAM1					= $07
PARAM2					= $08
PARAM3					= $09


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WeeGUI entry point
; Set up your call, then do a JSR to this address.
;
WeeGUI					= $4004


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; API call names, to be passed to WeeGUI via X register
; e.g.
;     ldx #WGDesktop
;     jsr WeeGUI
;
WGClearScreen			= 0
WGDesktop				= 2
WGSetCursor				= 4
WGSetGlobalCursor		= 6
WGSyncGlobalCursor		= 8
WGPlot					= 10
WGPrint					= 12
WGFillRect				= 14
WGStrokeRect			= 16
WGFancyRect				= 18
WGPaintView				= 20
WGViewPaintAll			= 22
WGEraseView				= 24
WGEraseViewContents		= 26
WGCreateView			= 28
WGCreateCheckbox		= 30
WGCreateButton			= 32
WGViewSetTitle			= 34
WGViewSetAction			= 36
WGSelectView			= 38
WGViewFromPoint			= 40
WGViewFocus				= 42
WGViewUnfocus			= 44
WGViewFocusNext			= 46
WGViewFocusPrev			= 48
WGViewFocusAction		= 50
WGPendingViewAction		= 52
WGPendingView			= 54
WGScrollX				= 56
WGScrollXBy				= 58
WGScrollY				= 60
WGScrollYBy				= 62
WGEnableMouse			= 64
WGDisableMouse			= 66
