#ifndef __TIMER_H
#define __TIMER_H

void timer_init(void);
void do_timer(void);

static inline void
bin_to_ascii(unsigned long t, unsigned char* t1, unsigned char* t2)
{

 long  q = t/10;
 *t2 = (t%10 + 48);
 t=q;
 q = t/10;
 *t1 = (t%10 + 48);

}  

#endif /* __TIMER_H */
