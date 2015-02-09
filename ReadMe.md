
Known issues
------------

- Hitting Reset during a WeeGUI application will leave your Apple II in an unsafe state.
- Calling WGEraseView on a view that shares border rendering with other views will require manually redrawing those views.
- ProDOS reports NO BUFFERS AVAILABLE after three successive runs of ASMDEMO. Doing a CAT will restore normal operation.


To Do:
------
- Document final memory map
- Remove references to ORG in docs (except in memory map)
- Put sample code in docs
