#ifndef __SYSTEM_H
#define __SYSTEM_H

/* 
  Set a IDT entry:

		Interrupt gate Descriptor (type=14)
  _____________________________________________________________
  |				| |   | |       | | | |       |
  |	   OFFSET 31..16	|P|DPL|0| TYPE  |0 0 0|unused |
  |_____________________________|_|_|_|_|1|1|1|0|_|_|_|_|_|_|_|
  |				|			      |
  |	      SELECTOR		|	OFFSET 15..0	      |
  |_____________________________|_____________________________|



		set_gate(&idt[n],14,0,addr)
  _____________________________________________________________
  |				| |   | |       | | | |       |
  |	addr 31..16		|1|000|0| TYPE  |0 0 0| 0000  | <-- EDX
  |_____________________________|_|_|_|_|1|1|1|0|_|_|_|_|_|_|_|<---------- *(4+(char *)(&idt[n]))
  |				|			      |
  |	      0x0008		|  addr 15..0 (registre AX)   | <-- EAX
  |_____________________________|_____________________________|<---------- *((char *)(&idt[n]))
								



	idt[0x20]: timer interrupt 
	=> set_intr_gate(0x20, &timer_interrupt) in (kernel/timer.c)	
	==>  set_gate(&idt[0x20],14,0,&timer_interrupt)
  _____________________________________________________________
  |				| |   | |       | | | |       |
  |  &timer_interrupt 31..16	|1|000|0| TYPE  |0 0 0| 0000  | <-- EDX
  |_____________________________|_|_|_|_|1|1|1|0|_|_|_|_|_|_|_|<---------- *(4+(char *)(&idt[0x20]))
  |				|			      |
  |	      0x0008		|  &timer_interrupt 15..0     | <-- EAX
  |_____________________________|_____________________________|<---------- *((char *)(&idt[0x20]))
								


*/
#define set_gate(gate_addr,type,dpl,addr) 		\
__asm__ __volatile__ (					\
	"movw \t%%dx,%%ax\n\t" 				\
	"movw \t%0,%%dx\n\t" 				\
	"movl \t%%eax,%1\n\t" 				\
	"movl \t%%edx,%2" 				\
	: 						\
	: "i" ((short) (0x8000+(dpl<<13)+(type<<8))), 	\
	"m" (*((char *) (gate_addr))), 			\
	"m" (*(4+(char *) (gate_addr))), 		\
	"d" ((char *) (addr)),"a" (0x00080000))

/* 
 * Set a "interrupt gate descriptor" in IDT
*/
#define set_intr_gate(n,addr) set_gate(&idt[n],14,0,addr)

/* 
 *  Enable maskable interrupts
*/
#define sti() __asm__ __volatile__("\tsti"::)

#endif /* __SYSTEM_H */
