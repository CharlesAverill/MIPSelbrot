.data
a:	.word	2
b:	.word	0

.text
main:
	lw $t0, a
	lw $t1, b
	
	ori $t3, $t0, 0x2
exit: 
	li	$v0, 10
	syscall