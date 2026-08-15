#include <fcntl.h>
#include "irq.h"
#include <unistd.h>
#include "pcie_device.h"
#include <errno.h>
#include <stdio.h>
#include <semaphore.h>

volatile int event_count = 0;
sem_t sem_pending_A;
sem_t sem_pending_B;

// Never ever call this function in a loop
// no close() here on purpose, this thread never exits (infinite loop),
// fd stays open till the whole program dies anyway, OS cleans it up then (https://www.man7.org/linux/man-pages/man2/exit.2.html),
// close(fd) would be necessary if are opneing fd sveral times in a loop.
// https://www.man7.org/linux/man-pages/man2/pread.2.html
void *irq_thread_func(void *arg)
{
    (void)arg;
    return NULL;
    int fd = open(USR_IRQ_EVENT_FILE, O_RDONLY | O_SYNC);
    if (fd < 0)
        return NULL;
    for (;;)
    {
        int val = 0;
        ssize_t n = read(fd, &val, sizeof(val));
        printf("read() returned n=%zd val=%d errno=%d\n", n, val, errno);
    }
    return NULL;
}
