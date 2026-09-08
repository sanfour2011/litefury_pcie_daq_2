#include <fcntl.h>
#include "irq.h"
#include <unistd.h>
#include "pcie_device.h"
#include <errno.h>
#include <stdio.h>

volatile int event_count = 0;
sem_t sem_pending_A;
sem_t sem_pending_B;

// Never ever call this function in a loop
// no close() here on purpose, this thread never exits (infinite loop),
// fd stays open till the whole program dies anyway, OS cleans it up then (https://www.man7.org/linux/man-pages/man2/exit.2.html),
// close(fd) would be necessary if are opneing fd sveral times in a loop.
// https://www.man7.org/linux/man-pages/man2/pread.2.html
// same thing for sem_close()
void *irq_A_thread_func(void *arg)
{
    (void)arg;

    int fd = open(USR_IRQ_EVENT_A_FILE, O_RDONLY | O_SYNC);
    if (fd < 0)
        return NULL;
    for (;;)
    {
        int val = 0;
        read(fd, &val, sizeof(val));
        // ssize_t n = read(fd, &val, sizeof(val));
        //printf("read() returned n=%zd val=%d errno=%d\n", n, val, errno);
        sem_wait(&sem_pending_A);
    }
    return NULL;
}

void *irq_B_thread_func(void *arg)
{
    (void)arg;

    int fd = open(USR_IRQ_EVENT_B_FILE, O_RDONLY | O_SYNC);
    if (fd < 0)
        return NULL;
    for (;;)
    {
        int val = 0;
        read(fd, &val, sizeof(val));
        // ssize_t n = read(fd, &val, sizeof(val));
        //printf("read() returned n=%zd val=%d errno=%d\n", n, val, errno);
        sem_wait(&sem_pending_B);
    }
    return NULL;
}
