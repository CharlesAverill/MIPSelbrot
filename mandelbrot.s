.data
newline:	.asciiz	"\n"
.text
main:
	addiu	$fp, $sp, 0

	# Make space for variables
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	subu	$sp, $sp, 4
	
	# Width
	ori	$t0, $zero, 256
	sw	$t0, 8($fp)
	# Height
	ori	$t0, $zero, 256
	sw	$t0, 4($fp)
	# Max_Iter
	ori	$t0, $zero, 570
	sw	$t0, 8($fp)
	
	ori	$t0, $zero, 0
	sw	$t0, 36($fp)
L0:
	lw	$t0, 36($fp)
	lw	$t1, 4($fp)
	slt	$at, $t0, $t1
	beq	$at, $zero, L1
	ori	$t0, $zero, 0
	sw	$t0, 28($fp)
L2:
	lw	$t0, 28($fp)
	lw	$t1, 0($fp)
	slt	$at, $t0, $t1
	beq	$at, $zero, L3
	ori	$t0, $zero, 0
	sw	$t0, 32($fp)
	ori	$t0, $zero, 0
	sw	$t0, 12($fp)
	lw	$t0, 28($fp)
	lw	$t1, 0($fp)
	ori	$t2, $zero, 2
	div	$t1, $t2
	mflo	$t2
	sub	$t0, $t0, $t2
	sw	$t0, 20($fp)
	lw	$t0, 36($fp)
	lw	$t1, 4($fp)
	ori	$t2, $zero, 2
	div	$t1, $t2
	mflo	$t2
	sub	$t0, $t0, $t2
	sw	$t0, 24($fp)
	lw	$t0, 8($fp)
	sw	$t0, 40($fp)
L4:
	lw	$t0, 12($fp)
	lw	$t1, 12($fp)
	mult	$t0, $t1
	mflo	$t1
	lw	$t0, 16($fp)
	lw	$t2, 16($fp)
	mult	$t0, $t2
	mflo	$t2
	add	$t1, $t1, $t2
	ori	$t0, $zero, 4
	slt	$at, $t1, $t0
	beq	$at, $zero, L5
	lw	$t0, 12($fp)
	lw	$t1, 12($fp)
	mult	$t0, $t1
	mflo	$t1
	lw	$t0, 16($fp)
	lw	$t2, 16($fp)
	mult	$t0, $t2
	mflo	$t2
	sub	$t1, $t1, $t2
	lw	$t0, 20($fp)
	add	$t1, $t1, $t0
	sw	$t1, 28($fp)
	ori	$t0, $zero, 2
	lw	$t1, 12($fp)
	mult	$t0, $t1
	mflo	$t1
	lw	$t0, 16($fp)
	mult	$t1, $t0
	mflo	$t0
	lw	$t1, 24($fp)
	add	$t0, $t0, $t1
	sw	$t0, 16($fp)
	lw	$t0, 28($fp)
	sw	$t0, 12($fp)
	j	L4
L5:
	lw	$t0, 28($fp)
	ori	$t1, $zero, 1
	add	$t0, $t0, $t1
	sw	$t0, 28($fp)
	j	L2
L3:
	lw	$t0, 36($fp)
	ori	$t1, $zero, 1
	add	$t0, $t0, $t1
	sw	$t0, 36($fp)
	j	L0
L1:

exit:
	ori	$v0, $zero, 10
	syscall
