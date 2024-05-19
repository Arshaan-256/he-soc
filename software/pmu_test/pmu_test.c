#include "encoding.h"
#include <stdio.h>
#include <stdlib.h>
#include "utils.h"
#include "pmu_test_func.c"

// The CUA will always miss in the L1 but after one run of the loop, it will never miss in the LLC.
#define NUM_NON_CUA 3
// #define START_CORE

#ifndef TESTS_AUTO
  #define JUMP_CUA        8    // multiply by 8 for bytes
  #define JUMP_NONCUA     8    // multiply by 8 for bytes
  // #define LEN_NONCUA   32768
  // #define LEN_NONCUA   524288
  #define LEN_NONCUA   40960      // array size: 320 kB
  // #define LEN_NONCUA   262144  // array size: 2048 kB
  #define START_NONCUA    0
#endif

#define AVG_LAT     20
#define ARRAY_LEN   80000

// #define INTF_RD

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
    volatile uint64_t *tarray = (uint64_t*) 0x83000000;
    for (int a_idx = START_NONCUA; a_idx < LEN_NONCUA / 1024; a_idx +=JUMP_NONCUA) {
      printf(".");
      #ifdef INTF_RD
        asm volatile (
          "ld   %0, 0(%1)\n"
          : "=r"(var)
          : "r"(tarray - a_idx)
        );
      #elif defined(INTF_WR)
        var = a_idx;
        asm volatile (
          "sd   %0, 0(%1)\n"
          :: "r"(var),
              "r"(tarray - a_idx)
        );
      #endif
    }

    printf("\r\n");

    #ifdef INTF_RD
      printf("Read contention, non-CUA array size: %d, stride: %d.\r\n", LEN_NONCUA, JUMP_NONCUA);
    #endif

    #ifdef INTF_WR
      printf("Write contention, non-CUA array size: %d, stride: %d.\r\n", LEN_NONCUA, JUMP_NONCUA);
    #endif

    // **************************************************************
    // Set up PMU.
    // **************************************************************
    uint32_t num_counter = 8;
                            // CORE 0
    uint32_t event_sel[] = {LLC_RD_RES_CORE_0,    // 0
                            LLC_WR_RES_CORE_0,    // 1
                            MEM_RD_RES_CORE_0,    // 2
                            MEM_WR_RES_CORE_0,    // 3
                            LLC_RD_RES_CORE_0,    // 4
                            LLC_WR_RES_CORE_0,    // 5
                            MEM_RD_RES_CORE_0,    // 6
                            MEM_WR_RES_CORE_0,    // 7
                            LLC_RD_RES_CORE_0,    // 8
                            LLC_WR_RES_CORE_0     // 9

                            };

                             // CORE 0
    uint32_t event_info[] = {ADD_MEM_ONLY,    // 0 
                             ADD_MEM_ONLY,    // 1
                             ADD_MEM_ONLY,    // 2
                             ADD_MEM_ONLY,    // 3
                             ADD_RESP_LAT,    // 4
                             ADD_RESP_LAT,    // 5
                             ADD_RESP_LAT,    // 6
                             ADD_RESP_LAT,    // 7
                             ADD_RESP_LAT,    // 8
                             ADD_RESP_LAT     // 9
                            };

                             // CORE 0
    uint32_t print_info[] = {-1,-1,-1,-1,
                             -1,-1,-1,-1,
                             -1,-1
                            };

    write_32b_regs(EVENT_SEL_BASE_ADDR, num_counter, event_sel, COUNTER_BUNDLE_SIZE);
    write_32b_regs(EVENT_INFO_BASE_ADDR, num_counter, event_info, COUNTER_BUNDLE_SIZE);

    /// Don't need it for simulation!
    // Wipe out both SPMs.
    // for (uint32_t ispm_addr=ISPM_BASE_ADDR; ispm_addr<DSPM_BASE_ADDR; ispm_addr=ispm_addr+4) {
    //   write_32b(ispm_addr, 0x0);
    // }

    // for (uint32_t dspm_addr=DSPM_BASE_ADDR; dspm_addr<DSPM_END_ADDR; dspm_addr=dspm_addr+4) {
    //   write_32b(dspm_addr, 0x0);
    // }

    // **************************************************************
    // Set up PMU core.
    // **************************************************************
    uint32_t progrsam[] = {
    0x33,
    0x10427137,
    0x12423,
    0x12623,
    0x793,
    0x2f12823,
    0x813,
    0x3012a23,
    0x2f12c23,
    0x3012e23,
    0x12c23,
    0x12e23,
    0x2012023,
    0x10100793,
    0x2f12223,
    0x10427737,
    0x8072583,
    0x104277b7,
    0x10078793,
    0x2b12423,
    0x10427f37,
    0x10427eb7,
    0x10427e37,
    0x10427337,
    0x104278b7,
    0x10404437,
    0x1042f0b7,
    0x80000837,
    0x2f12623,
    0x400f93,
    0xfff80813,
    0x88f0f13,
    0x90e8e93,
    0x94e0e13,
    0x9830313,
    0x9c88893,
    0x10300393,
    0x100493,
    0x200913,
    0x300993,
    0x10100293,
    0x10404a37,
    0x440413,
    0xfe308093,
    0x2012023,
    0x2012783,
    0x78787,
    0xf12823,
    0x3f12023,
    0x2012783,
    0x78787,
    0xf12a23,
    0x2012783,
    0x1812703,
    0xe79007,
    0x1412783,
    0x3012b03,
    0x3412b83,
    0x107f7b3,
    0x1678ab3,
    0xfab533,
    0x3512823,
    0x17507b3,
    0x2f12a23,
    0x1012783,
    0x2812703,
    0x693,
    0x107f7b3,
    0x2e78633,
    0x2c12c23,
    0x2d12e23,
    0x1012783,
    0xff2023,
    0x3012703,
    0x3412783,
    0xeea023,
    0x3012703,
    0x3412783,
    0xfe2023,
    0x3812703,
    0x3c12783,
    0xe32023,
    0x3812703,
    0x3c12783,
    0xf8a023,
    0x3012703,
    0x3412783,
    0x3812503,
    0x3c12583,
    0xf5ea63,
    0xb79463,
    0xe56663,
    0x2412783,
    0x8778e63,
    0x3012703,
    0x3412783,
    0x3812503,
    0x3c12583,
    0xf5e663,
    0xf2b792e3,
    0xf2e570e3,
    0x2412783,
    0xf0579ce3,
    0x912e23,
    0x1c12783,
    0x20f02023,
    0x1212e23,
    0x1c12783,
    0x20f02023,
    0x1312e23,
    0x1c12783,
    0x20f02023,
    0x2712223,
    0xa2783,
    0xf12623,
    0x42783,
    0xf12423,
    0x2c12783,
    0xecf0ece3,
    0xc12703,
    0x2c12783,
    0xe7a023,
    0x812703,
    0x2c12783,
    0xe7a223,
    0x2412703,
    0x2c12783,
    0xe7a423,
    0x2c12783,
    0x1c78793,
    0x2f12623,
    0xea5ff06f,
    0x912e23,
    0x1c12783,
    0x20f02423,
    0x1212e23,
    0x1c12783,
    0x20f02423,
    0x1312e23,
    0x1c12783,
    0x20f02423,
    0x2512223,
    0xa2783,
    0xf12623,
    0x42783,
    0xf12423,
    0x2c12783,
    0xf2f0e6e3,
    0xc12703,
    0x2c12783,
    0xe7a023,
    0x812703,
    0x2c12783,
    0xe7a223,
    0x2412703,
    0x2c12783,
    0xe7a423,
    0x2c12783,
    0x1c78793,
    0x2f12623,
    0xef9ff06f};

    uint32_t program[] = {
      0x33,
      0x10427137,
      0x12623,
      0x12823,
      0x12a23,
      0x100813,
      0x400513,
      0x500593,
      0x12623,
      0xc12783,
      0x78787,
      0xf12823,
      0x1012623,
      0xc12783,
      0x78787,
      0xf12a23,
      0x1012703,
      0x1412783,
      0x693,
      0x2f70633,
      0xc12c23,
      0xd12e23,
      0xa12623,
      0xc12783,
      0x1012703,
      0xe79007,
      0xb12623,
      0xc12783,
      0x1412703,
      0xe79007,
      0xfa9ff06f
    };

    // Write it at `DSPM_BASE_ADDR + 0x80`.
    uint32_t dspm_val[] = {
      AVG_LAT                          // Average latency threshold
    };

    uint32_t instruction; 
    uint32_t program_size = sizeof(program) / sizeof(program[0]);
    uint32_t dspm_len = sizeof(dspm_val) / sizeof(dspm_val[0]);

    printf("Test Parameters\r\n");
    printf("Average latency threshold: %0d\r\n", dspm_val[0]);

    // Set up PMU core and SPMs.
    write_32b(PMC_STATUS_ADDR, 1);
    error_count += test_spm(ISPM_BASE_ADDR, program_size, program);
    error_count += test_spm(DSPM_BASE_ADDR+0x80, dspm_len, dspm_val);

    printf("SPMs loaded. (%0d)\r\n", error_count);

    // **************************************************************
    // Run Test
    // **************************************************************
    uint32_t counter_rst[num_counter];
    uint32_t counter_init[num_counter];
    uint32_t counter_final[num_counter];
    uint32_t counter_data[num_counter];
    uint64_t start_cycle, end_cycle, cycle_taken;
    uint64_t result;
    uint32_t pmu_timer_lower[2], pmu_timer_upper[2];
    uint64_t pmu_timer_start, pmu_timer_end, pmu_timer_delta;

    // Set up synthetic benchmark array.
    volatile uint64_t *array = (uint64_t*) 0x83000000;
    // for (uint32_t i=0; i < ARRAY_LEN; i++) {
    //   array[i] = my_rand(i*10);
    // }

    // Start PMU Timer by writing to PMU Period Register.
    write_32b(PERIOD_ADDR, 0xFFFFFFFF);
    write_32b(PERIOD_ADDR + 0x4, 0xFFFFFFFF);

    printf("Test started!\r\n");

    // Reset all counters.
    for (uint32_t i=0; i<num_counter; i++) {
      counter_rst[i] = 0;
    }
    write_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_rst, COUNTER_BUNDLE_SIZE);
    // Read PMU counters.
    read_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_init, COUNTER_BUNDLE_SIZE);
    // Start PMU core.
    #ifdef START_CORE
      write_32b(PMC_STATUS_ADDR, 0);
    #endif
    // Read cycle CSR.
    start_cycle = read_csr(cycle);
    // Read PMU Timer.
    pmu_timer_lower[0] = read_32b(TIMER_ADDR);
    pmu_timer_upper[0] = read_32b(TIMER_ADDR+0x4);

    /// *****************
    /// This is the test.
    /// *****************
    for (uint64_t repeat=0; repeat<100; repeat++) {
      for (uint64_t i=0; i < ARRAY_LEN; i++) {
        array[i] = (array[i] % ARRAY_LEN)*(array[i] % ARRAY_LEN) + repeat;
      }
    }

    /// *****************************
    /// Collect post-test statistics.
    /// *****************************
    // Read cycle CSR.
    end_cycle   = read_csr(cycle);
    cycle_taken = (end_cycle - start_cycle);
    // Stop PMU core.
    #ifdef START_CORE
      write_32b(PMC_STATUS_ADDR, 1);
    #endif
    // Read PMU counters.
    read_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_final, COUNTER_BUNDLE_SIZE);
    // Read PMU Timer.
    pmu_timer_lower[1] = read_32b(TIMER_ADDR);
    pmu_timer_upper[1] = read_32b(TIMER_ADDR+0x4);

    // Calculate PMU Timer Delta.
    pmu_timer_start = (pmu_timer_upper[0] << 32) + pmu_timer_lower[0];
    pmu_timer_end   = (pmu_timer_upper[1] << 32) + pmu_timer_lower[1];
    pmu_timer_delta = pmu_timer_end - pmu_timer_start;
    
    // **************************************************************
    // Print Results.
    // **************************************************************
    // Print execution time.
    printf("Test over! Time taken: %x_%x\r\n", (cycle_taken >> 32), (cycle_taken & 0xFFFFFFFF));

    printf("PMU Timer(%x_%x to %x_%x): %x_%x\r\n",
                  (pmu_timer_start >> 32), (pmu_timer_start & 0xFFFFFFFF),
                  (pmu_timer_end >> 32),   (pmu_timer_end & 0xFFFFFFFF),
                  (pmu_timer_delta >> 32), (pmu_timer_delta & 0xFFFFFFFF));

    // Print counter data.
    for (uint32_t i=0; i<num_counter; i++) {
      counter_data[i] = (counter_final[i] & 0x7FFFFFFF)-(counter_init[i] & 0x7FFFFFFF);
    }
    for (uint32_t i=0; i<num_counter; i++) {
        if (print_info[i] == -1) {
            printf("%d:%d", i, counter_data[i]);
            uart_wait_tx_done();
        } else {
            if (counter_data[i] != 0) {
                printf("%d:%u", i, counter_data[i] / counter_data[print_info[i]]);
                uart_wait_tx_done();
            } else {
                printf("%d:%u", i, counter_data[i]);
                uart_wait_tx_done();
            }
        }
        printf("(%d,%d)",counter_init[i]&0x7FFFFFFF, counter_final[i]&0x7FFFFFFF);
        uart_wait_tx_done();
        if (i != num_counter-1) printf(",");
        else                    printf(".\r\n");
    }

    printf("CVA6-0 Over! %d\r\n", error_count);
    uart_wait_tx_done();

    end_test(mhartid);
    uart_wait_tx_done();

    while (1);
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