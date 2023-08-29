#include <stdio.h>
#include <stdlib.h>
#include "utils.h"

// *********************************************************************
// Macros and Defines
// *********************************************************************
#define TEST_0
#define TEST_1

// All Widths are in Bytes
#define NUM_COUNTER 4

#define INSTR_WIDTH 4
#define DATA_WIDTH 4

#define NUM_INSTR 100
#define NUM_DATA 100

// For the array traversal
#define NUM_ELEMENT 100

// Counter Bundle
typedef struct {
  uint32_t  counter;
  uint32_t  event_sel;
  uint32_t  event_info;
  uint32_t  init_budget;
} counter_b_t;

// PMU Bundle
typedef struct {
  uint64_t  timer;
  uint64_t  period;
} pmu_b_t;

// *********************************************************************
// Function Prototypes
// *********************************************************************
// The AXI4-Lite interconnect is 32bit.
// Can only read-write to 32bits at a time.
#define read_32b(addr)         (*(volatile uint32_t *)(long)(addr))
#define write_32b(addr, val_)  (*(volatile uint32_t *)(long)(addr) = val_)

// A simple LCG (Linear Congruential Generator) algorithm to generate pseudo-random numbers for testing.
uint32_t my_rand(uint32_t seed);

// Read-Write functions to read from / write to `len` number of 32-bit registers.
// The address of the first register is `base_addr` and each consequent register is `+ step_size` away from the previous one.
void read_32b_regs(uint64_t base_addr, uint32_t len, uint32_t* rval, uint32_t step_size);
void write_32b_regs(uint64_t base_addr, uint32_t len, uint32_t val[], uint32_t step_size);


// Read-Write functions to write to `num_regs` number of 64-bit registers.
// The address of the first register is `base_addr` and each consequent register is `+ step_size` away from the previous one.
void read_64b_regs(uint64_t base_addr, uint32_t len, uint64_t* rval, uint32_t step_size);
void write_64b_regs(uint64_t base_addr, uint32_t len, uint64_t val[], uint32_t step_size);

// Function reads a struct of type `counter_b_t` from `base_addr` and returns it.
counter_b_t read_counter_b(uint64_t base_addr);
// Function writes a a struct of type `counter_b_t` to `base_addr`.
void write_counter_b(counter_b_t counter_b, uint64_t base_addr);

uint32_t array_traversal(uint32_t len);

// Function to test read and writes to Data SPM.
// This test will make `num_rw` number of writes, from array `val[]`,  and then reads to the DSPM, starting from addreses `base_addr`.
// For each mismatch it increments the error counter and then returns it.
// A return of 0 indicates that the test successfully passed.
uint32_t test_spm(uint64_t base_addr, uint32_t num_rw, uint32_t val[]);
// This function generates a random array of size `num_rw` (using `my_rand()`) and then calls `test_spm`. 
uint32_t test_spm_rand(uint64_t base_addr, uint32_t num_rw);