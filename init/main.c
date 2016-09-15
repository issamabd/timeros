/* 
*	main.c
*
* Issam Abdallah, Information Engineer, Tunisia.
* Email: iabdallah@yandex.com
* Web site: issamabd.com
*/

#include <io.h>		/* outb(), inb() */
#include <system.h>	/* sti() */

#define ENABLE_NMI 0x00
#define DISABLE_NMI 0x80

#define CMOS_READ(addr)			\
({					\
    outb(ENABLE_NMI|addr,0x70); 	\
    inb(0x71); 				\
}) 

/* Packed BCD to binary convert */
#define BCD_TO_BIN(val) ( (val) = ( (val) & 15 ) + ( (val) >> 4 ) * 10 )

/* startup time in seconds */
long startup_time=0;

/* kernel/timer.c */
extern void timer_init(void);

/* initialize the time */
void time_init(void)
{

/* get RTC from CMOS */  
	long seconds = CMOS_READ(0);
	long minutes = CMOS_READ(2);
	long hours = CMOS_READ(4);

/* Convert to binary */
	BCD_TO_BIN(seconds);
	BCD_TO_BIN(minutes);
	BCD_TO_BIN(hours);

/* startup time in seconds */
	startup_time = seconds + minutes*60 + hours*60*60;
}

/* main function */
int main(void)
{
/* [0]! get startup_time in seconds */
 	time_init();
/* [1]! Initialise the timer hardware : kernel/timer.c */
	timer_init();
/* [2]! Interrupts have been disabled in boot/boot.s. Enable them: */
	sti();

/* [3]! loop until shutdown */
	for(;;){}

}

