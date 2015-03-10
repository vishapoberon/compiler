CFLAGS = "-lnewt"
export CFLAGS

VOC = /opt/voc/bin/voc

all:
	$(VOC) -s newt.Mod newttest.Mod -m
	$(VOC) -s newt.Mod newttest2.Mod -m

clean:
	rm *.h
	rm *.c
	rm *.o
	rm *.sym
