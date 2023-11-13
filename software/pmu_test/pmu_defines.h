/// This assumes the following: 
///   1. The PMU counters (including the initial budget registers) are 32-bit with 
///      the 31st bit reserved for Pending.
///   2. Both the configuration registers are 32-bits.
///
/// NUM_COUNTER is parameterizable and should be set to the number of counters in the PMU.
/// The memory map of the PMU is as follows:
///     /************************************\
///     | Initial Budget Register            |
///     | Event Info Configuration Register  |          Not yet 4kB aligned
///     | Event Selection Register           |              Counter Bundle
///     | Counter                            |
///     \************************************/
///                     .
///                     .                         ... x (NUM_COUNTER)
///                     .
///     /************************************\
///     | Initial Budget Register            |
///     | Event Info Configuration Register  |          Not yet 4kB aligned          
///     | Event Selection Register           |              Counter Bundle
///     | Counter                            |
///     \************************************/
///     /************************************\
///     | Initial Budget Register            |
///     | Event Info Configuration Register  |          Not yet 4kB aligned
///     | Event Selection Register           |              Counter Bundle
///     | Counter                            |
///     \************************************/
///     /************************************\
///     | MemGuard Period Register           |          Not yet 4kB aligned
///     | PMU Timer                          |              PMU Bundle
///     \************************************/
/// Each block is a separate 4kB-aligned page.
/// The PMU Bundle includes the PMU Timer and the MemGuard Period Register.
/// A counter bundle includes:
///     1. Counter                                BASE_ADDR + 0x0
///     2. Event Selection Register               BASE_ADDR + 0x4
///     3. Event Info Configuration Register      BASE_ADDR + 0x8
///     4. Initial Budget Register                BASE_ADDR + 0xc

#define NUM_COUNTER 8

#define TIMER_WIDTH     0x8
#define STATUS_WIDTH    0x4
#define BOOT_ADDR_WIDTH 0x4
#define COUNTER_WIDTH   0x4

// PMU Bundle Addresses
#define PMU_B_BASE_ADDR     0x10404000
#define TIMER_ADDR          (PMU_B_BASE_ADDR)
#define PERIOD_ADDR         (PMU_B_BASE_ADDR + TIMER_WIDTH)
#define PMC_STATUS_ADDR     (PMU_B_BASE_ADDR + 2*TIMER_WIDTH)
#define PMC_BOOT_ADDR       (PMU_B_BASE_ADDR + 2*TIMER_WIDTH + STATUS_WIDTH)
// Two 64-bit (8B) timer and one 32-bit status registers in the PMU bundle.
#define PMU_BUNDLE_SIZE     2*TIMER_WIDTH + STATUS_WIDTH + BOOT_ADDR_WIDTH

// Counter Bundle Base Addresses
#define COUNTER_B_BASE_ADDR     (PMU_B_BASE_ADDR + PMU_BUNDLE_SIZE)
#define COUNTER_BASE_ADDR       (COUNTER_B_BASE_ADDR + 0*COUNTER_WIDTH)
#define EVENT_SEL_BASE_ADDR     (COUNTER_B_BASE_ADDR + 1*COUNTER_WIDTH)
#define EVENT_INFO_BASE_ADDR    (COUNTER_B_BASE_ADDR + 2*COUNTER_WIDTH)
#define INIT_BUDGET_BASE_ADDR   (COUNTER_B_BASE_ADDR + 3*COUNTER_WIDTH)
// Four 32-bit (4B) registers in one counter bundle.
#define COUNTER_BUNDLE_SIZE     16

// // // PMU Core Addresses
#define ISPM_BASE_ADDR      0x10405000
#define DSPM_BASE_ADDR      0x10406000
