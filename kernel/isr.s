/* 
*	isr.s
*
* Issam Abdallah, Information Engineer, Tunisia.
* Email: iabdallah@yandex.com
* Web site: issamabd.com
*/
	.global timer_interrupt

.balign 2
timer_interrupt: 
	incl	jiffies			# update jiffies
	movb	$0x20, %al		# send EOI (End Of Int) to PIC-1
	outb	%al, $0x20
	call	do_timer		# call do_timer() in kernel/timer.c
	iret				# Return from interrupt

