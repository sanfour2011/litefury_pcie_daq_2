#ifndef BRAM_DATA_H
#define BRAM_DATA_H

#include <stdint.h>

typedef enum  {BRAM_HALF_A, BRAM_HALF_B} BRAM_SECTION_A_B;


void dump_bram_data(BRAM_SECTION_A_B bram_section, uint32_t *bram_data);
double measure_bram_throughput(int iterations);


#endif