#include "apmu_core_lib.h"

void main () {
    volatile int a;
    a = 2;
    volatile int b = a*a*a;
    volatile int c;
    if (b == 100) {
        c = b+1;
    } else {
        c = b*b;
    }

    int x1, x2, x4, x5;
    counter_read(x1,x2);

    counter_write(x4,x5);
    asm volatile ("cnt.rd %0, %1":"=r"(x1):"r"(x2));

    return;
}