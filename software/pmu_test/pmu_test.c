#include <stdio.h>
#include <stdlib.h>
#include "utils.h"
//#define FPGA_EMULATION
 
// The AXI4-Lite interconnect is 32bit.
// Can only read-write to 32bits at a time.
#define read_32b(addr)         (*(volatile uint32_t *)(long)(addr))
#define write_32b(addr, val_)  (*(volatile uint32_t *)(long)(addr) = val_)

#define TEST_1

// All Widths are in Bytes
#define NUM_COUNTER 4

#define COUNTER_WIDTH 4
#define CONFIG_WIDTH 4
#define TIMER_WIDTH 8

#define INSTR_WIDTH 4
#define DATA_WIDTH 4

#define NUM_INSTR 100
#define NUM_DATA 50


// For the array traversal
#define NUM_ELEMENT 100

void read_32b_regs(uint32_t num_regs, uint64_t base_addr);
void write_32b_regs(uint32_t num_regs, uint64_t base_addr, uint32_t val[]);

void read_64b_regs(uint32_t num_regs, uint64_t base_addr);
void write_64b_regs(uint32_t num_regs, uint64_t base_addr, uint64_t val[]);

int main(int argc, char const *argv[]) {
  #ifdef FPGA_EMULATION
  uint32_t baud_rate = 9600;
  uint32_t test_freq = 100000000;
  #else
  set_flls();
  uint32_t baud_rate = 115200;
  uint32_t test_freq = 100000000;
  #endif  

  uart_set_cfg(0,(test_freq/baud_rate)>>4);

  // Pointer is char to make it byte-addressable,
  // event_sel_config does not always align by 32B boundary!

  uint64_t PMU_COUNTER_BASE_ADDR      = 0x10404000;
  uint64_t PMU_EVENT_SEL_BASE_ADDR    = 0x10404000 + 1*NUM_COUNTER*COUNTER_WIDTH + 0*NUM_COUNTER*CONFIG_WIDTH;
  uint64_t PMU_EVENT_INFO_BASE_ADDR   = 0x10404000 + 1*NUM_COUNTER*COUNTER_WIDTH + 1*NUM_COUNTER*CONFIG_WIDTH;
  uint64_t PMU_INIT_BUDGET_BASE_ADDR  = 0x10404000 + 1*NUM_COUNTER*COUNTER_WIDTH + 2*NUM_COUNTER*CONFIG_WIDTH;
  uint64_t PMU_PERIOD_REG_BASE_ADDR   = 0x10404000 + 2*NUM_COUNTER*COUNTER_WIDTH + 2*NUM_COUNTER*CONFIG_WIDTH;
  uint64_t PMU_TIMER_BASE_ADDR        = 0x10404000 + 2*NUM_COUNTER*COUNTER_WIDTH + 2*NUM_COUNTER*CONFIG_WIDTH + 1*TIMER_WIDTH;

  uint64_t PMU_INSTR_SPM_BASE_ADDR    = 0x10404000;

  uint32_t counter_val[]      = {0x100, 0x200, 0x300, 0x400};
  uint32_t event_sel_val[]    = {0x1F002F, 0x1F003F, 0x1F004F, 0x1F005F};
  uint32_t event_info_val[]   = {0xA00, 0xB00, 0xC00, 0xD00};
  uint64_t init_budget_val[]  = {0xFFFFFFFFFFFFFFFE, 0xFFFFFA000, 0xFFFFFB000, 0xFFFFFC000};
  uint64_t period_val[]       = {0x0};

  uint64_t timer;

  uint32_t program[] = {0x33,
                          0xfe000ee3,
                          0xff00f93,
                          0x400f13,
                          0xe93,
                          0xfff00093,
                          0x108093,
                          0x8107,
                          0x1f15663,
                          0xffe09ae3,
                          0xfe0e86e3,
                          0x200eb3,
                          0x12900e13,
                          0x1c09007,
                          0x33,
                          0xfe000ee3};

  uint32_t program_size = sizeof(program) / sizeof(program[0]);                            

  printf("Hello PMU!\n");
  uart_wait_tx_done();

  #ifdef TEST_0
    printf("Counter\n");
    write_64b_regs(NUM_COUNTER, PMU_COUNTER_BASE_ADDR, counter_val);

    printf("EventSel Config\n");
    write_32b_regs(NUM_COUNTER, PMU_EVENT_SEL_BASE_ADDR, event_sel_val); 

    printf("EventInfo Config\n");
    write_32b_regs(NUM_COUNTER, PMU_EVENT_INFO_BASE_ADDR, event_info_val);

    printf("Initital Budget\n");
    write_64b_regs(NUM_COUNTER, PMU_INIT_BUDGET_BASE_ADDR, init_budget_val);

    printf("Period Register\n");
    write_64b_regs(1, PMU_PERIOD_REG_BASE_ADDR, period_val);
  #elif defined TEST_1
    PMU_COUNTER_BASE_ADDR   = PMU_INSTR_SPM_BASE_ADDR + NUM_INSTR*INSTR_WIDTH + NUM_DATA*DATA_WIDTH;
    PMU_EVENT_SEL_BASE_ADDR = PMU_COUNTER_BASE_ADDR + NUM_COUNTER*COUNTER_WIDTH;

    printf("Counter\n");
    write_32b_regs(NUM_COUNTER, PMU_COUNTER_BASE_ADDR, counter_val);

    printf("EventSel Config\n");
    write_32b_regs(NUM_COUNTER, PMU_EVENT_SEL_BASE_ADDR, event_sel_val);

    printf("Writing Instruction SPM\n");
    write_32b_regs(program_size, PMU_INSTR_SPM_BASE_ADDR, program);

    // Start the program
    write_32b_regs(1, (PMU_INSTR_SPM_BASE_ADDR+4), &program[0]);

    printf("Counter\n");
  #endif

  printf("Counters initialized!\n");
  uart_wait_tx_done();

  volatile uint32_t comp_array[NUM_ELEMENT] = {0};
  for (uint32_t i=0; i<NUM_ELEMENT; i++) {
     comp_array[i] = comp_array[i] + i;
  }

  printf("Array traversed!\n");
  uart_wait_tx_done();

  unsigned int val_64;

  #ifdef TEST_0
    printf("Counter\n");
    read_64b_regs(NUM_COUNTER, PMU_COUNTER_BASE_ADDR);

    printf("EventSel Config\n");
    read_32b_regs(NUM_COUNTER, PMU_EVENT_SEL_BASE_ADDR);

    printf("EventInfo Config\n");
    read_32b_regs(NUM_COUNTER, PMU_EVENT_INFO_BASE_ADDR);

    printf("Initital Budget\n");
    read_64b_regs(NUM_COUNTER, PMU_INIT_BUDGET_BASE_ADDR);

    printf("Period Register\n");
    read_64b_regs(1, PMU_PERIOD_REG_BASE_ADDR);
  
    printf("Timer Register\n");
    read_64b_regs(1, PMU_TIMER_BASE_ADDR);
  #endif

  printf("The test is over!\n");
  uart_wait_tx_done();

  return 0;
}

