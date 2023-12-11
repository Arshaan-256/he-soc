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

  error_count = test_case_study_without_debug (
                     ISPM_BASE_ADDR,
                     DSPM_BASE_ADDR,
                     PMC_STATUS_ADDR, 
                     COUNTER_BASE_ADDR,
                     COUNTER_BUNDLE_SIZE,
                     4,
                     2);

  // uint64_t var;
  // uint64_t a_len2 = 16384*2;
  // uint64_t N_REPEAT = 3;
  // volatile uint64_t *array = (uint64_t*) 0x83000000;
  // for (uint32_t a_repeat = 0; a_repeat < N_REPEAT; a_repeat++){
  //     for (uint32_t a_idx = 0; a_idx < a_len2; a_idx+=JUMP_CUA) {
  //       #ifdef CUA_RD
  //         asm volatile ( 
  //           "ld   %0, 0(%1)\n"  // read addr_var data into read_var
  //           : "=r"(var)
  //           : "r"(array - a_idx)
  //         );
  //       #elif defined(CUA_WR)
  //         var = a_idx;
  //         asm volatile ( 
  //           "sd   %0, 0(%1)\n"  // read addr_var data into read_var
  //           :: "r"(var),
  //              "r"(array - a_idx)
  //         );
  //       #endif
  //     }
  //   } 

  printf("The test is over!\n");
  printf("Errors: %0d\n", error_count);
  uart_wait_tx_done();

  return 0;
}