//#include "util.h"
#include <stdio.h>
#include <stdlib.h>
#include "encoding.h"
#include "utils.h"
//#define FPGA_EMULATION

int main(int argc, char const *argv[]) {

  uint64_t mhartid;

  #ifdef FPGA_EMULATION
  int baud_rate = 9600;
  int test_freq = 10000000;
  #else
  set_flls();
  int baud_rate = 115200;
  int test_freq = 100000000;
  #endif  
  uart_set_cfg(0,(test_freq/baud_rate)>>4);
  
  asm volatile (
    "csrr %0, mhartid\n"
    : "=r" (mhartid)
  );

  if (mhartid == 0) {
    printf("Hello CVA6-0!\n");
    uart_wait_tx_done();
  } else if (mhartid == 1) {
    printf("Hello CVA6-1!\n");
    uart_wait_tx_done();
  } else if (mhartid == 2) {
    printf("Hello CVA6-2!\n");
    uart_wait_tx_done();
  } else if (mhartid == 3) {
    printf("Hello CVA6-3!\n");
    uart_wait_tx_done();
  }
  return 0;
}
 


