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

#include "encoding.h"
#include <stdio.h>
#include <stdlib.h>
#include "utils.h"
#include "pmu_test_func.c"
#define JUMP_CUA 8
#define CUA_RD

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

  uint32_t program[] = {0x33,
                        0x400593,
                        0xfb7,
                        0xf8f93,
                        0xfaf03,
                        0x4fad03,
                        0x8fad83,
                        0xcfae03,
                        0x10fae83,
                        0x93,
                        0x8107,
                        0x108093,
                        0x8187,
                        0x40310233,
                        0x108093,
                        0x8287,
                        0x108093,
                        0x8307,
                        0x406283b3,
                        0x3a38433,
                        0x3b304b3,
                        0x940533,
                        0x2250533,
                        0xfde544e3,
                        0x178793,
                        0x33,
                        0x33,
                        0x33,
                        0xfc0000e3,
                        0x33,
                        0xfe000ee3};

  uint32_t dspm_val[] = {1000,
                        16,
                        21,
                        13,
                        9};

  // Pointer is char to make it byte-addressable,
  // event_sel_config does not always align by 32B boundary!
  // error_count += run_pmu_core_test_suite (ISPM_BASE_ADDR, 
  //                                         COUNTER_BASE_ADDR, 
  //                                         DSPM_BASE_ADDR, 
  //                                         PMC_STATUS_ADDR,
  //                                         COUNTER_BUNDLE_SIZE,
  //                                         NUM_COUNTER,
  //                                         20, 
  //                                         2);
  uint32_t DEBUG = 2;
  uint32_t instruction;
  instruction = encodeLUI(31, DSPM_BASE_ADDR >> 12, (DEBUG >= 2));
  program[1] = instruction;
  instruction = encodeADDI(31, 31, DSPM_BASE_ADDR & 0xFFF, (DEBUG >= 2));
  program[2] = instruction;
  uint32_t program_size  = sizeof(program) / sizeof(program[0]);
  uint32_t dspm_val_size = sizeof(dspm_val) / sizeof(dspm_val[0]);

  printf("Writing to SPMs!\n");
  error_count += test_spm(ISPM_BASE_ADDR,program_size,program);
  error_count += test_spm(DSPM_BASE_ADDR,dspm_val_size,dspm_val);

  printf("Updating event_sel_cfg!\n");
  uint32_t event_sel[]  = {LLC_RD_REQ_CORE_0,   // 0
                          MEM_RD_REQ_CORE_0,
                          LLC_RD_RES_CORE_0,    // 1
                          MEM_RD_RES_CORE_0,
                          LLC_RD_RES_CORE_0,    // 2
                          MEM_RD_RES_CORE_0,
                          LLC_RD_RES_CORE_0,    // 3
                          MEM_RD_RES_CORE_0};
  write_32b_regs(EVENT_SEL_BASE_ADDR, 8, event_sel, COUNTER_BUNDLE_SIZE);
  
  printf("Starting PMU Core!\n");
  write_32b(PMC_STATUS_ADDR,0);
  // uint32_t len = 20;
  // uint32_t rand_arr[len];
  // for(uint32_t i=0; i<len; i++) {
  //   uint32_t seed = (uint32_t)(0x1040 * i + len);
  //   rand_arr[i] = (uint32_t)(my_rand(seed));
  // }

  // bubble_sort(rand_arr, 20);
  // for (uint32_t i=0; i<len; i++) {
  //   printf("%x: %0d\n",i, rand_arr[i]);
  // }

  uint64_t var;
  uint64_t a_len2 = 16384*2;
  uint64_t N_REPEAT = 3;
  volatile uint64_t *array = (uint64_t*) 0x83000000;
  for (uint32_t a_repeat = 0; a_repeat < N_REPEAT; a_repeat++){
      for (uint32_t a_idx = 0; a_idx < a_len2; a_idx+=JUMP_CUA) {
        #ifdef CUA_RD
          asm volatile ( 
            "ld   %0, 0(%1)\n"  // read addr_var data into read_var
            : "=r"(var)
            : "r"(array - a_idx)
          );
        #elif defined(CUA_WR)
          var = a_idx;
          asm volatile ( 
            "sd   %0, 0(%1)\n"  // read addr_var data into read_var
            :: "r"(var),
               "r"(array - a_idx)
          );
        #endif
      }
    }

  printf("The test is over!\n");
  printf("Errors: %0d\n", error_count);
  uart_wait_tx_done();

  return 0;
}




