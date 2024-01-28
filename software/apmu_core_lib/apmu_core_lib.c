#include "apmu_defines.h"
#include "apmu_core_lib.h"

#define DEBUG_HALT      0x200
#define DEBUG_RESUME    0x208

// C0: Reads to LLC by CUA.
// C1: Writes to LLC by CUA.
// C2: Reads to memory by CUA.
// C3: Writes to memory by CUA.
// C4: Read request latency.
// C5: Write request latency.

void main () {

    // If halted then 1, else 0.
    int halt_status;
    int p_read_hit  = 1; 
    int p_write_hit = 3;
    int p_read_miss = 6; 
    int p_writeback = 9;
    int read_lat, write_lat, cur_lat, target_lat;
    int k_read, k_write, k_read_miss, k_writeback, k_read_hit, k_write_hit;
    int counter_idx = 0;
    int core_idx;

    while (1) {
        // Read all counters.
        // C0
        counter_read(k_read, counter_idx);
        counter_idx += 1;
        // C1
        counter_read(k_write, counter_idx);
        counter_idx += 1;
        // C2
        counter_read(k_read_miss, counter_idx);
        counter_idx += 1;
        // C3
        counter_read(k_writeback, counter_idx);
        counter_idx += 1;
        // C4
        counter_read(read_lat, counter_idx);
        counter_idx += 1;
        // C5
        counter_read(write_lat, counter_idx);

        cur_lat     = read_lat + write_lat;
        k_read_hit  = k_read  - k_read_miss;
        k_write_hit = k_write - k_writeback;

        target_lat  = p_read_hit  * k_read_hit + 
                      p_write_hit * k_write_hit +
                      p_read_miss * k_read_miss +
                      p_writeback * k_writeback;

        if ((cur_lat <= target_lat) && (halt_status == 1)) {
            // Resume all cores if halted.
            core_idx = 1;
            write_32b(DEBUG_RESUME, core_idx);
            core_idx = 2;
            write_32b(DEBUG_RESUME, core_idx);
            core_idx = 3;
            write_32b(DEBUG_RESUME, core_idx);
            halt_status = 0;        
        } else if ((cur_lat > target_lat) && (halt_status == 0)) {
            // Halt all cores if not already halted.
            core_idx = 1;
            write_32b(DEBUG_HALT, core_idx);
            core_idx = 2;
            write_32b(DEBUG_HALT, core_idx);
            core_idx = 3;
            write_32b(DEBUG_HALT, core_idx);
            halt_status = 1;
        }
    }

    return;
}