
Known issues
------------

- Hitting Reset during a WeeGUI application will leave your Apple II in an unsafe state


To Do:
------

- Repainting a view while the mouse cursor is on it will cause artifacts when mouse moves
- Quitting sometimes leaves BASIC in inverted text mode
- Quitting with button highlighted leaves us in inverted text mode
- After initial run of basic demo, additional run fails with no buffers available
- Make WGFillRect support 1 height and 1 width
- If called in inverse mode, clear screen clears inverse
- Fix unclosed PRE tags in documentation
- Delete view feature
- Factor out mouse driver
- Standardize naming of functions
- Write sample code
- Update side effects in assembly API