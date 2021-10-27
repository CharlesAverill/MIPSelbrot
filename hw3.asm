# Homework 3
# Charles Averill
# 2340.003
# Oct 1, 2021

.data
name_prompt:	.asciiz "What is your name? "
username:		.space 64

height_prompt:	.asciiz "Please enter your height in inches: "
weight_prompt:	.asciiz "Please enter your weight in pounds: "

your_bmi:		.asciiz "Your BMI is: "

underweight:	.asciiz "\nThis is considered underweight\n"
normal_weight:	.asciiz "\nThis is a normal weight\n"
overweight:		.asciiz "\nThis is considered overweight\n"
obese:			.asciiz "\nThis is considered obese\n"

low_bmi:		.double 18.5
mid_bmi:		.double 25.0
hi_bmi:			.double 30.0

.text
main:
	# t0, f0 - height
	# t1, f2 - weight
	# t2, f4 - bmi
	# f6, f8, f10 - low, mid, hi BMI values
	
	# Load bmi values
	ldc1 $f6, low_bmi
	ldc1 $f8, mid_bmi
	ldc1 $f10, hi_bmi
	
	# Print name_prompt
	li $v0, 4
	la $a0, name_prompt
	syscall
	
	# Read name from user
	li $v0, 8
	la $a0, username
	li $a1, 64
	syscall
	
	# Print height_prompt
	li $v0, 4
	la $a0, height_prompt
	syscall
	
	# Read height from user
	li $v0, 5
	syscall
	move $t0, $v0
	
	# Print weight_prompt
	li $v0, 4
	la $a0, weight_prompt
	syscall
	
	# Read weight from user
	li $v0, 5
	syscall
	move $t1, $v0
	
	# Do integer multiplication for speed boost
	
	# weight *= 703
	mulu $t1, $t1, 703 # Unsigned inline multiplication removes need for MFHI
	
	# height *= height
	mulu $t0, $t0, $t0
	
	# Move height and weight to CP1 for division
	mtc1.d $t0, $f0
	mtc1.d $t1, $f2
	
	# Convert height and width to doubles
	cvt.d.w $f0, $f0
	cvt.d.w $f2, $f2
	
	# bmi = weight / height
	div.d $f4, $f2, $f0
	
	# Print username
	li $v0, 4
	la $a0, username
	syscall
	
	# Print bmi statement
	li $v0, 4
	la $a0, your_bmi
	syscall
	
	# Print bmi
	li $v0, 3
	mov.d $f12, $f4
	syscall
	
	c.lt.d $f4, $f6 # Condition Flag 0 = bmi < low_bmi
	bc1t print_low_bmi
	
	c.lt.d $f4, $f8 # Condition Flag 0 = bmi < mid_bmi
	bc1t print_med_bmi
	
	c.lt.d $f4, $f10 # Condition Flag 0 = bmi < hi_bmi
	bc1t print_hi_bmi
	
print_obese:
	# Print obese statement
	li $v0, 4
	la $a0, obese
	syscall
	j exit
	
print_hi_bmi:
	# Print overweight statement
	li $v0, 4
	la $a0, overweight
	syscall
	j exit

print_med_bmi:
	# Print average weight statement
	li $v0, 4
	la $a0, normal_weight
	syscall
	j exit

print_low_bmi:
	# Print overweight statement
	li $v0, 4
	la $a0, underweight
	syscall
	
exit:
	li $v0, 10
	syscall
	
	# SAMPLE RUNS
	# What is your name? charles
	# Please enter your height in inches: 72
	# Please enter your weight in pounds: 180
	# charles
	# Your BMI is: 24.40972222222222
	# This is a normal weight
	
	# What is your name? tiny
	# Please enter your height in inches: 18
	# Please enter your weight in pounds: 15
	# tiny
	# Your BMI is: 32.5462962962963
	# This considered obese
	
	# What is your name? goliath
	# Please enter your height in inches: 720
	# Please enter your weight in pounds: 7000
	# goliath
	# Your BMI is: 9.49266975308642
	# This is considered underweight