#define counter_read(rd, rs1)       asm volatile ("cnt.rd %0, %1" : "=r" (rd) : "r" (rs1));
#define counter_write(rs1, rs2)     asm volatile ("cnt.wr %0, %1" :: "r" (rs1), "r" (rs2));