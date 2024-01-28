// Macros for 32-bit read-write to memory address.
#define read_32b(addr)         (*(volatile int *)(long)(addr))
#define write_32b(addr, val_)  (*(volatile int *)(long)(addr) = val_)

// Macros for custom PMU core instructions.
#define counter_read(rd, rs1)       asm volatile ("cnt.rd\t%0,%1" : "=r" (rd) : "r" (rs1));
#define counter_write(rs1, rs2)     asm volatile ("cnt.wr\t%0,%1" :: "r" (rs1), "r" (rs2));

