// #include "apmu_defines.h"
// #include "apmu_core_lib.h"

// #define DEBUG_HALT      0x200
// #define DEBUG_RESUME    0x208

// #define TIMER_ADDR      0x10404000
// #define DSPM_BASE_ADDR  0x10427000

// #define debug_halt(core_id)     write_32b(DEBUG_HALT, core_id)
// #define debug_resume(core_id)   write_32b(DEBUG_RESUME, core_id)

// #define HALT            101
// #define RESUME          303

// // C0: Reads to LLC by CUA.
// // C1: Writes to LLC by CUA.
// // C2: Reads to memory by CUA.
// // C3: Writes to memory by CUA.
// // C4: Read request latency.
// // C5: Write request latency.

// void used_for_test ();
// void for_show_biz ();

// void for_reg () {
//     asm volatile ("fence");
//     asm volatile ("li sp,272789504");

//     // PMU Timer.
//     volatile int unsigned timer_h = 0;
//     volatile int unsigned timer_l = 0;

//     // Read requests and read latencies, from counters.
//     volatile int unsigned cnt_n_read,  cnt_read_lat;
//     volatile int unsigned cnt_n_write, cnt_write_lat;

//     // Used for total latency computation and comparisons.
//     volatile int unsigned current_lat = 0;
//     volatile int unsigned target_lat  = 0;
//     // int unsigned current_lat_l = 0;
//     // int unsigned current_lat_u = 0;
//     // int unsigned target_lat_l  = 0;
//     // int unsigned target_lat_u  = 0;

//     int unsigned zero        = 0;
//     int unsigned core_idx    = 0;   // Used to loop over non-CUA cores.
//     int unsigned counter_idx = 0;   // Used to loop over PMU counters.

//     int unsigned halt_status     = RESUME;

//     // This is the target read_latency that the PMU should maintain for CUA.
//     volatile int *init = (int*)(DSPM_BASE_ADDR + 0x80);
//     volatile int unsigned target_avg_lat = *init;
//     init = (int*)(DSPM_BASE_ADDR + 0x84);
//     volatile int unsigned target_n_read = *init;

//     // Every halt-resume operation is logged into the DSPM with a timestamp.
//     int dspm_ptr = DSPM_BASE_ADDR + 0x100;

//     timer_l = read_32b(TIMER_ADDR);
//     write_32b(dspm_ptr, timer_l);
//     write_32b(dspm_ptr, RESUME);
//     dspm_ptr = dspm_ptr+ 0x10;

//     while (1) {
//         // Read necessary PMU counters.
//         // C0
//         counter_idx = 0;
//         asm volatile("fence");
//         counter_read(cnt_n_read, counter_idx);
//         counter_read(cnt_n_read, 10);
//         cnt_n_read = cnt_n_read & 0x7FFFFFFF;

//         // C1
//         counter_idx = 1;
//         counter_read(cnt_n_write, counter_idx);
//         cnt_n_write = cnt_n_write & 0x7FFFFFFF;
        
//         // C4
//         counter_idx = 4;
//         counter_read(cnt_read_lat, counter_idx);

//         // C5
//         counter_idx = 5;
//         counter_read(cnt_write_lat, counter_idx);

//         current_lat = cnt_read_lat + (cnt_write_lat >> 2);
//         // add_64u_32u(current_lat_l, current_lat_u, (cnt_read_lat & 0x7FFFFFFF), current_lat_l, current_lat_u);
//         // add_64u_32u(current_lat_l, current_lat_u, (cnt_write_lat & 0x7FFFFFFF) >> 2, current_lat_l, current_lat_u);
        
//         target_lat  = (cnt_n_read + (cnt_n_write >> 2)) * target_avg_lat;
//         // int tmp = (cnt_n_read & 0x7FFFFFFF) + ((cnt_n_write & 0x7FFFFFFF) >> 2);
//         // mult_32u_32u(tmp, target_avg_lat, target_lat_l, target_lat_u)

