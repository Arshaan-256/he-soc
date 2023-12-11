void mem_sweep_all_sizes (uint32_t num_counter, uint32_t *print_info, ) {
  // For testing write, we need to be careful so as to not overwrite the program.
  // This is why the EVAL_LEN is restricted to 37 (4MB).
  uint32_t EVAL_LEN = 37;

  int eval_array[] = {16,
                      32,
                      64,
                      128,
                      256,
                      512,
                      1024,
                      2048,
                      4096,
                      5120,
                      6144,
                      7168,
                      8192,
                      9216,
                      10240,
                      11264,
                      12288,
                      13312,
                      14336,
                      15360,
                      16384,
                      20480,
                      24576,
                      28672,
                      32768,
                      36864,
                      40960,
                      45056,
                      49152,
                      53248,
                      57344,
                      61440,
                      65536,
                      131072,
                      262144,
                      524288,
                      1048576};

  // uint32_t counter_rval[NUM_COUNTER];
  volatile uint64_t *array = (uint64_t*) 0x83000000;

    for (uint32_t a_len = 1; a_len < EVAL_LEN; a_len++) { 
        uint64_t var;
        uint64_t curr_cycle;
        uint64_t end_cycle;
        uint64_t curr_miss;
        uint64_t end_miss;
        uint64_t a_len2;
        uint32_t counter_rst[num_counter];
        uint32_t counter_init[num_counter];
        uint32_t counter_final[num_counter];

        a_len2 = eval_array[a_len];
        for (uint32_t i=0; i<num_counter; i++)
        counter_rst[i] = 0;

        uint32_t N_REPEAT = 100;

        for (int a_idx = 0; a_idx < a_len2; a_idx+=JUMP_CUA) {
            #ifdef CUA_RD
                asm volatile (
                "ld   %0, 0(%1)\n"
                : "=r"(var)
                : "r"(array - a_idx)
                );
            #elif defined(CUA_WR)
                asm volatile (
                "sd   %0, 0(%1)\n"
                :: "r"(var),
                    "r"(array - a_idx)
                );
            #endif
        }

        // Reset all counters.
        write_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_rst, COUNTER_BUNDLE_SIZE);

        asm volatile("csrr %0, 0xb04" : "=r" (curr_miss) : );
        read_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_init, COUNTER_BUNDLE_SIZE);
        curr_cycle = read_csr(cycle);
        
        for (int a_repeat = 0; a_repeat < N_REPEAT; a_repeat++){
            for (int a_idx = 0; a_idx < a_len2; a_idx+=JUMP_CUA) {
                #ifdef CUA_RD
                asm volatile ( 
                    "ld   %0, 0(%1)\n"
                    : "=r"(var)
                    : "r"(array - a_idx)
                );
                #elif defined(CUA_WR)
                var = a_idx;
                asm volatile ( 
                    "sd   %0, 0(%1)\n"
                    :: "r"(var),
                    "r"(array - a_idx)
                );
                #endif
            }
        }

        end_cycle = read_csr(cycle) - curr_cycle;
        read_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_final, COUNTER_BUNDLE_SIZE);
        asm volatile("csrr %0, 0xb04" : "=r" (end_miss) : );

        // Size in Bytes.
        printf("Size:%d,", (a_len2*8)/1024);

        // Load-store cycle count.
        uint32_t num_ls_made = N_REPEAT*(a_len2/JUMP_CUA);
        volatile uint64_t ld_sd_cc = (end_cycle/num_ls_made);
        printf("LS-CC (%d):%d,", num_ls_made, ld_sd_cc);

        // L1 D-cache misses.
        printf("D1-miss:%d,", end_miss-curr_miss);

        uint32_t counter_data[31];
        for (uint32_t i=0; i<num_counter; i++) {
        counter_data[i] = (counter_final[i] & 0x7FFFFFFF)-(counter_init[i] & 0x7FFFFFFF); 
        }

        for (uint32_t i=0; i<num_counter; i++) {
            if (print_info[i] == -1) {
                printf("%d:%d", i, counter_data[i]);
            } else {
                if (counter_data[i] != 0) {
                    printf("%d:%d", i, counter_data[i] / counter_data[print_info[i]]);
                } else {
                    printf("%d:%d", i, counter_data[i]);
                }
            }
            printf("(%d,%d)",counter_init[i]&0x7FFFFFFF, counter_final[i]&0x7FFFFFFF);
            if (i != num_counter-1) printf(",");
            else                    printf(".");
        }

        printf("\r\n");
    }
}

