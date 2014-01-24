
SETPATH = MODULES=".:gnuc:gnuc/x86_64"

VOC0 = $(SETPATH) /opt/voc/bin/voc

all:
	#$(VOC0) -s ORS.Mod
	#$(VOC0) -s ORB.Mod
	#$(VOC0) -s ORG.Mod
	$(VOC0) -s ORS.Mod ORB.Mod ORG.Mod ORP.Mod -M

test:
	./ORP -s test.Mod

clean:
	rm *.sym
	rm *.o
	rm *.h
	rm *.c

