/// This assumes the following: 
///   1. The PMU counters (including the initial budget registers) are 32-bit with 
///      the 31st bit reserved for Pending.
///   2. Both the configuration registers are 32-bits.
///
/// NUM_COUNTER is parameterizable and should be set to the number of counters in the PMU.
/// The memory map of the PMU is as follows:
///     /************************************\
///     | Initial Budget Register            |
///     | Event Info Configuration Register  |          Not yet 4kB aligned
///     | Event Selection Register           |              Counter Bundle
///     | Counter                            |
///     \************************************/
///                     .
///                     .                         ... x (NUM_COUNTER)
///                     .
///     /************************************\
///     | Initial Budget Register            |
///     | Event Info Configuration Register  |          Not yet 4kB aligned          
///     | Event Selection Register           |              Counter Bundle
///     | Counter                            |
///     \************************************/
///     /************************************\
///     | Initial Budget Register            |
///     | Event Info Configuration Register  |          Not yet 4kB aligned
///     | Event Selection Register           |              Counter Bundle
///     | Counter                            |
///     \************************************/
///     /************************************\
///     | MemGuard Period Register           |          Not yet 4kB aligned
///     | PMU Timer                          |              PMU Bundle
///     \************************************/
/// Each block is a separate 4kB-aligned page.
/// The PMU Bundle includes the PMU Timer and the MemGuard Period Register.
/// A counter bundle includes:
///     1. Counter
///     2. Event Selection Register
///     3. Event Info Configuration Register
///     4. Initial Budget Register

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

  uart_set_cfg(0,(test_freq/baud_rate)>>4);

  uint32_t error_count = 0;

  // Pointer is char to make it byte-addressable,
  // event_sel_config does not always align by 32B boundary!

  // Two 64-bit (8B) timer and one 32-bit status registers in the PMU bundle.
  uint64_t PMU_BUNDLE_SIZE        = 2 * 8 + 4;

  // Four 32-bit (4B) registers in one counter bundle.
  uint64_t COUNTER_BUNDLE_SIZE    = 4 * 4;

  // Base Addresses
  uint64_t PMU_BASE_ADDR          = 0x10404000;     // Timer Base Address
  uint64_t PERIOD_BASE_ADDR       = PMU_BASE_ADDR + 0x8;
  uint64_t STATUS_BASE_ADDR       = PMU_BASE_ADDR + 0x8*2;

  uint64_t COUNTER_BASE_ADDR      = PMU_BASE_ADDR + PMU_BUNDLE_SIZE;
  uint64_t EVENT_SEL_BASE_ADDR    = COUNTER_BASE_ADDR + 0x4;
  uint64_t EVENT_INFO_BASE_ADDR   = EVENT_SEL_BASE_ADDR + 0x4;
  uint64_t INIT_BUDGET_BASE_ADDR  = EVENT_INFO_BASE_ADDR + 0x4;

  uint64_t ISPM_BASE_ADDRESS      = 0x10405000;
  uint64_t DSPM_BASE_ADDRESS      = 0x10406000;
  
  uint32_t counter_val[]          = {0x100, 0x200, 0x300, 0x400};
  uint32_t event_sel_val[]        = {0x1FAB00, 0x1FAB01, 0x1FAB02, 0x1FAB03};
  uint32_t event_info_val[]       = {0xA00, 0xB00, 0xC00, 0xD00};
  uint32_t init_budget_val[]      = {0xFFFFFFE0, 0xFFFFA000, 0xFFFFB000, 0xFFFFC000};
  uint64_t period_val             = 0x0;
  uint64_t timer;
  
  counter_b_t counter_b[NUM_COUNTER];

  for (int i=0; i<NUM_COUNTER; i++) {
    counter_b[i].counter     = counter_val[i];
    counter_b[i].event_sel   = event_sel_val[i];
    counter_b[i].event_info  = event_info_val[i];
    counter_b[i].init_budget = init_budget_val[i];
  }

  uint32_t program[] = {0x593,
                        0x593,
                        0x200193,
                        0x93,
                        0x100026f,
                        0x13,
                        0x13,
                        0x400006f,
                        0x117,
                        0xff410113,
                        0x2411a63,
                        0x100093,
                        0x140006f,
                        0x108093,
                        0x108093,
                        0x108093,
                        0x108093,
                        0x108093,
                        0x108093,
                        0x300e93,
                        0x300193,
                        0x1d09463,
                        0x301863,
                        0xa00593,
                        0x33,
                        0xfe000ee3,
                        0xc00593,
                        0x33,
                        0xfe000ee3};

  uint32_t program_size = sizeof(program) / sizeof(program[0]);                            

  printf("Hello PMU!\n");
  uart_wait_tx_done();

  // unstall core here
  // write_32b(base_addr, counter_b.event_info);

  // # ifdef TEST_5
  //   uint64_t counter_b_addr = COUNTER_BASE_ADDR;
  //   printf("Initialize all counter bundles.\n");
  //   uart_wait_tx_done();  

  //   for(int i=0; i<NUM_COUNTER; i++) {
  //     printf("writing to %x\r\n", counter_b_addr);
  //     write_counter_b(counter_b[i], counter_b_addr);
  //     counter_b_addr = counter_b_addr + COUNTER_BUNDLE_SIZE;
  //   }

  //   counter_b_t cb;
  //   printf("Read all counter bundles.\n");
  //   uart_wait_tx_done();  
    
  //   counter_b_addr = COUNTER_BASE_ADDR;
  //   for(uint32_t i=0; i<NUM_COUNTER; i++) {
  //     printf("Reading from %x\r\n", counter_b_addr);    
  //     cb = read_counter_b(counter_b_addr);
  //     counter_b_addr = counter_b_addr + COUNTER_BUNDLE_SIZE;

  //     if (cb.counter != counter_b[i].counter) {
  //       error_count += 1;
  //       printf("Error: Read counter is different from written\n. %x vs %x", cb.counter, counter_b[i].counter);
  //     }
  //     if (cb.event_sel != counter_b[i].event_sel) {
  //       error_count += 1;
  //       printf("Error: Read event_sel is different from written\n. %x vs %x", cb.event_sel, counter_b[i].event_sel);
  //     }
  //     if (cb.event_info != counter_b[i].event_info) {
  //       error_count += 1;
  //       printf("Error: Read event_info is different from written\n. %x vs %x", cb.event_info, counter_b[i].event_info);
  //     }
  //     if (cb.init_budget != counter_b[i].init_budget) {
  //       error_count += 1;
  //       printf("Error: Read init_budget is different from written\n. %x vs %x", cb.init_budget, counter_b[i].init_budget);
  //     }
  //   }
  // #endif

  // #ifdef TEST_4
  //   uint32_t read_program[program_size];

  //   printf("Initialize ISPM.\n");
  //   write_spm_4B(program_size, ISPM_BASE_ADDRESS, program);

  //   printf("Reading ISPM.\n");
  //   read_spm_4B(program_size, ISPM_BASE_ADDRESS, read_program);

  //   for (uint32_t i=0; i<program_size; i++) {
  //     if (program[i] != read_program[i]) {
  //       error_count += 1;
  //       printf("Program at index [%0d] is different from written.");
  //     }
  //   }

  //   printf("Starting the core!\n");
  //   write_32b(STATUS_BASE_ADDR, 0);
  // #endif 

  uint32_t err_count = 0;
  uint32_t err;

  // Testing for ISPM
  err = test_spm(ISPM_BASE_ADDRESS, program_size, program);
  err_count += err;
  
  // Testing for DSPM
  err = test_spm_rand(DSPM_BASE_ADDRESS, 100);

  err_count += err;

  // uint32_t num = 0;
  // uint32_t output = 0;
  // for (uint32_t i=0; i<20; i++) {
  //   write_32b(STATUS_BASE_ADDR, 0);
  //   num = i*NUM_ELEMENT;
  //   output = array_traversal(num);
  //   write_32b(STATUS_BASE_ADDR, 1);
  // }


  printf("The test is over!\n");
  printf("Errors: %0d\n", error_count);
  uart_wait_tx_done();

  return 0;
}

counter_b_t read_counter_b(uint64_t base_addr) {
  counter_b_t counter_b;

  counter_b.counter     = read_32b(base_addr);
  base_addr = base_addr + 0x4;

  counter_b.event_sel   = read_32b(base_addr);
  base_addr = base_addr + 0x4;
  
  counter_b.event_info  = read_32b(base_addr);
  base_addr = base_addr + 0x4;
  
  counter_b.init_budget = read_32b(base_addr);
  
  #ifdef DEBUG
    printf("Read CounterBundle: %x %x %x %x\n", 
            counter_b.counter, 
            counter_b.event_sel, 
            counter_b.event_info, 
            counter_b.init_budget);
  #endif
  
  return counter_b;  
}