//         write_32b(DSPM_BASE_ADDR+0x84, cnt_n_read);
//         write_32b(DSPM_BASE_ADDR+0x88, cnt_n_write);

//         write_32b(DSPM_BASE_ADDR+0x8c, current_lat);
//         // write_32b(DSPM_BASE_ADDR+0x100c, current_lat >> 32);

//         write_32b(DSPM_BASE_ADDR+0x90, target_lat);
//         // write_32b(DSPM_BASE_ADDR+0x1014, target_lat >> 32);

//         timer_l = read_32b(TIMER_ADDR);
//         // timer_h = read_32b(TIMER_ADDR + 0x4);

//         if ((current_lat <= target_lat) && (halt_status == HALT)) {
//             // Resume all cores if halted.
//             core_idx = 1;
//             write_32b(DEBUG_RESUME, core_idx);
//             debug_resume(core_idx);
//             core_idx = 2;
//             write_32b(DEBUG_RESUME, core_idx);
//             debug_resume(core_idx);
//             core_idx = 3;
//             write_32b(DEBUG_RESUME, core_idx);
//             debug_resume(core_idx);
//             halt_status = RESUME;

//             if (dspm_ptr < DSPM_BASE_ADDR + 0x8000 - 0x20) {
//                 write_32b(dspm_ptr, timer_l);
//                 write_32b(dspm_ptr + 4, RESUME);
//                 write_32b(dspm_ptr + 8, current_lat);
//                 write_32b(dspm_ptr + 12, target_lat);
//                 dspm_ptr = dspm_ptr+ 0x10;
//             }

//         } else if ((current_lat > target_lat) && (halt_status == RESUME)) {
//             // Halt all cores if not already halted.
//             core_idx = 1;
//             write_32b(DEBUG_HALT, core_idx);
//             debug_halt(core_idx);
//             core_idx = 2;
//             write_32b(DEBUG_HALT, core_idx);
//             debug_halt(core_idx);
//             core_idx = 3;
//             write_32b(DEBUG_HALT, core_idx);
//             debug_halt(core_idx);
//             halt_status = HALT;

//             if (dspm_ptr < DSPM_BASE_ADDR + 0x8000 - 0x20) {
//                 write_32b(dspm_ptr, timer_l);
//                 write_32b(dspm_ptr + 4, HALT);
//                 write_32b(dspm_ptr + 8, current_lat);
//                 write_32b(dspm_ptr + 12, target_lat);
//                 dspm_ptr = dspm_ptr+ 0x10;
//             }
//         }
//     }

//     return;

// }

// void used_for_test () {

//     asm volatile ("fence");
//     asm volatile ("li sp,272789504");

//     // PMU Timer.
//     volatile int unsigned timer_h = 0;
//     volatile int unsigned timer_l = 0;

//     // Read requests and read latencies, from counters.
//     volatile int unsigned cnt_n_read,  cnt_read_lat;
//     volatile int unsigned cnt_n_write, cnt_write_lat;

//     // Used for total latency computation and comparisons.
//     volatile int unsigned current_lat = 0;
//     volatile int unsigned target_lat  = 0;
//     // int unsigned current_lat_l = 0;
//     // int unsigned current_lat_u = 0;
//     // int unsigned target_lat_l  = 0;
//     // int unsigned target_lat_u  = 0;

//     int unsigned zero        = 0;
//     int unsigned core_idx    = 0;   // Used to loop over non-CUA cores.
//     int unsigned counter_idx = 0;   // Used to loop over PMU counters.

//     int unsigned halt_status     = RESUME;
//     int unsigned last_timestamp  = 0;
//     int unsigned halt_time       = 0;
//     int unsigned resume_time     = 0;

//     int unsigned res_decision = 0;
//     int unsigned hal_decision = 0;

//     // This is the target read_latency that the PMU should maintain for CUA.
//     volatile int *init = (int*)(DSPM_BASE_ADDR + 0x80);
//     volatile int unsigned target_avg_lat = *init;
//     init = (int*)(DSPM_BASE_ADDR + 0x84);
//     volatile int unsigned target_n_read = *init;

