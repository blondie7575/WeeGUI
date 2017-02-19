#include "WeeGUI.h"
#include <CType.h>

#declare key%
#pragma optimize 0,2 ' full line optimization in this demo scares applesoft.

#define QuitChar 113

#define TextViewID 0
#define MainViewID 1
#define OpenGarageButtonID 2
#define CloseGarageButtonID 3
#define ParlorCheckBoxID 4
#define LoungeCheckBoxID 5
#define BedroomCheckBoxID 6
#define QuitButtonID 7

	print chr$(4)"brun weegui"
	WGDesktop
	WGCreateView(TextViewID,DecoratedView,2,15,76,7,76,40)
	WGViewSetTitle("Help")
	WGViewSetAction(TextViewAction)
	gosub TextViewAction

	WGFillRect(0,0,80,13,160)
	WGCreateView(MainViewID,PlainView,1,1,78,11,78,11)
	WGCreateButton(OpenGarageButtonID,4,3,21,OpenGarageAction,"Open Garage")
	WGCreateButton(CloseGarageButtonID,4,5,21,CloseGarageAction,"Close Garage")

	WGSelectView(MainViewID)
	WGSetCursor(40,1)
	WGPrint(83)
	WGPrint(83)
	WGPrint(83)
	inverse 
	WGPrint(" Lighting ")
	normal 
	WGPrint(83)
	WGPrint(83)
	WGPrint(83)
	WGCreateCheckbox(ParlorCheckBoxID,42,4,"Parlor")
	WGCreateCheckbox(LoungeCheckBoxID,42,6,"Lounge")
	WGCreateCheckbox(BedroomCheckBoxID,42,8,"Bedroom")
	gosub OpenGarageAction
	WGCreateButton(QuitButtonID,71,1,8,10000,"Quit")
	WGSelectView(0)
	WGEnableMouse

	' RUN LOOP
	repeat
		WGPendingViewAction
		WGGet(key%)

		if key% = cUpArrow then 
			WGSelectView(TextViewID)
			WGScrollBy(0,1)
			gosub TextViewAction
		endif
		if key% = cDownArrow then 
			WGSelectView(TextViewID)
			WGScrollBy(0, - 1)
			gosub TextViewAction
		endif
		if key% = cEscape then 
			WGViewFocusPrev
		endif
		if key% = cTab then 
			WGViewFocusNext
		endif
		if key% = cCR then 
			WGViewFocusAction
		endif
	until key% = QuitChar

	WGDisableMouse
	WGExit
	home 
	end

TextViewAction:
	WGSelectView(TextViewID)
	WGEraseViewContents
	WGSetCursor(2,1)
	WGPrint("Welcome to the SuperAutoMat6000 home automation system.")
	WGSetCursor(0,3)
	WGPrint("Use the buttons and checkboxes above to achieve the perfect mood for any occasion. Frequent use may cause heartburn. Do not look into laser with remaining eye.")
	WGPrint(" Note that this is a really long, pointless block of meaningless text, but at least you can scroll it!")
	WGPrint(" Darn good thing too, because it doesn't fit in the allotted space here.")
	WGSetCursor(8,9)
	WGPrint("(c)2015 OmniCorp. All rights reserved.")
	return 

OpenGarageAction:
	WGSelectView(MainViewID)
	WGSetCursor(4,8)
	WGPrint("Garage door is open  ")
	return

CloseGarageAction:
	WGSelectView(MainViewID)
	WGSetCursor(4,8)
	WGPrint("Garage door is closed")
	return 


