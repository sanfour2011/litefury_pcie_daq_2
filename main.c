#include <stdlib.h>
#include <ncurses.h>
#include <stdint.h>
#include <pthread.h>
#include "ui/reg.h"
#include "ui/bram_panel.h"
#include "ui/pci_info.h"
#include "FPGA/irq.h"
#include "FPGA/csr.h"
#include "FPGA/bram_data.h"
#include "FPGA/pcie_device.h"
#include "shell_exec.h"
#include <semaphore.h>

// https://invisible-island.net/ncurses/howto/NCURSES-Programming-HOWTO.html

int main(void)
{

    initscr();
    if (has_colors() == FALSE)
    {
        endwin();
        printf(" Terminal does not support color\n");
        exit(1);
    }

    noecho();
    curs_set(0);
    nodelay(stdscr, TRUE);
    start_color();
    use_default_colors();

    // declaring color pairs
    init_pair(1, COLOR_GREEN, -1);
    init_pair(2, COLOR_RED, -1);

    // Titel
    box(stdscr, 0, 0);
    attron(COLOR_PAIR(1) | A_BOLD);
    mvprintw(1, 2, " LiteFury Control ");
    attroff(COLOR_PAIR(1) | A_BOLD);
    mvhline(2, 1, ACS_HLINE, COLS - 2);
    refresh();

    int left_width = 20;            // menu Witdth
    int content_top = 3;            // start row for menu
    int content_height = LINES - 4; // -4-Lines to let place for Title Box

    mvvline(content_top, left_width, ACS_VLINE, content_height);
    refresh();

    WINDOW *left = derwin(stdscr, content_height, left_width - 1, content_top, 1);

    int right_x = left_width + 1;
    int right_width = COLS - right_x - 1;

    int pci_height = 1;
    int reg_height = 5;
    int bram_height = content_height - pci_height - reg_height - 2;

    // calc horizontal seperator lines positions and content positions
    int pci_y = content_top;
    int sep1_y = pci_y + pci_height;
    int reg_y = sep1_y + 1;
    int sep2_y = reg_y + reg_height;
    int bram_y = sep2_y + 1;

    mvhline(sep1_y, right_x, ACS_HLINE, right_width);
    mvhline(sep2_y, right_x, ACS_HLINE, right_width);
    refresh();

    WINDOW *pci = derwin(stdscr, pci_height, right_width, pci_y, right_x);
    WINDOW *reg = derwin(stdscr, reg_height, right_width, reg_y, right_x);
    WINDOW *bram = derwin(stdscr, bram_height, right_width, bram_y, right_x);

    // Command menu Left side:
    mvwprintw(left, 0, 0, "1: Start Acq");
    mvwprintw(left, 1, 0, "2: Stop Acq");
    mvwprintw(left, 1, 0, "a: Auto clear");
    mvwprintw(left, 2, 0, "c: Clear IRQ A");
    mvwprintw(left, 3, 0, "k: Clear IRQ B");
    mvwprintw(left, 4, 0, "r: Reset Board");
    mvwprintw(left, 5, 0, "l: Load Driver");
    mvwprintw(left, 6, 0, "u: Unload Driver");
    mvwprintw(left, 7, 0, "s: Rescan PCI");
    mvwprintw(left, 8, 0, "i: PCI Info");
    mvwprintw(left, 9, 0, "p: FPGA 2 Flash");
    mvwprintw(left, 10, 0, "t: Throughput");
    mvwprintw(left, 11, 0, "q: Quit");
    wrefresh(left);

    int ch;
    uint32_t bram_data[BRAM_WORDS];

    bool FPGA_LOADED = true;
    bool auto_clear = false;
    // IRQ:
    sem_init(&sem_pending_A, 0, 0);
    sem_init(&sem_pending_B, 0, 0);

    pthread_t irq_A_thread, irq_B_thread;
    pthread_create(&irq_A_thread, NULL, irq_A_thread_func, NULL);
    pthread_detach(irq_A_thread); // We dont need to wait for it runs, it never returns!
    pthread_create(&irq_B_thread, NULL, irq_B_thread_func, NULL);
    pthread_detach(irq_B_thread); // We dont need to wait for it runs, it never returns!

    int scroll_offset = 0;
    draw_pci_panel(pci);
    keypad(stdscr, TRUE);
    while ((ch = getch()) != 'q')
    {

        if (ch == KEY_UP)
            scroll_offset++;
        if (ch == KEY_DOWN)
            scroll_offset = scroll_offset > 0 ? (scroll_offset - 1) : 0;

        if (FPGA_LOADED)
        {
            if (ch == '1')
                csr_control_en_acq(1);
            if (ch == '2')
                csr_control_en_acq(0);
            if (ch == 'c' && !auto_clear)
            {
                csr_status_clear_irq_A();
                sem_post(&sem_pending_A); // todo: its better to check the status of irq_pending_B bit in CSR then call sem_post
            }
            if (ch == 'k' && !auto_clear)
            {
                csr_status_clear_irq_B();
                sem_post(&sem_pending_B); // todo: its better to check the status of irq_pending_B bit in CSR then call sem_post
            }
            if (ch == 'a')
                auto_clear = !auto_clear;
            if (ch == 't')
            {
                int iter = ask_iterations();
                double speed = measure_bram_throughput(iter);
                show_throughput_popup(speed, iter);
            }
        }
        if (ch == 'i')
            draw_pci_panel(pci);
        if (ch == 'r')
            run_shell_command("echo 1 | sudo tee /sys/bus/pci/devices/0000:01:00.0/reset");
        if (ch == 'l')
            run_shell_command("sudo pwd && insmod ./xdma.ko && lsmod | grep xdma");
        if (ch == 'u')
            run_shell_command("sudo rmmod xdma");
        if (ch == 's')
            FPGA_LOADED = pci_rescan_and_check();

        if (ch == 'p' && FPGA_LOADED)
        {
            run_shell_command("sudo rmmod xdma");
            run_shell_command("echo 1 | sudo tee /sys/bus/pci/devices/0000:01:00.0/remove");
            FPGA_LOADED = FALSE;
        }

        uint32_t ctrl_reg = csr_control_read();
        uint32_t status_reg = csr_status_read();
        dump_bram_data(bram_data);
        int irq_pending_bit_A = (status_reg & (1U << STATUS_IRQ_PENDING_A_BIT)) != 0;
        int irq_pending_bit_B = (status_reg & (1U << STATUS_IRQ_PENDING_B_BIT)) != 0;

        if (auto_clear && irq_pending_bit_A)
        {
            csr_status_clear_irq_A();
            sem_post(&sem_pending_A);
        }

        if (auto_clear && irq_pending_bit_B)
        {
            csr_status_clear_irq_A();
            sem_post(&sem_pending_A);
        }

        draw_bram_panel(bram, bram_data, scroll_offset);
        draw_reg_panel(reg, ctrl_reg, status_reg);

        mvwprintw(reg, 3, 30, "Auto clear: %d", auto_clear? 1:0);
        mvwprintw(reg, 4, 30, "irq heartbeat: %d", event_count);

        wrefresh(reg);
        napms(50);
    }

    endwin();
    return 0;
}