# Homework 4
# Charles Averill
# 2340.003
# Oct 15, 2021

# Width of screen in pixels
.eqv WIDTH 32
# Height of screen in pixels
.eqv HEIGHT 32

# colors
.eqv ERASE 0x00000000

.eqv BROWN 0x0060463B
.eqv BLACK 0x002E3138
.eqv GREEN 0x00A9E5BB
.eqv YELLW 0x00FCF6B1
.eqv ORANG 0x00F7B32B
.eqv PINK  0x00FD3E81
.eqv PURPL 0x00BC96E6

.data

# Macro to draw a pixel
.macro draw_pixel (%X, %Y, %color, %delay)
	mul	$t9, %Y, WIDTH	# y * WIDTH
	add	$t9, $t9, %X	# add X
	mul	$t9, $t9, 4		# multiply by 4 to get word offset
	add	$t9, $t9, $gp	# add to base address
	sw	%color, ($t9)	# store color at memory location
	
	# Preserve a0
	move $t9, $a0
	
	# Sleep between draw
	li $v0, 32
	li $a0, %delay
	syscall
	
	# Restore a0
	move $a0, $t9
	
	.end_macro

# Colors array
colors:	.word BROWN, BLACK, GREEN, YELLW, ORANG, PINK, PURPL

.text
main:
	# Set up starting position
	addi 	$s0, $0, WIDTH    # s0 = X = WIDTH/2
	sra 	$s0, $s0, 1
	addi 	$s1, $0, HEIGHT   # s1 = Y = HEIGHT/2
	sra 	$s1, $s1, 1
	addi 	$s2, $0, PINK
loop:
	# Draw top side
	# t0 - loop counter
	# t1 - box size
	# t2 - color counter
	# t3 - address of colors array
	# t4 - address of colors[i]
	li $t0, 0
	li $t1, 7
	li $t2, 0
	la $t3, colors
	la $t4, colors
top_bottom_loop:		# Draw top and bottom sides
	# Draw top pixel
	add $a0, $s0, $t0	# X = centerX + counter
	move $a1, $s1		# Y = centerY
	lw $a2, 0($t4)		# Color = colors[i]
	draw_pixel ($a0, $a1, $a2, 5)
	
	# Draw bottom pixel
	add $a0, $s0, $t1	# X = centerX + boxSize - counter
	sub $a0, $a0, $t0
	add $a1, $s1, $t1	# Y = centerY + boxSize
	draw_pixel ($a0, $a1, $a2, 5)
	
	# Increment color counter
	addi $t2, $t2, 1
	sll $t5, $t2, 2
	add $t4, $t3, $t5
	
	# Loop increment
	addi $t0, $t0, 1
	bne $t0, $t1, top_bottom_loop
	
	# Reset counters and addresses
	li $t0, 0
	li $t2, 0
	la $t3, colors
	la $t4, colors

left_right_loop:		# Draw left and right sides
	# Draw left pixel
	move $a0, $s0		# X = centerX
	add $a1, $s1, $t1	# Y = centerY + boxSize - counter
	sub $a1, $a1, $t0
	lw $a2, 0($t4)		# Color = colors[i]
	draw_pixel ($a0, $a1, $a2, 5)
	
	# Draw right pixel
	add $a0, $s0, $t1	# X = centerX + boxSize
	add $a1, $s1, $t0	# Y = centerY + counter
	draw_pixel ($a0, $a1, $a2, 5)
	
	# Increment color counter
	addi $t2, $t2, 1
	sll $t5, $t2, 2
	add $t4, $t3, $t5
	
	# Loop increment
	addi $t0, $t0, 1
	bne $t0, $t1, left_right_loop
	
input:
	# check for input
	lw $t0, 0xffff0000  	#t1 holds if input available
    	beq $t0, 0, loop	#If no input, keep displaying
	
	# process input
	lw 	$s2, 0xffff0004
	beq	$s2, 32, exit	# input space
	beq	$s2, 119, up 	# input w
	beq	$s2, 115, down 	# input s
	beq	$s2, 97, left  	# input a
	beq	$s2, 100, right	# input d
	# invalid input, ignore
	j	loop
	
	# process valid input
up:
	# Decrement Y
	addi $s1, $s1, -1
	# Black out screen, draw
	jal black_out_screen
	j loop
down:
	# Increment Y
	addi $s1, $s1, 1
	# Black out screen, draw
	jal black_out_screen
	j loop
left:
	# Decrement X
	addi $s0, $s0, -1
	# Black out screen, draw
	jal black_out_screen
	j loop	
right:
	# Increment X
	addi $s0, $s0, 1
	# Black out screen, draw
	jal black_out_screen
	j loop	
		
exit:	li	$v0, 10
	syscall

# Function to erase entire screen
black_out_screen:
	# a0 = X
	# a1 = Y
	# a2 = Color
	li $a0, 0
	li $a1, 0
	li $a2, ERASE
	
black_out_loop:
	# Black out pixel
	draw_pixel ($a0, $a1, $a2, 0)
	
	# Increment X
	addi $a0, $a0, 1
	blt $a0, WIDTH, black_out_loop
	
	# Increment Y, reset X
	li $a0, 0
	addi $a1, $a1, 1
	blt $a1, HEIGHT, black_out_loop
	
	jr $ra
