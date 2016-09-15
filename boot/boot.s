/*
|	boot.s

*   This is a rewriting of the linux-0.01 boot.s, using the 
*   GNU assembler syntax with some modifications in the code.

| boot.s is loaded at 0x7c00 by the bios-startup routines, and moves itself
| out of the way to address 0x90000, and jumps there.
|
| It then loads the system at 0x10000, using BIOS interrupts. Thereafter
| it disables all interrupts, moves the system down to 0x0000, changes
| to protected mode, and calls the start of system. System then must
| RE-initialize the protected mode in it's own tables, and enable
| interrupts as needed.

*   Note: I have used function 0x42 of the BIOS service 0x13 instead of
*   function number 0x2 used in the original boot.s!
 
*   Issam Abdallah, Tunisia.
*   E-mail: iabdallah@yandex.com
*   Web site: issamabd.com
*/

	.code16
	.text
	.global _start

_start:

BOOTSEG = 0x07c0
INITSEG = 0x9000
SYSSEG  = 0x1000
SYSSIZE = 20

######################################### * move boot.s to 0x90000

	movw	$BOOTSEG, %ax
	movw	%ax, %ds
	movw	$INITSEG, %ax
	movw	%ax, %es
	movw	$256, %cx		# 256 * 2 = 512 bytes
	subw	%si, %si
	subw	%di, %di
	cld
	rep 
	movsw				# move word by word

	ljmp	$INITSEG, $go	

######################################### * Initialize segment registers

go: 
	mov 	$INITSEG, %ax 	
	mov 	%ax, %ds		# ES = CS!
	mov 	%ax, %es		# ES = DS!
	mov 	%ax, %ss		# optional
	mov 	$0x400, %sp		# arbitrary value >>512


	xor	%ah, %ah		# AH = 0: function 0 => set video mode
	mov	$0x3, %al		# video mode: 80x25 16 colors text mode 
	int	$0x10			# BIOS interrupt 0x10: video service

	movw	$MSG_SIZE, %cx		# size of message
	movb	$0, %bh			# page 0
	movb	$0x07, %bl		# background black (0x0) - foreground white (0x7)
	movw	$msg, %bp		# [ES:BP]: offset of the message
	movb	$0x13, %ah		# write string
	movb	$0x01, %al		# move cursor
	int	$0x10

######################################### * ok, we've written the message, now we want to load the system (at 0x10000)

1:
	xor 	%ax, %ax		# AX=0: Initialize the disk
	int 	$0x13			# BIOS Interrupt 0x13: disk service
	jc	1b
				
	xor	%ax, %ax
	movb	$0x42, %ah		# function 0x42: extended read (LBA)
	movw	$dap, %si 		# SI pointes to DAP structure
	int	$0x13

######################################### * now we want to move to protected mode ... 

	cli				# no interrupts are allowed! 		

######################################### * first we move the system to it's rightful place

	xor	%ax, %ax
	cld				# 'direction'=0, movs moves forward
do_move:
	movw	%ax, %es		# destination segment
	addw	$0x1000, %ax
	cmpw	$INITSEG, %ax		# we will move segments from 0x1000 to 0x8000
	jz	end_move
	movw	%ax, %ds		# source segment
	xor	%di, %di
	xor	%si, %si
	movw 	$0x8000, %cx		# size of a segment (64Kb) in words
	rep
	movsw				# movsw will move word by word
	jmp	do_move

end_move:
######################################### * then we load the segment descriptors

	mov	$INITSEG, %ax		# right, forgot this at first. didn't work :-)
	mov	%ax, %ds 
	lgdt 	gdt_ptr			# load gdt with whatever appropriate

######################################### * that was painless, now we enable A20

	call	empty_8042

	movb	$0xD1, %al		# command write
	outb	%al, $0x64
	call	empty_8042

	movb	$0xDF, %al		# A20 on
	outb	%al, $0x60
	call	empty_8042

