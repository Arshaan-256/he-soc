#include "pmu_test_func.c"
#include "encoding.h"

// #define RD_ON_RD
#define WR_ON_WR
// #define RD_ONLY
// #define WR_ONLY

#ifdef RD_ON_RD
  #define CUA_RD 
  #define INTF_RD
#elif defined(WR_ON_WR)
  #define CUA_WR
  #define INTF_WR 
#elif defined(RD_ONLY)
  #define CUA_RD
#elif defined(WR_ONLY)
  #define CUA_WR
#endif

void test_cache ();
inline void my_sleep();

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
  uint32_t test_freq = 50000000;
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

  uint32_t dspm_base_addr;
  uint32_t read_target;
  uint32_t error_count = 0;

  // uint32_t counter_val[]          = {0x1, 0x2, 0x3, 0x4};
  uint32_t event_sel_val[]  = {0x00001F, 0x00002F, 0x00003F, 0x00004F, 0x2F001F, 0x2F002F, 0x2F003F, 0x2F004F};
  // uint32_t event_info_val[]       = {0x10, 0x20, 0x30, 0x40};
  // uint32_t init_budget_val[]      = {0x100, 0x200, 0x300, 0x400};

  counter_b_t counter_b[NUM_COUNTER];

  //                                                                                                                                                                                              

  // *******************************************************************
  // Core 0
  // *******************************************************************
  if (mhartid == 0) {   
    write_32b_regs(EVENT_SEL_BASE_ADDR, NUM_COUNTER, event_sel_val, COUNTER_BUNDLE_SIZE);
    test_cache ();
  // *******************************************************************
  // Core 1-3
  // *******************************************************************
  } else {
    while (1) {
      // asm volatile ("fence");
      uint64_t readvar2;
      volatile uint64_t *array2 = (uint64_t*)(0x81000000 + mhartid * 0x01000000);
      
      // 32'd1048576 = 0x0010_0000.
      // Each array element is 64-bit, the array size is 0x0080_0000 = 8MB.
      // This will always exhaust the 2MB LLC.
      // Each core has 0x0100_0000 (16MB) memory.
      // This still 8MB for the program which is way more than needed.
      for (int a_idx = 0; a_idx < 1048576; a_idx +=2) {
        #ifdef INTF_RD
          asm volatile (
            "ld   %0, 0(%1)\n"  // read addr_var data into read_var
            : "=r"(readvar2)
            : "r"(array2 - a_idx)
          );
        #elif defined(INTF_WR)
          asm volatile (
            "sd   %0, 0(%1)\n"  // read addr_var data into read_var
            : "=r"(readvar2)
            : "r"(array2 - a_idx)
          );
        #endif
      } 
    }
  }

  printf("Exiting, my HartID: %0d.\n", mhartid);
  uart_wait_tx_done();
  return 0;
}

void test_cache() {
  // For testing write, we need to be careful so as to not overwrite the program.
  // This is why the EVAL_LEN is restricted to 37 (4MB).
  #ifdef CUA_RD
    #define EVAL_LEN 38
  #elif defined (CUA_WR)
    #define EVAL_LEN 37
  #endif
  int eval_array[38] = {16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 5120, 6144, 7168, 8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384, 20480, 24576, 28672, 32768, 36864, 40960, 45056, 49152, 53248, 57344, 61440, 65536, 131072, 262144, 524288, 1048576, 2097152};
  uint32_t counter_rval[NUM_COUNTER];
  volatile uint64_t *array = (uint64_t*) 0x81000000;

  for(uint32_t a_len = 1; a_len < EVAL_LEN; a_len++) { 
    uint64_t readvar1, readvar2, readvar3, readvar4;
 
    uint64_t curr_cycle;
    uint64_t end_cycle;
    uint64_t curr_miss;
    uint64_t end_miss;
    uint64_t a_len2;
    a_len2 = eval_array[a_len];

    for (int a_idx = 0; a_idx < a_len2; a_idx+=2) {
      #ifdef CUA_RD
        asm volatile ( 
          "ld   %0, 0(%1)\n"  // read addr_var data into read_var
          : "=r"(readvar1)
          : "r"(array - a_idx)
        );
      #elif defined(CUA_WR)
        asm volatile ( 
          "sd   %0, 0(%1)\n"  // read addr_var data into read_var
          : "=r"(readvar1)
          : "r"(array - a_idx)
        );
      #endif
    }

    asm volatile("csrr %0, 0xb04" : "=r" (curr_miss) : );
    curr_cycle = read_csr(cycle);

    for (int a_repeat = 0; a_repeat < 100; a_repeat++){
      for (int a_idx = 0; a_idx < a_len2; a_idx+=2) {
        #ifdef CUA_RD
          asm volatile ( 
            "ld   %0, 0(%1)\n"  // read addr_var data into read_var
            : "=r"(readvar1)
            : "r"(array - a_idx)
          );
        #elif defined(CUA_WR)
          asm volatile ( 
            "sd   %0, 0(%1)\n"  // read addr_var data into read_var
            : "=r"(readvar1)
            : "r"(array - a_idx)
          );
        #endif
      }
    }

    end_cycle = read_csr(cycle) - curr_cycle;
    asm volatile("csrr %0, 0xb04" : "=r" (end_miss) : );    
    volatile uint32_t sleep = 10000;

    // Size in Bytes.
    asm volatile ("fence");
    printf("%d,", (a_len2*8));
    uart_wait_tx_done();
    my_sleep();

    // Load-store cycle count.
    asm volatile ("fence");
    // This line assumes that the repeat only has 4 instructions including the LD/ST.
    // This is compiler-dependent but I verified it when I wrote it.
    volatile uint64_t ld_sd_cc = (end_cycle)/(100*a_len2/2)-3;
    printf("%d,", ld_sd_cc);
    uart_wait_tx_done();
    my_sleep();

    // L1-D cache misses.
    asm volatile ("fence");
    volatile uint64_t l1d_miss = end_miss - curr_miss;
    printf("%d\n", l1d_miss);
    uart_wait_tx_done();
    my_sleep();
  }
}

// Sometimes the UART skips over output.
// Gives the UART more time to finish output before filling up the UART Tx FIFO with more data.
inline void my_sleep() {
  uint32_t sleep = 5000;
  for (volatile uint32_t i=0; i<sleep; i++) {
    asm volatile ("fence");
    asm volatile ("addi x1, x1, 1");
    asm volatile ("fence");
  }  
}
