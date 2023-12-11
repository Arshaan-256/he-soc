// The following two functions sweep the LLC acccessing array of growing sizes.
// These functions can be run with / without contention from other cores.
// The code makes a few assumptions: 
//              a) The system has 4 cores.
//              b) The total LLC size is 2 MB, 
//              c) The LLC is partitioned between all cores equally, each partition is 512 KB.

// The `print_info` is used to divide value of counters before printing them.
// If print_info[0] = -1, it indicates that this counter[0] does not need to be divided before printing the value of counter[0].
// If print_info[3] = 7, it indicates that divide `counter[3] / counter[7]` before printing the value of counter[3].
void mem_sweep_all_sizes (uint32_t num_counter, uint32_t *print_info);
void mem_sweep_two_cases (uint32_t num_counter, uint32_t *print_info);