//#include "util.h"
#include <stdio.h>
#include <stdlib.h>
#include "utils.h"
//#define FPGA_EMULATION

 

#define cfg_write(addr, val_)  (*(volatile unsigned int *)(long)(addr) = val_)
#define cfg_read(addr)         (*(volatile unsigned int *)(long)(addr))

 

// All Widths are in Bytes
#define NUM_COUNTER 4
#define TIMER_WIDTH 8
#define COUNTER_WIDTH 8
#define CONFIG_WIDTH 4
#define NUM_ELEMENT 100

 

#define INSTR_WIDTH 4

 

void read_counters(int num_counter, long long unsigned int BASE_ADDR, int REG_SIZE_IN_BYTES);
void write_counters(int num_counter, long long unsigned int BASE_ADDR, int REG_SIZE_IN_BYTES, long long int val[]);

 

int main(int argc, char const *argv[]) {

 

  #ifdef FPGA_EMULATION
  int baud_rate = 9600;
  int test_freq = 100000000;
  #else
  set_flls();
  int baud_rate = 115200;
  int test_freq = 100000000;
  #endif  
  uart_set_cfg(0,(test_freq/baud_rate)>>4);

 

  // Pointer is char to make it byte-addressable,
  // event_sel_config does not always align by 32B boundary!
  long long unsigned int PMU_COUNTER_BASE_ADDR      = 0x10404000;
  long long unsigned int PMU_EVENT_SEL_BASE_ADDR    = 0x10404000 + 1*NUM_COUNTER*8 + 0*NUM_COUNTER*4;
  long long unsigned int PMU_EVENT_INFO_BASE_ADDR   = 0x10404000 + 1*NUM_COUNTER*8 + 1*NUM_COUNTER*4;
  long long unsigned int PMU_INIT_BUDGET_BASE_ADDR  = 0x10404000 + 1*NUM_COUNTER*8 + 2*NUM_COUNTER*4;
  long long unsigned int PMU_PERIOD_REG_BASE_ADDR   = 0x10404000 + 2*NUM_COUNTER*8 + 2*NUM_COUNTER*4;
  long long unsigned int PMU_TIMER_BASE_ADDR        = 0x10404000 + 2*NUM_COUNTER*8 + 2*NUM_COUNTER*4 + 1*TIMER_WIDTH;
  long long unsigned int PMU_INSTR_SPM_BASE_ADDR    = 0x10404000;

 

  long long int counter_val[]      = {0x100, 0x200, 0x300, 0x400};
  long long int event_sel_val[]    = {0x1F002F, 0x1F003F, 0x1F004F, 0x1F005F};
  long long int event_info_val[]   = {0xA00, 0xB00, 0xC00, 0xD00};
  long long int init_budget_val[]  = {0xFFFFFFFFFFFFFFFE, 0xFFFFFA000, 0xFFFFFB000, 0xFFFFFC000};
  long long int period_val[]       = {0x10};
  long long int timer;

 

  int instr_spm[] = {0x06400093, 
                     0x0c808113, 
                     0x002081b3, 
                     0x00108233, 
                     0x40110133,
                     0x00200393,
                     0x0043a223,
                     0x0043a283, 
                     0x00000013, 
                     0xfe000ee3, 
                     0x00000013};

 

  printf("Hello PMU!\n");
  uart_wait_tx_done();

 

  printf("Counter\n");
  write_counters(NUM_COUNTER, PMU_COUNTER_BASE_ADDR, COUNTER_WIDTH, counter_val);
  printf("EventSel Config\n");
  write_counters(NUM_COUNTER, PMU_EVENT_SEL_BASE_ADDR, CONFIG_WIDTH, event_sel_val);
  printf("EventInfo Config\n");
  write_counters(NUM_COUNTER, PMU_EVENT_INFO_BASE_ADDR, CONFIG_WIDTH, event_info_val);
  printf("Initital Budget\n");
  write_counters(NUM_COUNTER, PMU_INIT_BUDGET_BASE_ADDR, COUNTER_WIDTH, init_budget_val);
  printf("Period Register\n");
  write_counters(1, PMU_PERIOD_REG_BASE_ADDR, COUNTER_WIDTH, period_val);

 

  printf("Counters initialized!\n");
  uart_wait_tx_done();

 

  volatile uint32_t comp_array[NUM_ELEMENT] = {0};
  for (int i=0; i<NUM_ELEMENT; i++) {
     comp_array[i] = comp_array[i] + i;
  }

 

  printf("Array traversed!\n");
  uart_wait_tx_done();
  unsigned int val_64;

 

  printf("Counter\n");
  read_counters(NUM_COUNTER, PMU_COUNTER_BASE_ADDR, COUNTER_WIDTH);
  printf("EventSel Config\n");
  read_counters(NUM_COUNTER, PMU_EVENT_SEL_BASE_ADDR, CONFIG_WIDTH);
  printf("EventInfo Config\n");
  read_counters(NUM_COUNTER, PMU_EVENT_INFO_BASE_ADDR, CONFIG_WIDTH);
  printf("Initital Budget\n");
  read_counters(NUM_COUNTER, PMU_INIT_BUDGET_BASE_ADDR, COUNTER_WIDTH);
  printf("Period Register\n");
  read_counters(1, PMU_PERIOD_REG_BASE_ADDR, TIMER_WIDTH);
  printf("Timer Register\n");
  read_counters(1, PMU_TIMER_BASE_ADDR, TIMER_WIDTH);

 

  int NUM_INSTR = sizeof(instr_spm) / sizeof(instr_spm[0]);

 

  // printf("Writing Instruction SPM\n");
  // write_counters(NUM_INSTR, PMU_INSTR_SPM_BASE_ADDR, INSTR_WIDTH, instr_spm);

 

  // printf("Reading Instruction SPM\n");
  // read_counters(NUM_INSTR, PMU_INSTR_SPM_BASE_ADDR, INSTR_WIDTH);

 

  printf("The test is over!\n");
  uart_wait_tx_done();
  return 0;
}

 

void read_counters(int num_counter, long long unsigned int BASE_ADDR, int REG_SIZE_IN_BYTES) {
  // Make sure the read variable is 32bit.
  // The AXI4-Lite interconnect is 32bit.
  unsigned int val;
  for (int i=0; i<num_counter; i++) {
    val = *(long*)(BASE_ADDR);
    printf("Read: %x: %x\n", BASE_ADDR, val);
    uart_wait_tx_done();
    BASE_ADDR += REG_SIZE_IN_BYTES;
  }
}

 

void write_counters(int num_counter, long long unsigned int BASE_ADDR, int REG_SIZE_IN_BYTES, long long val[]) {
  // The AXI4-Lite interconnect is 32bit.
  // Can only write to 32bits at a time.
  for (int i=0; i<num_counter; i++) {
    if (REG_SIZE_IN_BYTES==4) {
      cfg_write(BASE_ADDR, val[i]);
    } else if (REG_SIZE_IN_BYTES==8) {
      int val_l = val[i] & 0xFFFFFFFF;
      int val_h = val[i] >> 32;

 

      cfg_write(BASE_ADDR, val_l);
      cfg_write(BASE_ADDR+4, val_h);
    }
    printf("Write: %x: %x\n", BASE_ADDR, val[i]);
    uart_wait_tx_done();
    BASE_ADDR += REG_SIZE_IN_BYTES;
  }
}