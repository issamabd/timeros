CFLAGS 	= -O -W -Wall -fomit-frame-pointer -nostdinc -Iinclude 
SYSOBJS = boot/head.o init/main.o kernel/kernel.o

all: Image

Image: boot/boot system
	cat boot/boot system > Image
	sync

boot/boot.o: boot/boot.s
	as boot/boot.s -o boot/boot.o

boot/boot: boot/boot.o
	ld -Ttext 0 -Tdata 7C00 --oformat binary boot/boot.o -o boot/boot

system: $(SYSOBJS)
	ld -M -Ttext 0 -e startup_32 --oformat binary $(SYSOBJS) -o system > system.map

boot/head.o: boot/head.s
	as boot/head.s -o boot/head.o

kernel/kernel.o:
	(cd kernel; make)

init/main.o: init/main.c
	gcc -c $(CFLAGS) init/main.c -o init/main.o

clean:
	rm -fv $(SYSOBJS) boot/boot boot/boot.o system tmp_make *~
	(cd kernel; make clean)

