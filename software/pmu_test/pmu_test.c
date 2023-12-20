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
  

    uint32_t num_counter = 24;
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
                            LLC_WR_RES_CORE_0,    // 17
                            LLC_RD_RES_CORE_1,    // 18
                            LLC_WR_RES_CORE_1,    // 19  
                            LLC_RD_RES_CORE_2,    // 20 
                            LLC_WR_RES_CORE_2,    // 21  
                            LLC_RD_RES_CORE_3,    // 22  
                            LLC_WR_RES_CORE_3};   // 23

                             // CORE 0
    uint32_t event_info[] = {ADD_MEM_ONLY,    // 0
                             ADD_MEM_ONLY,    // 1
                             ADD_RESP_LAT,    // 2
                             ADD_RESP_LAT,    // 3
                             // CORE 1
                             ADD_MEM_ONLY,    // 4
                             ADD_MEM_ONLY,    // 5
                             ADD_MEM_ONLY,    // 6
                             ADD_MEM_ONLY,    // 7
                             // CORE 2
                             ADD_MEM_ONLY,    // 8
                             ADD_MEM_ONLY,    // 9
                             ADD_MEM_ONLY,    // 10
                             ADD_MEM_ONLY,    // 11
                             //CORE 3
                             ADD_MEM_ONLY,    // 12
                             ADD_MEM_ONLY,    // 13
                             ADD_MEM_ONLY,    // 14
                             ADD_MEM_ONLY,    // 15
                             // EXTRA INFO
                             ADD_RESP_LAT,    // 16
                             ADD_RESP_LAT,    // 17
                             ADD_RESP_LAT,    // 18
                             ADD_RESP_LAT,    // 19
                             ADD_RESP_LAT,    // 20
                             ADD_RESP_LAT,    // 21
                             ADD_RESP_LAT,    // 22
                             ADD_RESP_LAT};   // 23

    write_32b_regs(EVENT_SEL_BASE_ADDR, num_counter, event_sel, COUNTER_BUNDLE_SIZE);
    write_32b_regs(EVENT_INFO_BASE_ADDR, num_counter, event_info, COUNTER_BUNDLE_SIZE);

    uint32_t program[] = {
      0x33,         // 0: NOP
      0x400f93,     // 1: addi x31, x0, num_core
      0xf37,        // 2: lui x30, (dspm_base_addr >> 12)
      0xf0f13,      // 3: addi x30, x30, (dspm_base_addr & 0xFFF)
      0x28f0913,
      0xeb7,
      0x200e8e93,
      0x100093,
      0xf2e03,
      0x4f2d83,
      0x8f2b83,
      0xcf2c03,
      0x10f2c83,
      0x14f2d03,
      0x100093,
      0xa13,
      0x113,
      0x193,
      0x18207,
      0x118193,
      0x18287,
      0x520233,
      0x118193,
      0x18387,
      0x19007,
      0x118193,
      0x18407,
      0x19007,
      0x8383b3,
      0x18f2403,
      0x1cf2483,
      0x838433,
      0x747463,
      0x148493,
      0x8f2c23,
      0x9f2e23,
      0x24e0533,
      0x24e35b3,
      0x24d8833,
      0x24db8b3,
      0x95ea63,
      0x959463,
      0x856663,
      0x493,
      0x463,
      0x100493,
      0x110113,
      0x118193,
      0x18507,
      0x118193,
      0x18587,
      0x118193,
      0x18607,
      0x118193,
      0x18687,
      0x40b50533,
      0x40d60633,
      0x3750233,
      0x37532b3,
      0x3858333,
      0x385b3b3,
      0x7282b3,
      0x620233,
      0x627463,
      0x128293,
      0x458ee63,
      0x589463,
      0x4486a63,
      0x3960333,
      0x39633b3,
      0x7282b3,
      0x620233,
      0x627463,
      0x128293,
      0x258ec63,
      0x589463,
      0x2486863,
      0x3a68333,
      0x3a6b3b3,
      0x7282b3,
      0x620233,
      0x627463,
      0x128293,
      0x58ea63,
      0x589463,
      0x486663,
      0x293,
      0x463,
      0x100293,
      0x2099b3,
      0x13a7ab3,
      0x2adab3,
      0x12c313,
      0x6afb33,
      0x41b0863,
      0x1aca93,
      0x154fb33,
      0x5b7b33,
      0x1b0863,
      0xf3f116e3,
      0x21f2223,
      0xea0006e3,
      0x13a6a33,
      0x34f2023,
      0x10404237,
      0x22283,
      0x422303,
      0x1009213,
      0x220233,
      0x492023,
      0x592223,
      0x692423,
      0xc90913,
      0xfc0004e3,
      0xfff9c993,
      0x13a7a33,
      0x34f2023,
      0x10404237,
      0x22283,
      0x422303,
      0x1109213,
      0x220233,
      0x492023,
      0x592223,
      0x692423,
      0xc90913,
      0xf8000ae3};

    // 100%
    uint32_t dspm_val[] = {
      22,   // Average latency threshold
      0,    // Acceptable delay allowed per core
      11,   // Read-hit delay on CUA from the interfering cores
      78,   // Read-miss delay on CUA from the interfering cores.
      89,   // Write-hit delay on CUA from the interfering cores.
      390,  // Write-miss delay on CUA from the interfering cores.
      0,    // Initial CUA latency value, upper 32-bits.
      0     // Initial CUA latency value, lower 32-bits.
    };

    write_32b(PERIOD_ADDR,0xFFFFFFFF);
    write_32b(PERIOD_ADDR + 0x4,0xFFFFFFFF);

    printf("Test Parameters\r\n");
    printf("Average latency threshold: %0d\r\n", dspm_val[0]);
    printf("Acceptable delay allowed per request per core: %0d\r\n", dspm_val[1]);
    printf("Non-CUA parameters (rh,rm,wh,wm): %0d, %0d, %0d, %0d\r\n", dspm_val[2], dspm_val[3], dspm_val[4], dspm_val[5]);

    uint32_t instruction;
    uint32_t program_size = sizeof(program) / sizeof(program[0]);

    // encodeADDI (uint32_t rd, uint32_t rs1, uint32_t imm)
    instruction = encodeADDI(31, 0, 3 & 0xFFF, 0);
    program[1] = instruction;
    // encodeLUI (uint32_t rd, uint32_t imm)
    instruction = encodeLUI(30, DSPM_BASE_ADDR >> 12, 0);
    program[2] = instruction;
    // encodeADDI (uint32_t rd, uint32_t rs1, uint32_t imm)
    instruction = encodeADDI(30, 30, DSPM_BASE_ADDR & 0xFFF, 0);
    program[3] = instruction;

    printf("Setting up PMU core and SPMs.\r\n");
    write_32b(PMC_STATUS_ADDR, 1);
    error_count += test_spm(ISPM_BASE_ADDR, program_size, program);
    error_count += test_spm(DSPM_BASE_ADDR, 8, dspm_val);

    uint32_t test_cases[16] = {2040018, 8000026, 173649635, 172765718, 5359692, 5359692, 0, 0, 5359692, 5359692, 0, 0, 5359692, 5359692, 0, 0};
    printf("Writing counter values!\n");
    write_32b_regs(COUNTER_BASE_ADDR, 16, test_cases, COUNTER_BUNDLE_SIZE);

    printf("Start PMU core!\n");
    write_32b(PMC_STATUS_ADDR, 0);

    uint32_t ARRAY_LEN = 80000;
    // for (uint64_t repeat=0; repeat<100; repeat++) {
    //   for (uint64_t i=0; i < ARRAY_LEN; i++) {
    //     array[i] = (array[i] % ARRAY_LEN)*(array[i] % ARRAY_LEN) + repeat;
    //   }
    // }

    while (1) {
      uint read_target = read_32b(DSPM_BASE_ADDR + 0x24);
      if (read_target == 1)
        break;
    }

    for (uint32_t i=0; i<1000; i++) {
      uint32_t code       = read_32b(DSPM_BASE_ADDR + 0x28 + i*0xc);
      uint32_t time_lower = read_32b(DSPM_BASE_ADDR + 0x2c + i*0xc);
      uint32_t time_upper = read_32b(DSPM_BASE_ADDR + 0x30 + i*0xc);

      printf("Data %0d: %0d: %x_%x", i, code, time_upper, time_lower);

      if (code == 0) {
        break;
      }
    }

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