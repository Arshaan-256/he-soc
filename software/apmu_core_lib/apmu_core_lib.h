// Macros for 32-bit read-write to memory address.
#define read_32b(addr)         (*(volatile int *)(long)(addr))
#define write_32b(addr, val_)  (*(volatile int *)(long)(addr) = val_)

// Macros for custom PMU core instructions.
// Counter read: rd = cnt[rs1]
#define counter_read(rd, rs1)       asm volatile ("cnt.rd\t%0,%1" : "=r" (rd) : "r" (rs1));
// Counter write: cnt[rs1] = rs2
#define counter_write(rs1, rs2)     asm volatile ("cnt.wr\t%0,%1" :: "r" (rs1), "r" (rs2));

#define mult_32u_32u(in1, in2, out_l, out_u) {\
    asm volatile ("mul %0,%1,%2" : "=r" (out_l) : "r"(in1), "r"(in2)); \
    asm volatile ("mulhu %0,%1,%2" : "=r" (out_u) : "r"(in1), "r"(in2)); \
}

#define add_64u_32u(in1_l, in1_u, in2, out_l, out_u) {\
    asm volatile ("# out = in1 + in2"); \
    out_l = in1_l + in2; \
    out_u = in1_u; \
    if (out_l < (unsigned) in1_l) \
        out_u = in1_u + 1; \
}
