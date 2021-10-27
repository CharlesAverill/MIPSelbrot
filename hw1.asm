# Homework 1
# Charles Averill
# 2340.003
# Aug 31, 2021

.data
	a:				.word 0
	b:				.word 0
	c:				.word 0

	out1:			.word 0
	out2:			.word 0
	out3:			.word 0

	username:		.space 64 # Allocate 64 bytes for the username
	
	name_prompt:	.asciiz "What is your name? "
	int_prompt:		.asciiz "Please enter an integer between 1-100: "
	
	results:		.asciiz "Your answers are: "
	space:			.asciiz " "

.text
main:
	# $v0 = syscall opcode
	# $a0-1 = arguments for syscalls
	
	# Print name_prompt
	li $v0, 4
	# $aN registers for arguments
	la $a0, name_prompt
	syscall
	
	# Read string
	li $v0, 8
	la $a0, username
	li $a1, 64
	syscall
	
	# Print int_prompt
	li $v0, 4
	la $a0, int_prompt
	syscall
	
	# Read a
	li $v0, 5
	syscall
	sw $v0, a
	
	# Print int_prompt
	li $v0, 4
	la $a0, int_prompt
	syscall
	
	# Read b
	li $v0, 5
	syscall
	sw $v0, b
	
	# Print int_prompt
	li $v0, 4
	la $a0, int_prompt
	syscall
	
	# Read c
	li $v0, 5
	syscall
	sw $v0, c
	
	# Load into memory
	# $t0 = a
	# $t1 = b
	# $t2 = c
	# $t3 = out1
	# $t4 = out2
	# $t5 = out3
	
	lw $t0, a
	lw $t1, b
	lw $t2, c
	
	lw $t3, out1
	lw $t4, out2
	lw $t5, out3
	
	# out1 = 2a - c + 4
	add $t3, $t0, $t0 # 2 * a
	sub $t3, $t3, $t2 # - c
	addi $t3, $t3, 4 # + 4
	sw $t3, out1
	# out2 = b - c + (a - 2)
	add $t4, $t4, $t1 # b
	sub $t4, $t4, $t2 # - c
	add $t4, $t4, $t0 # + a
	subi $t4, $t4, 2 # + 2
	sw $t4, out2
	# out3 = (a + b) - (b - 1) + (c + 3)
	add $t5, $t0, $t1 # a + b
	sub $t5, $t5, $t1 # - b
	addi $t5, $t5, 1 # - (-1)
	add $t5, $t5, $t2 # + c
	addi $t5, $t5, 3 # + 3
	sw $t5, out3
	
	# Print name
	li $v0, 4
	la $a0, username
	syscall
	
	# Print results
	li $v0, 4
	la $a0, results
	syscall
	
	# Print out1
	li $v0, 1
	lw $a0, out1
	syscall
	
	# Print space
	li $v0, 4
	la $a0, space
	syscall
	
	# Print out2
	li $v0, 1
	lw $a0, out2
	syscall
	
	# Print space
	li $v0, 4
	la $a0, space
	syscall
	
	# Print out3
	li $v0, 1
	lw $a0, out3
	syscall
	
	# Exit program
exit:
	li $v0, 10
	syscall
	
	# SAMPLE RUNS
	# What is your name? charles
	# Please enter an integer between 1-100: 1
	# Please enter an integer between 1-100: 5
	# Please enter an integer between 1-100: 6
	# charles
	# Your answers are: 0 -2 11
	
	# What is your name? charles2
	# Please enter an integer between 1-100: 5
	# Please enter an integer between 1-100: 89
	# Please enter an integer between 1-100: 3
	# charles3
	# Your answers are: 11 89 12
	
	# What is your name? charles3
	# Please enter an integer between 1-100: 99
	# Please enter an integer between 1-100: 99
	# Please enter an integer between 1-100: 99
	# charles3
	# Your answers are: 103 97 202
