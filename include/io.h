#ifndef __IO_H
#define __IO_H

/* 
* write a byte in the I/O port and wait until 
* the port respond
*/
#define outb(val, port)			\
  __asm__ __volatile__(			\
	"outb\t%%al, %%dx\n\t"		\
	"jmp \t1f\n"			\
	"1:\tjmp\t 1f\n"		\
	"1:"::"a"(val), "d"(port))

/* read byte from I/O port */
#define inb(port)			\
({					\
unsigned char _val;			\
  __asm__ __volatile__(			\
	"inb \t%%dx, %%al\n\t"		\
	"jmp \t1f\n"			\
	"1:\tjmp \t1f\n"		\
	"1:":"=a"(_val): "d"(port));	\
 _val;					\
})

#endif /* __IO_H */
