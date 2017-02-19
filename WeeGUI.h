' ============================================================
'
' WeeGUI.h	MD Basic WeeGUI support.
' https://github.com/blondie7575/WeeGUI
' http://www.morgandavis.net/blog/2009/08/09/md-basic/
' ============================================================

#pragma	once
#reserve WINDW, CHKBX, BUTTN, KILL, SEL, PDACT, FOC, FOCN, FOCP
#reserve ACT, PNT, PNTA, ERASE, WIPE, TITLE, STACT, PROG, SETV
#reserve CURSR
#reserve SCR, SCRBY
#reserve HOME, DESK, PLOT, PRINT, DRAW, FILL
#reserve MOUSE, GET
#reserve EXIT

' View Styles
#define FramelessView 0
#define PlainView 1
#define DecoratedView 2

' View Routines
#define WGCreateView &WINDW
#define WGCreateCheckbox &CHKBX
'#define WGCreateButton &BUTTN
#define WGCreateButton(p1,p2,p3,p4,p5,p6) &BUTTN(p1,p2,p3,p4,gosub p5,p6)
#define WGDeleteView &KILL
#define WGSelectView &SEL
#define WGPendingViewAction &PDACT
#define WGViewFocus &FOC
#define WGViewFocusNext &FOCN
#define WGViewFocusPrev &FOCP
#define WGViewFocusAction &ACT
#define WGPaintView &PNT
#define WGViewPaintAll &PNTA
#define WGEraseViewContents &ERASE
#define WGEraseView &WIPE
#define WGViewSetTitle &TITLE
'#define WGViewSetAction &STACT
#define WGViewSetAction(p1) &STACT(gosub p1)
#define WGCreateProgress &PROG
#define WGSetValue &SETV

' Cursor Routines
#define WGSetCursor &CURSR

' Scrolling Routines
#define WGScroll &SCR
#define WGScrollBy &SCRBY
#define WGScrollByX(x) WGScrollBy(x, 0)
#define WGScrollByY(y) WGScrollBy(0, y)

' Drawing Routines
#define WGClearScreen &HOME
#define WGDesktop &DESK
#define WGPlot &PLOT
#define WGPrint &PRINT
#define WGStrokeRect &DRAW
#define WGFillRect &FILL

' Mouse & Keyboard Routines
#define WGEnableMouse &MOUSE(1)
#define WGDisableMouse &MOUSE(0)
#define WGMouse &MOUSE
#define WGGet &GET

' Miscellanous
#define WGExit &EXIT