#include "reg.h"
#include "../FPGA/pcie_device.h"
void draw_reg_panel(WINDOW *win, uint32_t ctrl_reg, uint32_t status_reg)
{

    int running_bit = (status_reg & (1U << STATUS_RUNNING_BIT)) != 0;
    int buffer_full_bit = (status_reg & (1U << STATUS_BUFFER_FULL_BIT)) != 0;
    int irq_pending_bit_A = (status_reg & (1U << STATUS_IRQ_PENDING_A_BIT)) != 0;
    int irq_pending_bit_B = (status_reg & (1U << STATUS_IRQ_PENDING_B_BIT)) != 0;

    werase(win);
    mvwprintw(win, 0, 0, "CTRL / STATUS");
    mvwprintw(win, 0, 30, "CTRL  : 0x%08X", ctrl_reg);
    mvwprintw(win, 1, 30, "STATUS: 0x%08X", status_reg);

    mvwprintw(win, 1, 0, "is_running   : ");
    wattron(win, COLOR_PAIR(running_bit ? 1 : 2));
    wprintw(win, "%d", running_bit);
    wattroff(win, COLOR_PAIR(running_bit ? 1 : 2));

    mvwprintw(win, 2, 0, "buffer_full  : ");
    wattron(win, COLOR_PAIR(buffer_full_bit ? 2 : 1));
    wprintw(win, "%d", buffer_full_bit);
    wattroff(win, COLOR_PAIR(running_bit ? 2 : 1));

    mvwprintw(win, 3, 0, "irq_pending A: ");
    if (irq_pending_bit_A)
    {
        wattron(win, COLOR_PAIR(2));
        wprintw(win, "A PENDING");
        wattroff(win, COLOR_PAIR(2));
    }
    else
        wprintw(win, "0");

    mvwprintw(win, 4, 0, "irq_pending B: ");
    if (irq_pending_bit_B)
    {
        wattron(win, COLOR_PAIR(2));
        wprintw(win, "B PENDING");
        wattroff(win, COLOR_PAIR(2));
    }
    else
        wprintw(win, "0");

    wrefresh(win);
}