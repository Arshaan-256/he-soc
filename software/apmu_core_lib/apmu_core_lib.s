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
	li	a4,0
	li	t4,1
	li	t6,2
	li	t5,3
.L2:
 #APP
# 30 "apmu_core_lib.c" 1
	cnt.rd	a7,a4
# 0 "" 2
 #NO_APP
	addi	a3,a4,1
 #APP
# 33 "apmu_core_lib.c" 1
	cnt.rd	a3,a3
# 0 "" 2
 #NO_APP
	addi	a6,a4,2
 #APP
# 36 "apmu_core_lib.c" 1
	cnt.rd	a6,a6
# 0 "" 2
 #NO_APP
	addi	a1,a4,3
 #APP
# 39 "apmu_core_lib.c" 1
	cnt.rd	a1,a1
# 0 "" 2
 #NO_APP
	addi	a2,a4,4
 #APP
# 42 "apmu_core_lib.c" 1
	cnt.rd	a2,a2
# 0 "" 2
 #NO_APP
	addi	a4,a4,5
 #APP
# 45 "apmu_core_lib.c" 1
	cnt.rd	t1,a4
# 0 "" 2
 #NO_APP
	sub	a3,a3,a1
	slli	a5,a3,1
	slli	a0,a6,1
	add	a5,a5,a3
	sub	a7,a7,a6
	add	a3,a0,a6
	slli	a3,a3,1
	add	a5,a5,a7
	slli	a0,a1,3
	add	a5,a5,a3
	add	a1,a0,a1
	add	a3,a2,t1
	add	a5,a5,a1
	ble	a3,a5,.L9
	beq	t3,zero,.L5
	li	t3,1
	j	.L2
.L5:
	sw	t4,512(zero)
	sw	t6,512(zero)
	sw	t5,512(zero)
	li	t3,1
	j	.L2
.L9:
	beq	t3,t4,.L10
	li	t3,0
	j	.L2
.L10:
	sw	t4,520(zero)
	sw	t6,520(zero)
	sw	t5,520(zero)
	li	t3,0
	j	.L2
	.size	main, .-main
	.ident	"GCC: (gc891d8dc23e) 13.2.0"
