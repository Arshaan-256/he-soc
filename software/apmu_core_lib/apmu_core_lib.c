#include "apmu_defines.h"
#include "apmu_core_lib.h"

#define DEBUG_HALT      0x200
#define DEBUG_RESUME    0x208

#define TIMER_ADDR      0x10404000
#define DSPM_BASE_ADDR  0x10427000

#define debug_halt(core_id)     write_32b(DEBUG_HALT, core_id)
#define debug_resume(core_id)   write_32b(DEBUG_RESUME, core_id)

#define HALT            101
#define RESUME          303

// C0: Reads to LLC by CUA.
// C1: Writes to LLC by CUA.
// C2: Reads to memory by CUA.
// C3: Writes to memory by CUA.
// C4: Read request latency.
// C5: Write request latency.
void mempol() {
    
}


