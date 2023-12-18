#include "encoding.h"
#include <stdio.h>
#include <stdlib.h>
#include "utils.h"
#include "pmu_test_func.c"

// The CUA will always miss in the L1 but after one run of the loop, it will never miss in the LLC.
#define NUM_NON_CUA 3

#ifndef TESTS_AUTO
  #define JUMP_CUA        8    // multiply by 8 for bytes
  #define JUMP_NONCUA     8    // multiply by 8 for bytes
  // #define LEN_NONCUA   32768
  // #define LEN_NONCUA   524288
  #define LEN_NONCUA   40960      // array size: 320 kB
  // #define LEN_NONCUA   262144  // array size: 2048 kB
  #define START_NONCUA    0
#endif


#define INTF_RD

void test_cache(uint32_t num_counter, uint32_t *print_info);
void test_cache2(uint32_t num_counter, uint32_t *print_info);

// Sometimes the UART skips over output.
// Gives the UART more time to finish output before filling up the UART Tx FIFO with more data.
void my_sleep() {
  uint32_t sleep = 100000;
  for (volatile uint32_t i=0; i<sleep; i++) {
    asm volatile ("fence");
    asm volatile ("addi x1, x1, 1");
    asm volatile ("fence");
  }  
}

void end_test(uint32_t mhartid){
  printf("Exiting: %0d.\r\n", mhartid);
}

#define write_32b(addr, val_)  (*(volatile uint32_t *)(long)(addr) = val_)