//     // Every halt-resume operation is logged into the DSPM with a timestamp.
//     int dspm_ptr = DSPM_BASE_ADDR + 0x1300;
//     last_timestamp = read_32b(TIMER_ADDR);

//     while (1) {
//         // Read necessary PMU counters.
//         // C0
//         counter_idx = 0;
//         counter_read(cnt_n_read, counter_idx);
//         cnt_n_read = cnt_n_read & 0x7FFFFFFF;

//         // C1
//         counter_idx = 1;
//         counter_read(cnt_n_write, counter_idx);
//         cnt_n_write = cnt_n_write & 0x7FFFFFFF;
        
//         // C4
//         counter_idx = 4;
//         counter_read(cnt_read_lat, counter_idx);

//         // C5
//         counter_idx = 5;
//         counter_read(cnt_write_lat, counter_idx);

//         current_lat = cnt_read_lat + (cnt_write_lat >> 2);
//         // add_64u_32u(current_lat_l, current_lat_u, (cnt_read_lat & 0x7FFFFFFF), current_lat_l, current_lat_u);
//         // add_64u_32u(current_lat_l, current_lat_u, (cnt_write_lat & 0x7FFFFFFF) >> 2, current_lat_l, current_lat_u);
        
//         target_lat  = (cnt_n_read + (cnt_n_write >> 2)) * target_avg_lat;
//         // int tmp = (cnt_n_read & 0x7FFFFFFF) + ((cnt_n_write & 0x7FFFFFFF) >> 2);
//         // mult_32u_32u(tmp, target_avg_lat, target_lat_l, target_lat_u)

//         write_32b(DSPM_BASE_ADDR+0x1000, cnt_n_read);
//         write_32b(DSPM_BASE_ADDR+0x1004, cnt_n_write);

//         write_32b(DSPM_BASE_ADDR+0x1008, current_lat);
//         // write_32b(DSPM_BASE_ADDR+0x100c, current_lat >> 32);

//         write_32b(DSPM_BASE_ADDR+0x1010, target_lat);
//         // write_32b(DSPM_BASE_ADDR+0x1014, target_lat >> 32);

//         timer_l = read_32b(TIMER_ADDR);
//         // timer_h = read_32b(TIMER_ADDR + 0x4); 

//         res_decision = ((current_lat <= target_lat) && (halt_status == HALT)) ? RESUME:0;
//         hal_decision = ((current_lat > target_lat) && (halt_status == RESUME)) ? HALT:0;
//         write_32b(DSPM_BASE_ADDR+0x1710, res_decision);
//         write_32b(DSPM_BASE_ADDR+0x1720, hal_decision);
//         write_32b(DSPM_BASE_ADDR+0x1730, halt_status);
//         write_32b(DSPM_BASE_ADDR+0x1740, (current_lat <= target_lat));
//         write_32b(DSPM_BASE_ADDR+0x1750, (current_lat > target_lat));

//         if ((current_lat <= target_lat) && (halt_status == HALT)) {
//             // Resume all cores if halted.
//             core_idx = 1;
//             write_32b(DEBUG_RESUME, core_idx);
//             core_idx = 2;
//             write_32b(DEBUG_RESUME, core_idx);
//             core_idx = 3;
//             write_32b(DEBUG_RESUME, core_idx);
//             halt_status = RESUME;

//             halt_time = halt_time + (timer_l - last_timestamp);
//             write_32b(DSPM_BASE_ADDR+0x1100, halt_time);
//             write_32b(DSPM_BASE_ADDR+0x1300, 2);
//             write_32b(DSPM_BASE_ADDR+0x1400, timer_l);
//             write_32b(DSPM_BASE_ADDR+0x1500, current_lat);
//             write_32b(DSPM_BASE_ADDR+0x1520, target_lat);
//             write_32b(DSPM_BASE_ADDR+0x1540, cnt_n_read);
//             write_32b(DSPM_BASE_ADDR+0x1560, cnt_n_write);
//             last_timestamp = timer_l;
//         } else if ((current_lat > target_lat) && (halt_status == RESUME)) {
//             // Halt all cores if not already halted.
//             core_idx = 1;
//             write_32b(DEBUG_HALT, core_idx);
//             core_idx = 2;
//             write_32b(DEBUG_HALT, core_idx);
//             core_idx = 3;
//             write_32b(DEBUG_HALT, core_idx);
//             halt_status = HALT;

