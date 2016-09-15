OBJECTS = timer.o isr.o
CFLAGS	= -O -W -Wall -fomit-frame-pointer -nostdinc -I../include

kernel.o: $(OBJECTS)
	ld -r $(OBJECTS) -o kernel.o

isr.o: isr.s
	as -c isr.s -o isr.o

timer.o: timer.c
	gcc -c $(CFLAGS) timer.c -o timer.o

clean:
	rm -rfv $(OBJECTS) kernel.o *~

