#include "pmu_test_func.h"

uint32_t my_rand(uint32_t seed) {
  uint32_t a = 1103515245;
  uint32_t c = 12345;
  uint32_t m = 2<<29;

  seed = (a * seed + c) % m;
  return seed;
}

uint32_t array_traversal(uint32_t len) {
  uint32_t comp_array[len];
  for(uint32_t i=0; i<len; i++) {
    if (i==0) {
      comp_array[i] = 1;  
    } else {
      comp_array[i] = comp_array[i-1] + i*i;
    }
  }

  return comp_array[len-1];
}

void write_counter_b(counter_b_t counter_b, uint64_t base_addr) {  
  write_32b(base_addr, counter_b.counter);
  base_addr = base_addr + 0x4;
  write_32b(base_addr, counter_b.event_sel);
  base_addr = base_addr + 0x4;
  write_32b(base_addr, counter_b.event_info);
  base_addr = base_addr + 0x4;
  write_32b(base_addr, counter_b.init_budget);
}

void read_32b_regs(uint64_t base_addr, uint32_t len, uint32_t* rval, uint32_t step_size) {
  for (int i=0; i<len; i++) {
    rval[i] = read_32b(base_addr);
    base_addr = base_addr + step_size;
  }
}

void write_32b_regs(uint64_t base_addr, uint32_t len, uint32_t val[], uint32_t step_size) {
  for (int i=0; i<len; i++) {
    write_32b(base_addr, val[i]);
    base_addr = base_addr + step_size;
  }
}

void read_64b_regs(uint64_t base_addr, uint32_t len, uint64_t* rval, uint32_t step_size) {
  uint32_t val_l, val_h;

  for (uint32_t i=0; i<len; i++) {
    val_l = read_32b(base_addr);
    val_h = read_32b(base_addr+4);
    rval[i] = (val_h << 32) | val_l; 
    base_addr += step_size;
  }
}

void write_64b_regs(uint64_t base_addr, uint32_t len, uint64_t val[], uint32_t step_size) {
  uint32_t val_l, val_h;

  for (uint32_t i=0; i<len; i++) {
    val_l = val[i] & 0xFFFFFFFF;
    val_h = val[i] >> 32;
    write_32b(base_addr, val_l);
    write_32b(base_addr+4, val_h);
    base_addr += step_size;
  }
}

uint32_t test_spm(uint64_t base_addr, uint32_t num_rw, uint32_t val[]) {
  uint32_t error_count = 0;
  uint32_t rval[num_rw];   // used to read from the SPM

  write_32b_regs(base_addr, num_rw, val, 0x4);
  read_32b_regs(base_addr, num_rw, rval, 0x4);

  for (uint32_t i=0; i<num_rw; i++) {
    if (val[i] != rval[i]) {
      error_count += 1;
    }
  }

  return error_count;
}

uint32_t test_spm_rand(uint64_t base_addr, uint32_t num_rw) {
  uint32_t seed;
  uint32_t rand_val[num_rw];    // used to write to the SPM, is populated with random numbers
  
  for(uint32_t i=0; i<num_rw; i++) {
    seed = (uint32_t)(base_addr * i + num_rw);
    rand_val[i] = (uint32_t)(my_rand(seed));
  }

  return test_spm(base_addr, num_rw, rand_val);
}