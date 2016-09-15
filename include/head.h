#ifndef __HEAD_H
#define __HEAD_H

/* GDT, LDT or IDT */
typedef struct desc_struct {
	unsigned long a, b;
} desc_table[256];

/* idt is a global variable declared and defined in boot/head.s */
extern desc_table idt;

#endif /* HEAD_H */ 