//             resume_time = resume_time + (timer_l - last_timestamp);
//             write_32b(DSPM_BASE_ADDR+0x1200, resume_time);
//             write_32b(DSPM_BASE_ADDR+0x1300, 1);
//             write_32b(DSPM_BASE_ADDR+0x1400, timer_l);
//             write_32b(DSPM_BASE_ADDR+0x1600, current_lat);
//             write_32b(DSPM_BASE_ADDR+0x1620, target_lat);
//             write_32b(DSPM_BASE_ADDR+0x1640, cnt_n_read);
//             write_32b(DSPM_BASE_ADDR+0x1660, cnt_n_write);
//             last_timestamp = timer_l;
//         }
//     }

//     return;
// }


// void main() {
//     asm volatile ("fence");
//     asm volatile ("li sp,272789504");

//     // PMU Timer.
//     volatile int unsigned timer_l = 0;
//     volatile int unsigned rst_timer_l = 0;

//     // Read requests and read latencies, from counters.
//     volatile int unsigned cnt_n_read,  cnt_read_lat;
//     volatile int unsigned cnt_n_write, cnt_write_lat;

//     volatile int unsigned rst_cnt_n_read,  rst_cnt_read_lat;
//     volatile int unsigned rst_cnt_n_write, rst_cnt_write_lat;

//     // Used for total latency computation and comparisons.
//     volatile int unsigned current_lat = 0;

//     // This is the target number of reads that we care about.
//     volatile int *init = (int*)(DSPM_BASE_ADDR + 0x84);
//     volatile int unsigned target_read = *init;

//     int unsigned counter_idx = 0;   // Used to loop over PMU counters.

//     int flag = 0;

//     rst_timer_l = read_32b(TIMER_ADDR);

//     // C0
//     counter_idx = 0;
//     counter_read(rst_cnt_n_read, counter_idx);

//     // C1
//     counter_idx = 1;
//     counter_read(rst_cnt_n_write, counter_idx);
    
//     // C4
//     counter_idx = 4;
//     counter_read(rst_cnt_read_lat, counter_idx);

//     // C5
//     counter_idx = 5;
//     counter_read(rst_cnt_write_lat, counter_idx);

//     write_32b(DSPM_BASE_ADDR+0x2100, rst_timer_l);
//     write_32b(DSPM_BASE_ADDR+0x2108, rst_cnt_n_read);
//     write_32b(DSPM_BASE_ADDR+0x210c, rst_cnt_n_write);
//     write_32b(DSPM_BASE_ADDR+0x2110, rst_cnt_read_lat);
//     write_32b(DSPM_BASE_ADDR+0x2114, rst_cnt_write_lat);

//     while (1) {
//         // Read necessary PMU counters.
//         // C0
//         counter_idx = 0;
//         counter_read(cnt_n_read, counter_idx);
//         cnt_n_read = cnt_n_read - rst_cnt_n_read;

//         // C1
//         counter_idx = 1;
//         counter_read(cnt_n_write, counter_idx);
//         cnt_n_write = cnt_n_write - rst_cnt_n_write;
        
//         // C4
//         counter_idx = 4;
//         counter_read(cnt_read_lat, counter_idx);
//         cnt_read_lat = cnt_read_lat - rst_cnt_read_lat;

//         // C5
//         counter_idx = 5;
//         counter_read(cnt_write_lat, counter_idx);
//         cnt_write_lat = cnt_write_lat - rst_cnt_write_lat;

