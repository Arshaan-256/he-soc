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
///     1. Counter
///     2. Event Selection Register
///     3. Event Info Configuration Register
///     4. Initial Budget Register

#include "pmu_test_func.c"

// *********************************************************************
// Main Function
// *********************************************************************
int main(int argc, char const *argv[]) {
  #ifdef FPGA_EMULATION
  uint32_t baud_rate = 9600;
  uint32_t test_freq = 100000000;
  #else
  set_flls();
  uint32_t baud_rate = 115200;
  uint32_t test_freq = 100000000;
  #endif  

  uart_set_cfg(0,(test_freq/baud_rate)>>4);

  uint32_t error_count = 0;

  // Pointer is char to make it byte-addressable,
  // event_sel_config does not always align by 32B boundary!

  // Two 64-bit (8B) timer and one 32-bit status registers in the PMU bundle.
  uint64_t PMU_BUNDLE_SIZE        = 2 * 8 + 4;

  // Four 32-bit (4B) registers in one counter bundle.
  uint64_t COUNTER_BUNDLE_SIZE    = 4 * 4;

  // Base Addresses
  uint64_t PMU_BASE_ADDR          = 0x10404000;     // Timer Base Address
  uint64_t PERIOD_BASE_ADDR       = PMU_BASE_ADDR + 0x8;
  uint64_t STATUS_BASE_ADDR       = PMU_BASE_ADDR + 0x8*2;

  uint64_t COUNTER_BASE_ADDR      = PMU_BASE_ADDR + PMU_BUNDLE_SIZE;
  uint64_t EVENT_SEL_BASE_ADDR    = COUNTER_BASE_ADDR + 0x4;
  uint64_t EVENT_INFO_BASE_ADDR   = EVENT_SEL_BASE_ADDR + 0x4;
  uint64_t INIT_BUDGET_BASE_ADDR  = EVENT_INFO_BASE_ADDR + 0x4;

  uint64_t ISPM_BASE_ADDRESS      = 0x10405000;
  uint64_t DSPM_BASE_ADDRESS      = 0x10406000;
  
  uint32_t counter_val[]          = {0x100, 0x200, 0x300, 0x400};
  uint32_t event_sel_val[]        = {0x1FAB00, 0x1FAB01, 0x1FAB02, 0x1FAB03};
  uint32_t act_event_sel_val[]    = {0x1F001F, 0x1F002F, 0x1F003F, 0x1F004F};
  uint32_t event_info_val[]       = {0x8001C0		, 0x8001C0, 0x8001E0, 0x8001E0};
  uint32_t init_budget_val[]      = {0xFFFFFFE0, 0xFFFFA000, 0xFFFFB000, 0xFFFFC000};
  uint64_t period_val             = 0x0;
  uint64_t timer;
  
  counter_b_t counter_b[NUM_COUNTER];

  for (int i=0; i<NUM_COUNTER; i++) {
    counter_b[i].counter     = counter_val[i];
    counter_b[i].event_sel   = event_sel_val[i];
    counter_b[i].event_info  = event_info_val[i];
    counter_b[i].init_budget = init_budget_val[i];
  }
  uint32_t program[] = {0x593,
    0x104040b7,
0x1408093,
0x104063b7,
0x38393,
0x400113,
0x1000193,
0x233,
0x82b3,
0x1100313,
0x62a023,
0x1130313,
0x62a223,
0x1130313,
0x62a423,
0x1130313,
0x62a623,
0x1130313,
0x120213,
0x3282b3,
0xfc221ce3,
0x6500413,
0x83a023,
0x33,
0xfe000ee3
  };

  uint32_t _program[] = {0x593,
                        0x593,
                        0x104060b7,
0x8093,
0xaa0137,
0xaa10113,
0x20a023,
0xaf03,
0xaa0eb7,
0xaae8e93,
0x200193,
0x47df1063,
0x104060b7,
0x408093,
0xaa00b137,
0xa0010113,
0x20a223,
0x40af03,
0xaa00beb7,
0xa00e8e93,
0x300193,
0x43df1c63,
0x104060b7,
0x208093,
0xaa01137,
0xaa010113,
0x20a423,
0x80af03,
0xaa01eb7,
0xaa0e8e93,
0x400193,
0x41df1863,
0x104060b7,
0x8093,
0xa00aa137,
0xa10113,
0x20a623,
0xc0af03,
0xa00aaeb7,
0xae8e93,
0x500193,
0x3fdf1463,
0x104060b7,
0x1008093,
0xaa0137,
0xaa10113,
0xfe20aa23,
0xff40af03,
0xaa0eb7,
0xaae8e93,
0x600193,
0x3ddf1063,
0x104060b7,
0xc08093,
0xaa00b137,
0xa0010113,
0xfe20ac23,
0xff80af03,
0xaa00beb7,
0xa00e8e93,
0x700193,
0x39df1c63,
0x104060b7,
0x808093,
0xaa01137,
0xaa010113,
0xfe20ae23,
0xffc0af03,
0xaa01eb7,
0xaa0e8e93,
0x800193,
0x37df1863,
0x104060b7,
0x408093,
0xa00aa137,
0xa10113,
0x20a023,
0xaf03,
0xa00aaeb7,
0xae8e93,
0x900193,
0x35df1463,
0x104060b7,
0x2008093,
0x12345137,
0x67810113,
0xfe008213,
0x2222023,
0xa283,
0x12345eb7,
0x678e8e93,
0xa00193,
0x31d29e63,
0x104060b7,
0x808093,
0x58213137,
0x9810113,
0xffd08093,
0x20a3a3,
0x10406237,
0xc20213,
0x22283,
0x58213eb7,
0x98e8e93,
0xb00193,
0x2fd29463,
0xc00193,
0x213,
0xaabbd0b7,
0xcdd08093,
0x10406137,
0x10113,
0x112023,
0x12f03,
0xaabbdeb7,
0xcdde8e93,
0x2bdf1e63,
0x120213,
0x200293,
0xfc521ae3,
0xd00193,
0x213,
0xdaabc0b7,
0xccd08093,
0x10406137,
0x10113,
0x13,
0x112223,
0x412f03,
0xdaabceb7,
0xccde8e93,
0x29df1063,
0x120213,
0x200293,
0xfc5218e3,
0xe00193,
0x213,
0xddaac0b7,
0xbcc08093,
0x10406137,
0x410113,
0x13,
0x13,
0x112423,
0x812f03,
0xddaaceb7,
0xbcce8e93,
0x25df1063,
0x120213,
0x200293,
0xfc5216e3,
0xf00193,
0x213,
0xcddab0b7,
0xbbc08093,
0x13,
0x10406137,
0x410113,
0x112623,
0xc12f03,
0xcddabeb7,
0xbbce8e93,
0x21df1263,
0x120213,
0x200293,
0xfc5218e3,
0x1000193,
0x213,
0xccddb0b7,
0xabb08093,
0x13,
0x10406137,
0x210113,
0x13,
0x112823,
0x1012f03,
0xccddbeb7,
0xabbe8e93,
0x1ddf1263,
0x120213,
0x200293,
0xfc5216e3,
0x1100193,
0x213,
0xbccde0b7,
0xaab08093,
0x13,
0x13,
0x10406137,
0x10113,
0x112a23,
0x1412f03,
0xbccdeeb7,
0xaabe8e93,
0x19df1263,
0x120213,
0x200293,
0xfc5216e3,
0x1200193,
0x213,
0x10406137,
0x810113,
0x1120b7,
0x23308093,
0x112023,
0x12f03,
0x112eb7,
0x233e8e93,
0x15df1663,
0x120213,
0x200293,
0xfc521ae3,
0x1300193,
0x213,
0x10406137,
0x210113,
0x300110b7,
0x22308093,
0x13,
0x112223,
0x412f03,
0x30011eb7,
0x223e8e93,
0x11df1863,
0x120213,
0x200293,
0xfc5218e3,
0x1400193,
0x213,
0x10406137,
0x410113,
0x330010b7,
0x12208093,
0x13,
0x13,
0x112423,
0x812f03,
0x33001eb7,
0x122e8e93,
0xddf1863,
0x120213,
0x200293,
0xfc5216e3,
0x1500193,
0x213,
0x10406137,
0x10113,
0x13,
0x233000b7,
0x11208093,
0x112623,
0xc12f03,
0x23300eb7,
0x112e8e93,
0x9df1a63,
0x120213,
0x200293,
0xfc5218e3,
0x1600193,
0x213,
0x10406137,
0x10113,
0x13,
0x223300b7,
0x1108093,
0x13,
0x112823,
0x1012f03,
0x22330eb7,
0x11e8e93,
0x5df1a63,
0x120213,
0x200293,
0xfc5216e3,
0x1700193,
0x213,
0x10406137,
0x10113,
0x13,
0x13,
0x122330b7,
0x108093,
0x112a23,
0x1412f03,
0x12233eb7,
0x1e8e93,
0x1df1a63,
0x120213,
0x200293,
0xfc5216e3,
0x301863,
0xa00593,
0x33,
0xfe000ee3,
0xc00593,
0x33,
0xfe000ee3};

  printf("Hello PMU!\n");
  uart_wait_tx_done();
  
  uint32_t program_size = sizeof(program) / sizeof(program[0]);                            

  // printf("Testing Counters!\n");
  // test_counter_bundle(COUNTER_BASE_ADDR, 4, COUNTER_BUNDLE_SIZE, counter_b);

  // Setup event_sel registers.
  // printf("Setting up event_sel_config!\n");
  // write_32b_regs(EVENT_SEL_BASE_ADDR, 4, act_event_sel_val, COUNTER_BUNDLE_SIZE);


  // for (uint32_t i=0; i<2; i++) {
  //   array_traversal(NUM_ELEMENT*(i+1));
  // }

  // Testing for ISPM
  // printf("Testing ISPM!\n");
  // error_count += test_spm(ISPM_BASE_ADDRESS, program_size, program);
  // printf("ISPM Test Over, errors: 0%d!\n", error_count);
  
  // Testing for DSPM
  // printf("Testing DSPM!\n");
  // error_count += test_spm_rand(DSPM_BASE_ADDRESS, 20);

  // printf("Input array!\n");
  // uint32_t rval[20];
  // read_32b_regs(DSPM_BASE_ADDRESS, 20, rval, 0x4);
  // for (uint32_t i=0; i<20; i++) {
  //   printf("%0d\n",rval[i]);
  // }

  // // Setup event_sel registers.
  // printf("Setting up event_sel_config!\n");
  // write_32b_regs(EVENT_SEL_BASE_ADDR, 4, act_event_sel_val, COUNTER_BUNDLE_SIZE);

  // printf("Starting the core!\n");
  // write_32b(STATUS_BASE_ADDR, 0);
  // while (1) {
  //   uint end = read_32b(DSPM_BASE_ADDRESS);
  //   if (end == 101)
  //     break;
  // }
  // for (uint32_t i=0; i<2; i++) {
  //   write_32b(STATUS_BASE_ADDR, 0);
  //   array_traversal(NUM_ELEMENT*(i+1));
  //   write_32b(STATUS_BASE_ADDR, 1);
  // }

  // add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_pmu/i_pmu_core/i_ibex_pmu_core/gen_regfile_ff/register_file_i/*

  error_count += test_pmu_core_counter_b_writes (ISPM_BASE_ADDRESS, 
                                                 COUNTER_BASE_ADDR, 
                                                 DSPM_BASE_ADDRESS, 
                                                 STATUS_BASE_ADDR,
                                                 COUNTER_BUNDLE_SIZE,
                                                 NUM_COUNTER, 
                                                 2);

  // error_count += test_pmu_core_bubble_sort(ISPM_BASE_ADDRESS,
  //                                          DSPM_BASE_ADDRESS,
  //                                          STATUS_BASE_ADDR,
  //                                          10, 2);

  printf("The test is over!\n");
  printf("Errors: %0d\n", error_count);
  uart_wait_tx_done();

  return 0;
}




