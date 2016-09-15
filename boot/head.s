/* 
*	head.s
*
* Issam Abdallah, Information Ingineer, Tunisia.
* Email: iabdallah@yandex.com
* Web site: issamabd.com
*/
	.code32
	.global	startup_32, gdt, idt
	.text

startup_32:

	movl 	$0x10, %eax
	mov 	%ax, %ds
	mov 	%ax, %es
	mov 	%ax, %fs 
	mov 	%ax, %gs
	lss	kern_stack_ptr, %esp

	lgdt 	gdt_ptr			# reinitialize GDT
	call	setup_idt		# initialize IDT
	lidt	idt_ptr			# load IDTR 

	movl 	$0x10, %eax
	mov 	%ax, %ds
	mov 	%ax, %es
	mov 	%ax, %fs 
	mov 	%ax, %gs
	lss	kern_stack_ptr, %esp

	call	main			# call main (init/main.c)
					#
#########################################

setup_idt:
	leal 	ignore_int,%edx		# see "include/system.h"
	movl 	$0x00080000,%eax
	movw 	%dx,%ax
	movw 	$0x8e00, %dx		# interrupt gate descriptor = EDX:EAX

	leal 	idt,%edi		# EDI = &idt[0]
	movl 	$256,%ecx		# 256 entries IDT

set_idt_desc:				
	movl 	%eax,(%edi)		# EAX into the first 32-bit of idt[i]
	movl 	%edx,4(%edi)		# EDX into the 2nd 32-bit of idt[i]
	addl 	$8,%edi			# next entry
	loop	set_idt_desc		
	ret

## default interrupt handler used to initialize IDT
ignore_int:
	nop
	iret

## .balign 8: advance location counter until it is a multiple of 8  
## to optimize access to the GDT. 8 is the size of a GDT entry.

	.balign 8
gdt:	.quad 	0x0000000000000000	
	.quad	0x00c09a00000007ff	# 8Mb code segment (CS=0x08), base = 0x0000
	.quad	0x00c09200000007ff	# 8Mb data segment (DS=SS=0x10), base = 0x0000

gdt_ptr:
	.word . - gdt - 1
	.long gdt

.balign	4
	.fill	320, 4, 0		# 32 entries (I think this is the min size:)

kern_stack_ptr:				# for 'lss' instruction	
	.long	.			# ESP0
	.word	0x10

	.balign 8

idt:
	.fill 	256,8,0

idt_ptr:
	.word 	. - idt -1
	.long 	idt