## [4]! PIC initializing #################
					## PIC mode (LPIC are disabled). 
					## So we have to configure/initialise the two 8259A PIC. by sending
					## some Initialisation Command Word (ICW).

					## PIC 	     type	port
					## ------------------------------
					## 8259A-1   Command 	0x0020
					## 8259A-1   Data 	0x0021
					## 8259A-2   Command 	0x00A0
					## 8259A-2   Data 	0x00A1 

	## ICW1: commands
	movb	$0x11, %al		# ICW1 = 0x11 => two PICs (Bit 4), ICW4 required (bit 0)
	outb	%al, $0x20		# send to 8259A-1
	.word	0x00eb, 0x00eb		# jmp $+2, jmp $+2 => wait until the port respond
	outb	%al, $0xA0		# send to 8259A-2
	.word	0x00eb,0x00eb

	## ICW2: data
	movb	$0x20, %al		# Set the first interrupt index for 8259A-1 
	outb	%al, $0x21		# IDT[0x20]: timer interrupt (IRQ0)
	.word	0x00eb, 0x00eb		# 
	movb	$0x28, %al		# Samething with 8259A-2
	outb	%al, $0xA1		# IDT[0x28]: timer interrupt (IRQ8)
					# Note: HP Pavilion dv6000: IDT[0x28] => System CMOS/RTC clock interrupt
	.word	0x00eb, 0x00eb

	## ICW3: data
	movb	$0x04, %al		# PIC 8259A-1 is master
	outb	%al, $0x21
	.word	0x00eb, 0x00eb
	movb	$0x02, %al		# PIC 8259A-2 is slave
	outb	%al, $0xA1
	.word	0x00eb, 0x00eb

	## ICW4: data 
	movb	$0x01, %al		# non AEOI (bit-1), 8086 mode (bit-0)
	outb	%al, $0x21
	.word	0x00eb, 0x00eb
	outb	%al, $0xA1
	.word	0x00eb, 0x00eb

######################################### * switch to protected mode

	mov 	%cr0, %eax		# protected mode (PE) bit
	or 	$1, %ax			# EAX[0] = 1
	mov 	%eax, %cr0 		# this is it!

######################################### * The instruction queue of the processor still contains 16 bit instructions!
					# We have to empty the queue by executiong a long jump to a 32-bit piece of code,
					# which means that the offset operand of LJMP must have 32-bit size while executing
					# in 16-bit mode. So we have to use the 0x66 prefix! 
					# Note: see INTEL 80386 manual - section: Mixing 16-bit and 32-bit code

	.byte	0x66,0xea		# prefix (0x66) + ljmp opcode (0xea)
	.word	ok_pm,0x9		# offset: 32-bit size
	.word	0x8			# CS = 0x8: GDT[1]

	.code32

ok_pm:	

	ljmp	$0x8, $0x0		# Long JAMP to kernel head (CS:EIP)

######################################### * This routine checks that the keyboard command queue is empty
					# No timeout is used - if this hangs there is something wrong with
					# the machine, and we probably couldn't proceed anyway.
empty_8042:
	.word	0x00eb,0x00eb
	inb	$0x64, %al 		# 8042 status port
	testb	$2, %al			# is input buffer full?
	jnz	empty_8042		# yes - loop
	ret

######################################## * DAP: Disk Address Packet
dap:	.byte	0x10			# size of dap = 16 bytes 
	.byte	0			# 0 - unused
	.word	SYSSIZE			# number of sectors to be read
	## buffer = [segment:offset]: memory location to read into it!
	.word	0x0000			# offset
	.word	SYSSEG			# segment
	.word	1,0,0,0			# index of first sector to be read 

######################################### * GDT

gdt:
	.word	0,0,0,0			# dummy

	.word	0x07FF			# 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000			# base address=0
	.word	0x9A00			# code read/exec
	.word	0x00C0			# granularity=4096, 386

	.word	0x07FF			# 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000			# base address=0
	.word	0x9200			# data read/write
	.word	0x00C0			# granularity=4096, 386

gdt_ptr:
	.word	. - gdt - 1		# Limit = (8*3) - 1
	.word	gdt,0x9			# 0x9xxxx: a physical address!

######################################### * msg

msg:
	.byte	13, 10			# CR, LF
	.ascii	"Loading system..."
	.byte	13,10,13,10		# CR, LF, CR, LF

MSG_SIZE = . - msg

	.org	510
	.word	0xAA55 

######################################## * boot.s *