//         // PMU Timer
//         timer_l = read_32b(TIMER_ADDR);
//         timer_l = timer_l -rst_timer_l;
//         current_lat = (cnt_read_lat & 0x7FFFFFFF) + ((cnt_write_lat & 0x7FFFFFFF) >> 2);

//         if ((cnt_n_read < target_read) || !flag) {
//             write_32b(DSPM_BASE_ADDR+0x2000, timer_l);
//             write_32b(DSPM_BASE_ADDR+0x2010, current_lat);
//             write_32b(DSPM_BASE_ADDR+0x2018, cnt_n_read);
//             write_32b(DSPM_BASE_ADDR+0x201c, cnt_n_write);
//             write_32b(DSPM_BASE_ADDR+0x2020, cnt_read_lat);
//             write_32b(DSPM_BASE_ADDR+0x2024, cnt_write_lat);
//             flag = 1;
//         }
//     }
// }

    #define DEBUG_HALT      0x200
    #define DEBUG_RESUME    0x208
    
    #define TIMER_ADDR      0x10404000
    #define DSPM_BASE_ADDR  0x10427000

    // Macros for 32-bit read-write to memory addresses.
    #define read_32b(addr)         (*(volatile int *)(long)(addr))
    #define write_32b(addr, val_)  (*(volatile int *)(long)(addr) = val_)
    
    // Macros to program the Debug module.
    #define debug_halt(core_id)     write_32b(DEBUG_HALT, core_id)
    #define debug_resume(core_id)   write_32b(DEBUG_RESUME, core_id)

    // Macros for custom APMU core instructions.
    // Counter read: rd = cnt[rs1]
    #define counter_read(rd, rs1)       asm volatile ("cnt.rd\t%0,%1" : "=r" (rd) : "r" (rs1));
    // Counter write: cnt[rs1] = rs2
    #define counter_write(rs1, rs2)     asm volatile ("cnt.wr\t%0,%1" :: "r" (rs1), "r" (rs2));
    
    #define HALT            1
    #define RESUME          0

    void main () {
        // Load the DSPM base address into SP.
        asm volatile ("li sp,272789504");
        
        // Number of requests and latencies, read from APMU counters.
        volatile int unsigned cnt_n_read,  cnt_read_lat;
        volatile int unsigned cnt_n_write, cnt_write_lat;
        // Used for total latency computation and comparisons.
        volatile int unsigned current_lat = 0;
        volatile int unsigned target_lat  = 0;

        // Used to loop over non-CUA cores.
        int unsigned core_idx    = 0;
        // Used to loop over APMU counters.
        int unsigned counter_idx = 0;
        
        // To verify correct operation.
        int unsigned halt_status     = RESUME;

        // This is the target avg_lat that APMU should maintain for CUA.
        volatile int *target_addr = (int*)(DSPM_BASE_ADDR + 0x80);
        volatile int unsigned target_avg_lat = read_32b(target_addr);

        // Regulation mechanism starts.
        while (1) {
            // Read necessary PMU counters.
            // Counter 0: Number of read requests
            counter_read(cnt_n_read, 0);
            cnt_n_read = cnt_n_read & 0x7FFFFFFF;
    
            // Counter 1: Number of write requests
            counter_read(cnt_n_write, 1);
            cnt_n_write = cnt_n_write & 0x7FFFFFFF;
            
            // Counter 2: Cumulative read latency
            counter_read(cnt_read_lat, 2);
    
            // Counter 3: Cumulative write latency
            counter_read(cnt_write_lat, 3);

            current_lat = cnt_read_lat + (cnt_write_lat >> 2);
            target_lat  = (cnt_n_read + (cnt_n_write >> 2)) * target_avg_lat;

            if ((current_lat <= target_lat) && (halt_status == HALT)) {
                // Resume all cores if halted.
                debug_resume(1);
                debug_resume(2);
                debug_resume(3);
                halt_status = RESUME;
            } else if ((current_lat > target_lat) && (halt_status == RESUME)) {
                // Halt all cores if not already halted.
                debug_halt(1);
                debug_halt(2);
                debug_halt(3);
                halt_status = HALT;
            }
        }
    }