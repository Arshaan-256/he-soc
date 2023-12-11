#include "encoding.h"
#include <stdio.h>
#include <stdlib.h>
#include "utils.h"
#include "pmu_defines.h"
#include "pmu_test_func.c"
#include "pmu_mem_sweep_func.c"

/// The CUA will always miss in the L1 but after one run of the loop, it will never miss in the LLC.

/// This define controls the number of non-CUA cores that are causing RD / WR contention.
#define NUM_NON_CUA 3

/// This define specifies the contention type.
// #define RD_ONLY
// #define WR_ONLY
// #define RD_WITH_RD
// #define WR_WITH_WR
// #define RD_WITH_WR
// #define WR_WITH_RD

// Array size: 320 kB   (LLC Hits)
#define LEN_NONCUA   40960    
// Array size: 2048 kB  (LLC Misses)
#define LEN_NONCUA   262144

/// Core jumps over 8 64-bit elements every iteration.
/// It skips 64B (or one cacheline) per iteration. 
/// Always causing an L1 miss.
#define JUMP_CUA     8    
#define JUMP_NONCUA  8  
// Starting index for non-CUA.
#define START_NONCUA 0


// Do not concern yourself with the working of these defines.
// Mortals such as yourself are not worthy of 
#ifdef RD_ONLY
  #define CUA_RD
#elif defined(WR_ONLY)
  #define CUA_WR  
#elif defined(RD_WITH_RD)
  #define CUA_RD 
  #define INTF_RD
#elif defined(WR_WITH_WR)
  #define CUA_WR
  #define INTF_WR 
#elif defined(RD_WITHLY)
  #define CUA_RD
#elif defined(WR_WITHLY)
  #define CUA_WR
#elif defined(RD_WITH_WR)
  #define CUA_RD
  #define INTF_WR 
#elif defined(WR_WITH_RD)
  #define CUA_WR
  #define INTF_RD 
#endif

void end_test(uint32_t mhartid){
  printf("Exiting: %0d.\r\n", mhartid);
}

#define write_32b(addr, val_)  (*(volatile uint32_t *)(long)(addr) = val_)

// *********************************************************************
// Main Function
// *********************************************************************
int main(int argc, char const *argv[]) {
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
    
    #if defined(CUA_RD)
    // This is for when cua is making reads
    uint32_t event_sel[]  = {LLC_RD_REQ_CORE_0,   // llc read request by core 0
                             LLC_RD_RES_CORE_0,   // llc read response by core 0
                             MEM_RD_REQ_CORE_0,   // mem read request by core 0
                             MEM_RD_RES_CORE_0};  // mem read response by core 0
    
    #elif defined(CUA_WR)
    // This is for when cua is making writes
    uint32_t event_sel[]  = {LLC_WR_REQ_CORE_0,   // llc read request by core 0
                             LLC_WR_RES_CORE_0,   // llc read response by core 0
                             MEM_WR_REQ_CORE_0,   // mem read request by core 0
                             MEM_WR_RES_CORE_0};  // mem read response by core 0
    #else
    uint32_t event_sel[]  = {0x000000,
                             0x000000,
                             0x000000,
                             0x000000};
    #endif

    // this doesn't change
    uint32_t event_info[] = {0x000000,
                             ADD_RESP_LAT,
                             0x000000,
                             ADD_RESP_LAT};

    write_32b_regs(EVENT_SEL_BASE_ADDR, 4, event_sel, COUNTER_BUNDLE_SIZE);
    write_32b_regs(EVENT_INFO_BASE_ADDR, 4, event_info, COUNTER_BUNDLE_SIZE);
    uint32_t print_info[] = {-1,0,-1,2};
    mem_sweep_two_cases(4, print_info, JUMP_CUA);

    printf("CVA6-0 Over, errors: %0d!\r\n", error_count);

    end_test(mhartid);
    uart_wait_tx_done();

  // *******************************************************************
  // Core 1-3
  // *******************************************************************
  } else if (mhartid <= NUM_NON_CUA) {
    while (1) {
      asm volatile ("interfering_cores:");
      uint64_t var;
      volatile uint64_t *array = (uint64_t*)(uint64_t)(0x83000000 + mhartid * 0x01000000);
      
      // 32'd1048576/2 = 0x0010_0000/2 elements.
      // Each array element is 64-bit, the array size is 0x0040_0000 = 4MB.
      // This will always exhaust the 2MB LLC.
      // Each core has 0x0100_0000 (16MB) memory.
      // It will iterate over 4MB array from top address to down.
      for (int a_idx = START_NONCUA; a_idx < LEN_NONCUA; a_idx +=JUMP_NONCUA) {
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
    }
  } else {
    end_test(mhartid);
    uart_wait_tx_done();
    while (1);
  }
  
  return 0;
}