void mem_sweep_two_cases (uint32_t num_counter, uint32_t *print_info) {
    // LLC hit:  40 KB
    // LLC miss: 2048 KB
    int eval_array[] = {40960, 262144};

    volatile uint64_t *array = (uint64_t*) 0x83000000;

    for (uint32_t a_len = 0; a_len < EVAL_LEN; a_len++) { 
        uint64_t var;
        uint64_t curr_cycle;
        uint64_t end_cycle;
        uint64_t curr_miss;
        uint64_t end_miss;
        uint64_t a_len2;
        uint32_t counter_rst[num_counter];
        uint32_t counter_init[num_counter];
        uint32_t counter_final[num_counter];

        a_len2 = eval_array[a_len];
        for (uint32_t i=0; i<num_counter; i++)
            counter_rst[i] = 0;

        uint32_t N_REPEAT = 100;

        // Prime the cache.
        for (int a_idx = 0; a_idx < a_len2; a_idx+=JUMP_CUA) {
            #ifdef CUA_RD
            asm volatile (
                "ld   %0, 0(%1)\n"
                : "=r"(var)
                : "r"(array - a_idx)
            );
            #elif defined(CUA_WR)
            asm volatile (
                "sd   %0, 0(%1)\n"
                :: "r"(var),
                    "r"(array - a_idx)
            );
            #endif
        }

        // Reset all counters.
        write_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_rst, COUNTER_BUNDLE_SIZE);

        asm volatile("csrr %0, 0xb04" : "=r" (curr_miss) : );
        read_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_init, COUNTER_BUNDLE_SIZE);
        curr_cycle = read_csr(cycle);

        for (int a_repeat = 0; a_repeat < N_REPEAT; a_repeat++){
            for (int a_idx = 0; a_idx < a_len2; a_idx+=JUMP_CUA) {
            #ifdef CUA_RD
                asm volatile ( 
                "ld   %0, 0(%1)\n"
                : "=r"(var)
                : "r"(array - a_idx)
                );
            #elif defined(CUA_WR)
                var = a_idx;
                asm volatile ( 
                "sd   %0, 0(%1)\n"
                :: "r"(var),
                    "r"(array - a_idx)
                );
            #endif
            }
        }

        end_cycle = read_csr(cycle) - curr_cycle;
        read_32b_regs(COUNTER_BASE_ADDR, num_counter, counter_final, COUNTER_BUNDLE_SIZE);
        asm volatile("csrr %0, 0xb04" : "=r" (end_miss) : );

        // Size in Bytes.
        printf("Size:%d,", (a_len2*8)/1024);

        // Load-store cycle count.
        uint32_t num_ls_made = N_REPEAT*(a_len2/JUMP_CUA);
        volatile uint64_t ld_sd_cc = (end_cycle/num_ls_made);
        printf("LS-CC (%d):%d,", num_ls_made, ld_sd_cc);

        // L1 D-cache misses.
        printf("D1-miss:%d,", end_miss-curr_miss);

        uint32_t counter_data[31];
        for (uint32_t i=0; i<num_counter; i++) {
            counter_data[i] = (counter_final[i]&0x7FFFFFFF)-(counter_init[i]&0x7FFFFFFF); 
        }

        for (uint32_t i=0; i<num_counter; i++) {
            if (print_info[i] == -1) {
                printf("%d:%d", i, counter_data[i]);
            } else {
                if (counter_data[i] != 0) {
                    printf("%d:%d", i, counter_data[i] / counter_data[print_info[i]]);
                } else {
                    printf("%d:%d", i, counter_data[i]);
                }
            }
            printf("(%d,%d)",counter_init[i]&0x7FFFFFFF, counter_final[i]&0x7FFFFFFF);
            if (i != num_counter-1) printf(",");
            else                    printf(".");
        }

        printf("\r\n");
    }
}