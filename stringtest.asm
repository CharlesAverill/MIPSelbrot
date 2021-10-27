.data 
str:		.asciiz "Hello World"
newline:	.ascii "\0"
			.align 3
.text
main:
	# t0 - string index
	li $t0, 0
	# t1 - address of str
	la $t1, str
	# t4 - newline
	lb $t4, newline
loop:
	# t2 - temporary index
	move $t2, $t1
	add $t2, $t2, $t0
	lb $t3, ($t2) # t3 - current byte
	# print current byte
	move $a0, $t3
	li $v0, 11
	syscall
	
	addi $t0, $t0, 1 # i++
	beq $t3, $zero, exit
	j loop
exit:
	li $v0, 10
	syscall