void read_32b_regs(uint32_t num_regs, uint64_t base_addr) {
  uint32_t val;

  for (uint32_t i=0; i<num_regs; i++) {
    val = read_32b(base_addr);

    printf("Read: %x: %x\n", base_addr, val);
    uart_wait_tx_done();

    base_addr += 4;
  }
}

void write_32b_regs(uint32_t num_regs, uint64_t base_addr, uint32_t* val) {
  for (uint32_t i=0; i<num_regs; i++) {
    write_32b(base_addr, val[i]);

    printf("Write: %x: %x\n", base_addr, val[i]);
    uart_wait_tx_done();

    base_addr += 4;
  }
}

void read_64b_regs(uint32_t num_regs, uint64_t base_addr) {
  uint32_t val_l, val_h;
  uint64_t val;

  for (uint32_t i=0; i<num_regs; i++) {
    val_l = read_32b(base_addr);
    val_h = read_32b(base_addr+4);

    val = (val_h << 32) | val_l; 

    printf("Read: %x: %x\n", base_addr, val);
    uart_wait_tx_done();

    base_addr += 8;

  }
}

void write_64b_regs(uint32_t num_regs, uint64_t base_addr, uint64_t* val) {
  uint32_t val_l, val_h;

  for (uint32_t i=0; i<num_regs; i++) {
    val_l = val[i] & 0xFFFFFFFF;
    val_h = val[i] >> 32;

    write_32b(base_addr, val_l);
    write_32b(base_addr+4, val_h);

    printf("Write: %x: %x\n", base_addr, val[i]);
    uart_wait_tx_done();

    base_addr += 8;
  }
} 


