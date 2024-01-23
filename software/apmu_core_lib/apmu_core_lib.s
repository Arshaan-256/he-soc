	.file	"apmu_core_lib.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.startup,"ax",@progbits
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	li	a5,2
	sw	a5,4(sp)
	lw	a5,4(sp)
	lw	a2,4(sp)
	lw	a3,4(sp)
	li	a4,100
	mul	a5,a5,a2
	mul	a5,a5,a3
	sw	a5,8(sp)
	lw	a5,8(sp)
	beq	a5,a4,.L6
	lw	a5,8(sp)
	lw	a4,8(sp)
	mul	a5,a5,a4
	sw	a5,12(sp)
.L3:
	li	a5,0
 #APP
# 15 "apmu_core_lib.c" 1
	cnt.rd a4, a5
# 0 "" 2
 #NO_APP
	li	a4,0
	li	a3,0
 #APP
# 17 "apmu_core_lib.c" 1
	cnt.wr a4, a3
# 0 "" 2
# 18 "apmu_core_lib.c" 1
	cnt.rd a5, a5
# 0 "" 2
 #NO_APP
	addi	sp,sp,16
	jr	ra
.L6:
	lw	a5,8(sp)
	addi	a5,a5,1
	sw	a5,12(sp)
	j	.L3
	.size	main, .-main
	.ident	"GCC: (gc891d8dc23e) 13.2.0"
