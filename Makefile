#
#  Makefile
#  WeeGUI
#
#  Created by Quinn Dunki on 8/15/14.
#  One Girl, One Laptop Productions
#  http://www.quinndunki.com
#  http://www.quinndunki.com/blondihacks
#


CL65=cl65
AC=AppleCommander.jar
ADDR=4000
ADDRDEMO=6000

PGM=gui
DEMO=guidemo

all: $(DEMO) $(PGM)

$(DEMO):
	@PATH=$(PATH):/usr/local/bin; $(CL65) -t apple2enh --start-addr $(ADDRDEMO) -l$(DEMO).lst $(DEMO).s
	java -jar $(AC) -d $(DEMO).dsk $(DEMO)
	java -jar $(AC) -p $(DEMO).dsk $(DEMO) BIN 0x$(ADDRDEMO) < $(DEMO)
	rm -f $(DEMO)
	rm -f $(DEMO).o

$(PGM):
	@PATH=$(PATH):/usr/local/bin; $(CL65) -t apple2enh --start-addr $(ADDR) -l$(PGM).lst $(PGM).s
	java -jar $(AC) -d $(DEMO).dsk $(PGM)
	java -jar $(AC) -p $(DEMO).dsk $(PGM) BIN 0x$(ADDR) < $(PGM)
	rm -f $(PGM)
	rm -f $(PGM).o
	osascript V2Make.scpt $(PROJECT_DIR) $(DEMO) $(PGM)

clean:
	rm -f $(DEMO)
	rm -f $(DEMO).o
	rm -f $(PGM)
	rm -f $(PGM).o