// *********************************************************************
// Main Function
// *********************************************************************
int main(int argc, char const *argv[]) {
  
  volatile uint32_t read_target_0;
  volatile uint32_t read_target_1;
  volatile uint32_t read_target_2;
  volatile uint32_t read_target_3;

  

  uint32_t mhartid;
  asm volatile (
    "csrr %0, 0xF14\n"
    : "=r" (mhartid)
  );

  uint32_t dspm_base_addr;
  uint32_t read_target;
  uint32_t error_count = 0;

  // *******************************************************************
  // Core 0
  // *******************************************************************
  if (mhartid == 0) {   
    #ifdef FPGA_EMULATION
    uint32_t baud_rate = 9600;
    uint32_t test_freq = 100000000;
    #else
    set_flls();
    uint32_t baud_rate = 115200;
    uint32_t test_freq = 50000000;
    #endif
    uart_set_cfg(0,(test_freq/baud_rate)>>4);

    // Partition the cache.
    write_32b(0x50 + 0x10401000, 0xFFFFFF00);
    write_32b(0x54 + 0x10401000, 0xFFFF00FF);
    write_32b(0x58 + 0x10401000, 0xFF00FFFF);
    write_32b(0x5c + 0x10401000, 0x00FFFFFF);

    // Wait before running the program.
    uint32_t var;
    volatile uint64_t *array = (uint64_t*) 0x83000000;
    for (int a_idx = START_NONCUA; a_idx < LEN_NONCUA / 1024; a_idx +=JUMP_NONCUA) {
      #ifdef INTF_RD
        asm volatile (
          "ld   %0, 0(%1)\n"
          : "=r"(var)
          : "r"(array - a_idx)
        );
      #elif defined(INTF_WR)
        var = a_idx;
        asm volatile (
          "sd   %0, 0(%1)\n"
          :: "r"(var),
              "r"(array - a_idx)
        );
      #endif
    }
    
    #ifdef RD_WITH_RD
      printf("Read on read contention Jump=%d Len=%d\r\n", JUMP_CUA, LEN_NONCUA);
    #elif defined(WR_WITH_WR)
      printf("Write on write contention, Jump=%d Len=%d\r\n", JUMP_CUA, LEN_NONCUA);
    #elif defined(RD_ONLY)
      printf("Only read in CUA, Jump=%d Len=%d\r\n", JUMP_CUA, LEN_NONCUA);
    #elif defined(WR_ONLY)
      printf("Only write in CUA, Jump=%d Len=%d\r\n", JUMP_CUA, LEN_NONCUA);
    #elif defined(RD_WITH_WR)
      printf("Read on write contention, Jump=%d Len=%d\r\n", JUMP_CUA, LEN_NONCUA);
    #elif defined(WR_WITH_RD)
      printf("Write on read contention, Jump=%d Len=%d\r\n", JUMP_CUA, LEN_NONCUA);
    #endif
  
    uint32_t num_counter = 18;
                            // CORE 0
    uint32_t event_sel[] = {LLC_RD_REQ_CORE_0,    // 0
                            LLC_WR_REQ_CORE_0,    // 1
                            LLC_RD_RES_CORE_0,    // 2
                            LLC_WR_RES_CORE_0,    // 3
                            // CORE 1
                            LLC_RD_REQ_CORE_1,    // 4
                            MEM_RD_REQ_CORE_1,    // 5
                            LLC_WR_REQ_CORE_1,    // 6
                            MEM_WR_REQ_CORE_1,    // 7
                            // CORE 2
                            LLC_RD_REQ_CORE_2,    // 8
                            MEM_RD_REQ_CORE_2,    // 9
                            LLC_WR_REQ_CORE_2,    // 10
                            MEM_WR_REQ_CORE_2,    // 11
                            // CORE 3
                            LLC_RD_REQ_CORE_3,    // 12
                            MEM_RD_REQ_CORE_3,    // 13
                            LLC_WR_REQ_CORE_3,    // 14
                            MEM_WR_REQ_CORE_3,    // 15
                            // EXTRA INFO
                            LLC_RD_RES_CORE_0,    // 16
                            LLC_WR_RES_CORE_0};   // 17

                             // CORE 0
    uint32_t event_info[] = {ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             ADD_RESP_LAT,
                             ADD_RESP_LAT,
                             // CORE 1
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             // CORE 2
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             //CORE 3
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             ADD_MEM_ONLY,
                             // EXTRA INFO
                             ADD_RESP_LAT,
                             ADD_RESP_LAT};

    write_32b_regs(EVENT_SEL_BASE_ADDR, num_counter, event_sel, COUNTER_BUNDLE_SIZE);
    write_32b_regs(EVENT_INFO_BASE_ADDR, num_counter, event_info, COUNTER_BUNDLE_SIZE);

    // error_count = run_pmu_core_test_suite (
    //                     ISPM_BASE_ADDR,
    //                     COUNTER_BASE_ADDR,
    //                     DSPM_BASE_ADDR,
    //                     PMC_STATUS_ADDR,
    //                     COUNTER_BUNDLE_SIZE,
    //                     32,
    //                     20,
    //                     2);
    uint32_t ARRAY_LEN = 80000;
    for (uint64_t repeat=0; repeat<100; repeat++) {
      for (uint64_t i=0; i < ARRAY_LEN; i++) {
        array[i] = (array[i] % ARRAY_LEN)*(array[i] % ARRAY_LEN) + repeat;
      }
    }

    // uint32_t print_info[] = {-1,0,-1,2};
    // test_cache2(4, print_info);

    // pmu_halt_core(
    //             ISPM_BASE_ADDR,
    //             PMC_STATUS_ADDR,
    //             1,
    //             2
    // );

    // while (!read_32b(DSPM_BASE_ADDR));

    // printf("Resume the core.");
    // pmu_resume_core(
    //             ISPM_BASE_ADDR,
    //             PMC_STATUS_ADDR,
    //             1,
    //             2
    // );

    // error_count = test_case_study_without_debug (
    //                  ISPM_BASE_ADDR,
    //                  DSPM_BASE_ADDR,
    //                  PMC_STATUS_ADDR, 
    //                  COUNTER_BASE_ADDR,
    //                  COUNTER_BUNDLE_SIZE,
    //                  4,
    //                  2);
    // while (1);
    printf("CVA6-0 Over, errors: %0d!\r\n", error_count);

    end_test(mhartid);
    uart_wait_tx_done();

  // *******************************************************************
  // Core 1-3
  // *******************************************************************
  } else if (mhartid <= NUM_NON_CUA) {
    // if (mhartid == 1) while(1){};
    // if (mhartid == 2) while(1){};
    // if (mhartid == 3) while(1){};

    while (1) {
      asm volatile ("interfering_cores:");
      uint64_t var;
      volatile uint64_t *array = (uint64_t*)(uint64_t)(0x83000000 + mhartid * 0x01000000);
      
      // 32'd1048576/2 = 0x0010_0000/2 elements.
      // Each array element is 64-bit, the array size is 0x0040_0000 = 4MB.
      // This will always exhaust the 2MB LLC.
      // Each core has 0x0100_0000 (16MB) memory.
      // It will iterate over 4MB array from top address to down
      for (int a_idx = START_NONCUA; a_idx < LEN_NONCUA; a_idx +=JUMP_NONCUA) {
        #ifdef INTF_RD
          asm volatile (
            "ld   %0, 0(%1)\n"  // read addr_var data into read_vart
            : "=r"(var)
            : "r"(array - a_idx)
          );
        #elif defined(INTF_WR)
          var = a_idx;
          asm volatile (
            "sd   %0, 0(%1)\n"  // read addr_var data into read_var
            :: "r"(var),
               "r"(array - a_idx)
          );
        #endif
      } 
    }
  } else {
    end_test(mhartid);
    uart_wait_tx_done();
    while (1);
  }
  
  return 0;
}