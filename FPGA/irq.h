#ifndef IRQ_H
#define IRQ_H

#include <semaphore.h>

//it should runs in a thread since it runs in blocking mode and ui should still repsonsive.
extern volatile int event_count;
extern sem_t sem_pending_A;
extern sem_t sem_pending_B;

void *irq_A_thread_func(void *arg);
void *irq_B_thread_func(void *arg);

#endif