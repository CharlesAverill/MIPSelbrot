# Homework 2
# Charles Averill
# 2340.003
# Sep 13, 2021

.data
	string_prompt:	.asciiz "Enter some text:"
	goodbye:		.asciiz "Goodbye!"
	
	input_string:	.space 32 # 31 characters + null terminator
	max_chars:		.word 32
	
	num_chars:		.word -1
	num_words:		.word -1
	
	words:			.asciiz " words "
	characters:		.asciiz " characters\n"
	
	space:			.asciiz " "
	space_val:		.word 32 # 32 = ASCII value for a blank space
.text
main:
	# prompt for string
	li $v0, 54
	la $a0, string_prompt
	la $a1, input_string
	lw $a2, max_chars
	syscall
	
	# if status is not OK, exit
	bne $a1, $0, exit
	
	# count characters and words
	la $a0, input_string
	jal count_characters_words
	# copy return values to $t0 and $t1
	move $t0, $v0
	move $t1, $v1
	
	# print input_string
	li $v0, 4
	la $a0, input_string
	syscall
	
	# print num_words
	li $v0, 1
	move $a0, $t1
	syscall
	
	# print words
	li $v0, 4
	la $a0, words
	syscall
	
	# print num_characters
	li $v0, 1
	move $a0, $t0
	syscall
	
	# print characters
	li $v0, 4
	la $a0, characters
	syscall
	
	# loop
	j main
exit:
	# Display goodbye message
	li $v0, 59
	la $a0, goodbye
	syscall
	
	# exit program
	li $v0, 10
	syscall
	
count_characters_words:
	# ARGUMENTS
	# a0 - address of string
	# RETURN
	# v0 - number of characters in string
	# v1 - number of words in string
	
	# Push stack pointer
	addi $sp, $sp, -4
	sw $s1, ($sp)
	
	# s1 - index (being 0-indexed causes a weird bug, interesting)
	li $s1, 1
	# t3 - address of string
	move $t3, $a0
	# t4 - space ASCII value
	lw $t4, space_val
	
	# initialize return values
	li $v0, 0
	li $v1, 1 # always add 1 to word counter
loop:
	# t1 - address of string[i]
	move $t1, $t3
	add $t1, $t1, $s1
	# t2 - string[i]
	lb $t2, ($t1)
	# loop unless current character is null terminator
	beq $t2, $zero, loop_break
	# check if word counter must be incremented
	beq $t4, $t2, word_increment
loop_char_increment:
	# num_chars++, i++
	addi $v0, $v0, 1
	addi $s1, $s1, 1
	j loop
word_increment:
	# increment word counter, return back to end of loop
	addi $v1, $v1, 1
	j loop_char_increment
loop_break:
	# pop stack pointer
	lw $s1, ($sp)
	addi $sp, $sp, 4
	
	# return to last place in program
	jr $ra

	# SAMPLE RUNS
	# hi 3
	# 2 words 4 characters
	# bruh bruh
	# 2 words 9 characters
	# functions are cool
	# 3 words 18 characters