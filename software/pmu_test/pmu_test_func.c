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

counter_b_t read_counter_b(uint64_t base_addr) {
  counter_b_t counter_b;
  counter_b.counter     = read_32b(base_addr);
  base_addr = base_addr + 0x4;
  counter_b.event_sel   = read_32b(base_addr);
  base_addr = base_addr + 0x4;
  counter_b.event_info  = read_32b(base_addr);
  base_addr = base_addr + 0x4;
  counter_b.init_budget = read_32b(base_addr);
  return counter_b;  
}

void write_counter_b(uint64_t base_addr, counter_b_t counter_b) {  
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

uint32_t test_counter_bundle(uint64_t base_addr, uint32_t num_rw, uint32_t bundle_size, counter_b_t val[]) {
  uint64_t saved_base_addr;
  uint32_t error_count = 0;
  counter_b_t rval[num_rw];    // used to read from the SPM

  saved_base_addr = base_addr;
  for (uint32_t i=0; i<num_rw; i++) {
    write_counter_b(base_addr, val[i]);
    base_addr = base_addr + bundle_size;
  }
  
  base_addr = saved_base_addr;
  for (uint32_t i=0; i<num_rw; i++) {
    rval[i] = read_counter_b(base_addr);
    base_addr = base_addr + bundle_size;
  }

  for (uint32_t i=0; i<num_rw; i++) {
    if (val[i].counter != rval[i].counter) {
      error_count += 1;
    }
    if (val[i].event_sel != rval[i].event_sel) {
      error_count += 1;
    }
    if (val[i].event_info != rval[i].event_info) {
      error_count += 1;
    }
    if (val[i].init_budget != rval[i].init_budget) {
      error_count += 1;
    }
  }
  return error_count;
}

uint32_t test_counter_bundle_rand(uint64_t base_addr, uint32_t num_rw, uint32_t bundle_size) {
  uint32_t seed;
  counter_b_t rand_val[num_rw];    // used to write to the SPM, is populated with random numbers
  
  for(uint32_t i=0; i<num_rw; i++) {
    seed = (uint32_t)(base_addr * i + num_rw);
    rand_val[i].counter     = (uint32_t)(my_rand(seed+0));
    rand_val[i].event_sel   = (uint32_t)(my_rand(seed+1));
    rand_val[i].event_info  = (uint32_t)(my_rand(seed+2));
    rand_val[i].init_budget = (uint32_t)(my_rand(seed+3));
  }

  test_counter_bundle(base_addr, num_rw, bundle_size, rand_val);
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