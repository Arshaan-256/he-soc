#include "pmu_test_func.c"

// *********************************************************************
// Main Function
// *********************************************************************
int main(int argc, char const *argv[]) {
  #ifdef FPGA_EMULATION
  uint32_t baud_rate = 9600;
  uint32_t test_freq = 100000000;
  #else
  set_flls();
  uint32_t baud_rate = 115200;
  uint32_t test_freq = 100000000;
  #endif

  volatile uint32_t read_target_0;
  volatile uint32_t read_target_1;
  volatile uint32_t read_target_2;
  volatile uint32_t read_target_3;

  uart_set_cfg(0,(test_freq/baud_rate)>>4);

  uint32_t mhartid;
  asm volatile (
    "csrr %0, 0xF14\n"
    : "=r" (mhartid)
  );

  uint32_t dspm_base_addr = DSPM_BASE_ADDR;
  uint32_t read_target;
  uint32_t error_count = 0;

  uint32_t counter_val[]          = {0x1, 0x2, 0x3, 0x4};
  uint32_t event_sel_val[]        = {0x1000, 0x2000, 0x3000, 0x4000};
  uint32_t port_1_event_sel_val[]    = {0x1F0011, 0x1F0021, 0x1F003F, 0x1F004F};
  uint32_t port_2_event_sel_val[]    = {0x2F001F, 0x2F002F, 0x2F003F, 0x2F004F};
  uint32_t event_info_val[]       = {0x10, 0x20, 0x30, 0x40};
  uint32_t init_budget_val[]      = {0x100, 0x200, 0x300, 0x400};

  counter_b_t counter_b[NUM_COUNTER];

  for (uint32_t i=0; i<NUM_COUNTER; i++) {
    counter_b[i].counter     = counter_val[i];
    counter_b[i].event_sel   = event_sel_val[i];
    counter_b[i].event_info  = event_info_val[i];
    counter_b[i].init_budget = init_budget_val[i];
  }

  // *******************************************************************
  // Core 0
  // *******************************************************************
  if (mhartid == 0) {
    write_32b(dspm_base_addr, 0xF0);

    while (1) {  
      read_target_0 = read_32b(dspm_base_addr);
      if (read_target_0 == 0xF0) {
        break;
      }
    }
    printf("Hello CVA6-0!\n");
    uart_wait_tx_done();
    // error_count += test_spm_rand(ISPM_BASE_ADDR, 100);
    // printf("Testing counters!\n");
    // error_count += test_counter_bundle(COUNTER_BASE_ADDR, NUM_COUNTER, COUNTER_BUNDLE_SIZE, counter_b);

    // Setup event_sel registers.
    printf("Setting up event_sel_config!\n");
    uart_wait_tx_done();
    write_32b_regs(EVENT_SEL_BASE_ADDR, NUM_COUNTER, port_1_event_sel_val, COUNTER_BUNDLE_SIZE);

    printf("CVA6-0 Over, errors: %0d!\n", error_count);
    uart_wait_tx_done();

    asm volatile ("fence");
    write_32b(dspm_base_addr, 0xF91);
    asm volatile ("fence");

    uint32_t result_0 = array_traversal(NUM_ELEMENT*(1));
  // *******************************************************************
  // Core 1
  // *******************************************************************
  } else if (mhartid == 1) {
    while (1) {
      asm volatile ("fence");
      read_target_1 = read_32b(dspm_base_addr);
      if (read_target_1 == 0xF91) {
        break;
      }
    }
    printf("Hello CVA6-1!\n");
    // uart_wait_tx_done();
    // error_count += test_spm_rand(ISPM_BASE_ADDR, 100);
    // printf("CVA6-1 Over, errors: %0d!", error_count);

    // // Update DSPM target variable.
    // asm volatile ( 
    //   "li   %0, 0xF2\n"  // write read_var into addr_var
    //   : "=r"(read_target_1)
    // );

    // asm volatile ( 
    //   "sw   %0, 0(%1)\n"  // write read_var into addr_var
    //   : "=r"(read_target_1)
    //   : "r"(dspm_base_addr)
    // );   
    while (1) { 
      uint32_t result_1 = array_traversal(NUM_ELEMENT*(10+1));
    }
  // *******************************************************************
  // Core 2
  // *******************************************************************
  } else if (mhartid == 2) {
    // while (1) {
    //   asm volatile ( 
    //     "lw   %0, 0(%1)\n"  // read addr_var data into read_var
    //     : "=r"(read_target_2)
    //     : "r"(dspm_base_addr)
    //   );
    //   if (read_target_2 == 0xF2) {
    //     break;
    //   }
    // }
    // printf("Hello CVA6-2!\n");
    // uart_wait_tx_done();
    // error_count += test_spm_rand(ISPM_BASE_ADDR, 100);
    // printf("CVA6-2 Over, errors: %0d!", error_count);

    // // Update DSPM target variable.
    // asm volatile ( 
    //   "li   %0, 0xF3\n"  // write read_var into addr_var
    //   : "=r"(read_target_2)
    // );

    // asm volatile ( 
    //   "sw   %0, 0(%1)\n"  // write read_var into addr_var
    //   : "=r"(read_target_2)
    //   : "r"(dspm_base_addr)
    // );
    while (1) { 
      uint32_t result_2 = array_traversal(NUM_ELEMENT*(11+1));
    }
  // *******************************************************************
  // Core 3
  // *******************************************************************
  } else if (mhartid == 3) {
    // while (1) {
    //   asm volatile ( 
    //     "lw   %0, 0(%1)\n"  // read addr_var data into read_var
    //     : "=r"(read_target_3)
    //     : "r"(dspm_base_addr)
    //   );
    //   if (read_target_3 == 0xF3) {
    //     break;
    //   }
    // }
    // printf("Hello CVA6-3!\n");
    // uart_wait_tx_done();
    // error_count += test_spm_rand(ISPM_BASE_ADDR, 100);
    // printf("CVA6-3 Over, errors: %0d!", error_count);

    // // Update DSPM target variable.
    // asm volatile ( 
    //   "li   %0, 0xF4\n"  // write read_var into addr_var
    //   : "=r"(read_target_3)
    // );

    // asm volatile ( 
    //   "sw   %0, 0(%1)\n"  // write read_var into addr_var
    //   : "=r"(read_target_3)
    //   : "r"(dspm_base_addr)
    // );
    while (1) { 
      uint32_t result_3 = array_traversal(NUM_ELEMENT*(12+1));
    }
  }

  uint32_t counter_rval[] = {0x0, 0x0, 0x0, 0x0};
  read_32b_regs(COUNTER_BASE_ADDR, NUM_COUNTER, counter_rval, COUNTER_BUNDLE_SIZE);
  printf("Reading output\n");
  for (uint32_t i=0; i<NUM_COUNTER; i++) {
    printf("  Counter %0d: %0d (%x) \n", i, counter_rval[i] & 0x7FFFFFFF, counter_rval[i]);
  }
  // printf("The test is over!\n");
  // printf("Errors: %0d\n", error_count);
  // uart_wait_tx_done();

  return 0;
}




