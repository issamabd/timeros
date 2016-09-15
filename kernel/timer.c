/* 
* 	timer.c
*
* Issam Abdallah, Information Engineer, Tunisia.
* Email: iabdallah@yandex.com
* Web site: issamabd.com
*/

#include <io.h>		/* outb() 	   */
#include <system.h>	/* set_intr_gate() */
#include <head.h>	/* desc_table idt  */
#include <timer.h> 	/* bin_to_ascii()  */

/* IDT[0x20]: timer interrupt */
#define IRQ0 0x20	


 
/* 	
*	- HZ = Number of timer (INTEL 8253 ou 8254) Interrupts (or "ticks") per second. 
*/
#define HZ 100 

/* 
*	- TIMER_FREQ = Frequency of the timer's oscillator => T = 1/TIMER_FREQ = 0.000838 ms.
*/
#define TIMER_FREQ 1193180

/*
*	- LATCH = Value that will be written in the timer's data register (port 0x40). 
*/
#define LATCH  (TIMER_FREQ/ HZ)

/*
*	- jiffies = number of ticks since startup.
*	- jiffies/HZ = nombre of seconds since startup.
*	- startup_time = startup time in seconds (init/main.c)
*/
long volatile jiffies;
extern long startup_time;

/*
*	- clock format: hh:mm:ss
*	- In 80x25 16 colors text mode, the video memory (VGA) begins at the absolute 
*	  adress 0xb8000: top left point on the screen.
*/
#define CLOCK_POS 0xb8100

/* color: foreground white/background blue */
#define VGA_ATTR 0x1b

/* defined in isr.s */
extern long timer_interrupt(void);

/* do_timer() will be called every timer interrupt from isr.s */
void do_timer(void)
{
  int i;
  unsigned char tab[8];
  unsigned long h,r,m,s;
  unsigned char * video_ptr = (unsigned char*)(CLOCK_POS);
 
/* convert jiffies to hours, minutes and seconds */
  h = ( (jiffies/HZ)/3600 ) % 24;
  r = ( jiffies/HZ ) % 3600;
  m = r / 60;
  s = r % 60;

/* convert h,m and s to ASCII format */
  bin_to_ascii(h,&tab[0],&tab[1]);
  tab[2] = ':';
  bin_to_ascii(m,&tab[3],&tab[4]);
  tab[5] = ':';
  bin_to_ascii(s,&tab[6],&tab[7]);

/* Display the time in format: hh:mm:ss */
 for(i=0;i<8;i++)
 {
   *video_ptr = (tab[i]);
   video_ptr++;
   *video_ptr = (VGA_ATTR);
   video_ptr++;
 }
}

void timer_init(void)
{
/* mode/command register = 0x36 */
 outb(0x36, 0x43);		/* binary mode (bit 0), operating mode 3, LSB/MSB, channel 0 */
/* load the timer's data register with LATCH */
 outb(LATCH & 0xff , 0x40);	/* LSB : bits 7..0  */
 outb(LATCH >> 8 , 0x40);	/* MSB : bits 15..8 */

/* Set timer interrupt handler in IDT[0x20]:
*   Offset = &timer_interrupt, Selector = 0x8 = GDT[1] (include/system.h) 
*/
 set_intr_gate(IRQ0, &timer_interrupt);

/* startup_time in secondes, jiffies no ! */
 jiffies = startup_time*HZ;
} 

