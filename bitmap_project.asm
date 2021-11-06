# Bitmap Project - Mandelbrot Fractal Viewer
# Charles Averill
# 2340.003
# Oct 21, 2021

# colors
.eqv ERASE 0x00000000

.data

# Offset static data by 2^15 bits to ensure it doesn't interfere with the bitmap (Q67 Piazza)
.space			32768

pixel_color:	.word	0

# Standard Mandelbrot domain (range is derived from this for prettiness)
X_MIN:			.float -2.5
X_MAX:			.float	1.0

# Offsets
X_OFFSET:		.float	0.0
Y_OFFSET:		.float	0.0

# Numerical constants
LN_2:			.float	0.69314718	# ln(2)

NEG_ONE:		.float	-1.0

ZERO:			.float	0.0

ONE:			.float	1.0
TWO:			.float	2.0

C_ZOOM_SCALE:	.float	1.1

C_8:			.float	8.0
C_64:			.float	64.0
C_255:			.float	255

# Display constants
HUE_COEFF:		.float .9
BRIGHT_COEFF:	.float	.9

# Height, Width of screen in pixels for Mandelbrot computation
RESOLUTION:		.float	32.0
.eqv	RESOLUTION_INT	32

# How many times to loop over a pixel while calculating its color, think of it like complex resolution
N_MAX_ITER:		.float	100.0

# Flag to play sound when render pixel or not
USE_MUSIC:		.word	0

newline:		.asciiz "\n"

# Macro to draw a pixel
.macro draw_pixel (%X, %Y, %color)
	mul		$t9, %Y, RESOLUTION_INT	# y * WIDTH
	add		$t9, $t9, %X			# add X
	sll		$t9, $t9, 2				# multiply by 4 to get word offset
	add		$t9, $t9, $gp			# add to base address
	sw		%color, ($t9)			# store color at memory location
	
	.end_macro

# Macro to calculate the absolute value of a complex number P = (Px + i * Py)
# This value is defined as the distance from the complex origin to P, or
# abs(P) = sqrt(Px^2 + Py^2)
.macro complex_absolute (%rd, %Px, %Py, %rTemp)
	# rd - Destination register
	# Px, Py - Real and complex parts
	# rTemp - Valid temporary register to use
	mul.s	%rd, %Px, %Px	# rTemp = Px^2
	mul.s	%rTemp, %Py, %Py	# rTemp = Py^2
	add.s	%rd, %rd, %rTemp	# rd += Py^2
	
	sqrt.s	%rd, %rd				# rd = sqrt(rd)
	.end_macro

# Macro to calculate *an approximation* of ln(rs)
# I'm using the following approximation:
#     ln(x) ~= a * x^{1 / a} - a
# where a is a large number (64 in our case)
# Instead of approximating an exponent, I will be taking 6 concurrent square roots, so
# 	  ln(x) ~= 64 * sqrt(sqrt(sqrt(sqrt(sqrt(sqrt(x)))))) - 64
# This is surprisingly accurate!
.macro natural_log (%rd, %rs, %rTemp1)
	lwc1	%rTemp1, C_64
	sqrt.s	%rd, %rs
	sqrt.s	%rd, %rd
	sqrt.s	%rd, %rd
	sqrt.s	%rd, %rd
	sqrt.s	%rd, %rd
	sqrt.s	%rd, %rd			# rd = x^{1/64}
	mul.s	%rd, %rd, %rTemp1	# rd *= 64
	sub.s	%rd, %rd, %rTemp1	# rd -= 64
	.end_macro

# Macro to calculate log_2(x)
# I've already approximated ln(x), so by base rule:
# log_2(x) = ln(x) / ln(2)
# LN_2 will be used as a precomputed value for speed in this case
.macro log_2 (%rd, %rs, %rTemp1)
	natural_log	(%rd, %rs, %rTemp1)
	lwc1	%rTemp1, LN_2
	div.s	%rd, %rd, %rTemp1	# rd = ln(x) / ln(2)
	.end_macro

.text
main:
	# Mandelbrot set equation: z_{n + 1} = (z_n)^2 + c
	# Implementation based on https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set#Continuous_(smooth)_coloring

	# --- Start by resetting the view --- #
	jal black_out_screen
	# --- PERSISTENT REGISTERS --- #
	# These are variables that always need to be available, or are constants we don't want to load over and over
	# Registers f22 - f26 are temporary registers and will not hold any significant values
	# f29 - ONE
	# f30 - ZERO
	lwc1	$f0, RESOLUTION
	lwc1	$f1, X_MIN
	lwc1	$f2, X_MAX
	# Y_MIN, calculate below
	# Y_MAX, calculate below
	lwc1	$f5, ZERO
	lwc1	$f6, ZERO
	lwc1	$f7, N_MAX_ITER
	lwc1	$f8, HUE_COEFF
	lwc1	$f9, BRIGHT_COEFF
	
	# Constants
	lwc1	$f27, X_OFFSET
	lwc1	$f28, Y_OFFSET
	lwc1	$f29, ONE
	lwc1	$f30, ZERO
	
	# --- Calculate Y bounds --- #
	# Y_MAX = (X_MAX - X_MIN) / 2
	# Y_MIN = -1 * Y_MAX
	lwc1	$f22, TWO
	sub.s	$f4, $f2, $f1
	div.s	$f4, $f4, $f22	# Y_MAX
	
	lwc1	$f22, NEG_ONE
	mul.s	$f3, $f4, $f22	# Y_MIN
	
	lwc1	$f10, ZERO		# x
	li		$t0, 0			# int(x)
	lwc1	$f11, ZERO		# y
	li		$t1, 0			# int(y)
main_loop:
	# Point C represents the current pixel scaled by screen size, and modified by X and Y offsets
	# Cx, Cy = f12, f13
	
	# Cx = X_MIN + (X_MAX - X_MIN) * (x + X_OFFSET) / RESOLUTION
	sub.s	$f12, $f2, $f1			# Cx = X_MAX - X_MIN
	add.s	$f25, $f10, $f27		# temp = x + X_OFFSET
	mul.s	$f12, $f12, $f25		# Cx *= (x + X_OFFSET)
	div.s	$f12, $f12, $f0			# Cx /= RESOLUTION
	add.s	$f12, $f12, $f1			# Cx += X_MIN
	
	# Cy = Y_MIN + (Y_MAX - Y_MIN) * (y - Y_OFFSET) / RESOLUTION
	sub.s	$f13, $f4, $f3			# Cy = Y_MAX - Y_MIN
	sub.s	$f25, $f11, $f28		# temp = y + Y_OFFSET
	mul.s	$f13, $f13, $f25		# Cy *= (y + Y_OFFSET)
	div.s	$f13, $f13, $f0			# Cy /= RESOLUTION
	add.s	$f13, $f13, $f3			# Cy += Y_MIN
	
	# Point Z represents a point in the complex plane that we will test for inclusion in the Mandelbrot set
	# Z = (0, 0)
	lwc1	$f14, ZERO
	lwc1	$f15, ZERO
	
	# --- Determine if Z is in the Mandelbrot set by repeated squaring --- #
	# i = f22
	lwc1	$f22, ZERO
point_loop:
	# Z = Z^2 + C
	# newZX, newZY = f23, f24
	# newZX = ZX^2 - ZY^2
	mul.s	$f23, $f14, $f14
	mul.s	$f24, $f15, $f15
	sub.s	$f23, $f23, $f24
	
	# newZY = 2 * ZX * ZY
	add.s	$f24, $f14, $f14
	mul.s	$f24, $f24, $f15
	
	# Zx, Zy = newZX + Cx, newZY + Cy
	add.s	$f14, $f23, $f12
	add.s	$f15, $f24, $f13
	
	# abs(Z) = f16
	# We will use this value later, so reserve the register
	complex_absolute	($f16, $f14, $f15, $f23)
	
	# Break if N_MAX_ITER < abs(Z)
	c.lt.s	$f7, $f16
	bc1t	pick_color
point_loop_increment:
	add.s	$f22, $f22, $f29		# i++
	c.lt.s	$f22, $f7				# Is i < N_MAX_ITER?
	bc1t	point_loop
pick_color:
	# If we broke the previous loop, the pixel will be drawn (otherwise it is a black pixel)
	add.s	$f22, $f22, $f29		# i += 1
	c.lt.s	$f22, $f7
	bc1f	main_loop_increment
	
	# --- Pick the color of the pixel --- #
	# R, G, B = f19, f20, f21
	# Part of picking the color is modifying abs(Z) to encode our RGB data as K
	# K = ln(i + HUE_COEFF - log_2(ln(abs(Z)))) / BRIGHTNESS
	# K = f17
	natural_log		($f17, $f16, $f23)	# K = ln(abs(Z))
	log_2			($f17, $f17, $f23)	# K = log_2(K)
	sub.s	$f17, $f8, $f17			# K = HUE_COEFF - K
	add.s	$f17, $f17, $f22		# K += i
	natural_log		($f17, $f17, $f23)	# K = ln(K)
	div.s	$f17, $f17, $f9			# K /= BRIGHTNESS
	
	# If K is small, we want a blue pixel, otherwise a sepia pixel
	c.lt.s	$f17, $f29				# Is K < 1?
	bc1t	blue
	
	# Pixel will be sepia
	# Adjust K for an opposite hue
	lwc1	$f26, TWO
	sub.s	$f17, $f26, $f17		# K = 2 - K
	
	# G and B both are composed of at least K^3, so compute that first
	mul.s	$f21, $f17, $f17
	mul.s	$f21, $f21, $f17		# temp = K^3
	
	# R = K
	mov.s	$f19, $f17
	# G = sqrt(K^3)
	sqrt.s	$f20, $f21
	# B = K^3, already done
	
	j draw_mandelbrot_pixel
blue:
	# Pixel will be blue
	# R and G both are composed of at least K^3, so compute that first
	mul.s	$f25, $f17, $f17
	mul.s	$f25, $f25, $f17		# temp = K^3
	
	# R = K^4
	mul.s	$f19, $f25, $f17
	# G = sqrt(K^5)
	mul.s	$f20, $f25, $f17
	mul.s	$f20, $f25, $f17
	sqrt.s	$f20, $f20
	# B = K
	mov.s	$f21, $f17
draw_mandelbrot_pixel:
	# We now have the RGB of our current pixel. However they are currently between 0 and 1
	# We will scale by 255 to get our final value
	lwc1	$f25, C_255				# f10 = 255
	mul.s	$f19, $f19, $f25		# r *= 255
	mul.s	$f20, $f20, $f25		# g *= 255
	mul.s	$f21, $f21, $f25		# b *= 255
	
	# Now we need to move everything back into the normal arithmetic registers so we can combine them into our overall color for this pixel
	# Convert to ints
	cvt.w.s	$f19, $f19
	cvt.w.s	$f20, $f20
	cvt.w.s	$f21, $f21
	# Move
	mfc1	$t5, $f19	# t5 = int(r)
	mfc1	$t6, $f20	# t6 = int(g)
	mfc1	$t7, $f21	# t7 = int(b)
	
	# Our color is stored as 0x00RRGGBB, so we must bit shift R and G to be in the correct location before we combine them
	sll		$t5, $t5, 4
	sll		$t6, $t6, 2
	
	# Now, or them together into t4 - our resulting color for this pixel
	li		$t4, 0
	or		$t4, $t4, $t5
	or		$t4, $t4, $t6
	or		$t4, $t4, $t7
	
	# At last, draw the pixel (x, y)
	draw_pixel ($t0, $t1, $t4)
	
	# We will also play a noise with the MIDI out synchronous syscall if the user hits the m key
	lw		$t8, USE_MUSIC
	beq		$t8, 0, draw_mirror_pixel
play_sound:
	# Pitch = K * 128
	mul.s	$f25, $f17, $f25
	div.s	$f25, $f25, $f26
	cvt.w.s	$f25, $f25
	mfc1	$a0, $f25
	# Duration = 20ms
	li		$a1, 20
	# Instrument = Piano 0
	li		$a2, 0
	# Volume = 127
	li		$a3, 127
	
	li		$v0, 33
	syscall
draw_mirror_pixel:
	# If Y_OFFSET is 0, the graph will be symmetric about Y = 0, so draw (x, RESOLUTION - y)
	c.eq.s	$f28, $f30
	bc1f	main_loop_increment
	
	addi	$t2, $zero, RESOLUTION_INT
	sub		$t2, $t2, $t1
	draw_pixel ($t0, $t2, $t4)
main_loop_increment:
	add.s	$f10, $f10, $f29	# x++
	addi	$t0, $t0, 1
	c.lt.s	$f10, $f0
	bc1t	main_loop
	
	lwc1	$f10, ZERO			# x = 0
	li		$t0, 0
	add.s	$f11, $f11, $f29	# y++
	addi	$t1, $t1, 1

	# If Y_OFFSET == 0, the set is symmetric about y = 0, so y goes from 0 to RESOLUTION / 2
	c.eq.s	$f28, $f30
	bc1t	half_resolution
	
	c.lt.s	$f11, $f0
	bc1t	main_loop
	
half_resolution:
	add.s	$f25, $f11, $f11
	c.le.s	$f25, $f0
	bc1t	main_loop
	
	# Rendering takes a while, so we want to let the user know when it's done
	# Do this by flipping the top left pixel between black and white every few frames
	# t4 = timer
	# t5 = pixel_is_white
	li		$t4, 30000
	li		$t5, 0
input_loop:
	# Increment timer
	addi	$t4, $t4, 1
	# Only flip the pixel if we've iterated 4000 frames
	blt		$t4, 30000, skip_flip
	
	# Reset timer
	li		$t4, 0
	
	# If the pixel is white, draw a black one
	beq		$t5, 1, draw_black_pixel
	# Draw the pixel, X and Y are always 0
	li		$t0, 0x00FFFFFF
	draw_pixel	($zero, $zero, $t0)
	li		$t5, 1
	j skip_flip
draw_black_pixel:
	draw_pixel	($zero, $zero, $zero)
	li		$t5, 0
skip_flip:
	# check for input
	lw $t0, 0xffff0000  	#t1 holds if input available
    beq $t0, 0, input_loop	#If no input, keep displaying
    
    lwc1	$f24, TWO
    lwc1	$f25, C_8
    lwc1	$f26, C_ZOOM_SCALE
    # When zooming, update bounds and Y offset by zoom_update = (XMAX - XMIN) / (Zoom Scale * 2)
	sub.s	$f23, $f2, $f1
	div.s	$f23, $f23, $f26
	div.s	$f23, $f23, $f24
    
    # process input
	lw 	$s2, 0xffff0004
	beq	$s2, 32, exit		# input space
	# Movement
	beq	$s2, 119, up 		# input w
	beq	$s2, 115, down 		# input s
	beq	$s2, 97, left  		# input a
	beq	$s2, 100, right		# input d
	# Zoom
	beq	$s2, 122, zoom_in	# input z
	beq	$s2, 120, zoom_out
	# Color
	beq	$s2, 111, hue_up		# input o
	beq $s2, 108, hue_down		# input l
	beq	$s2, 105, bright_up		# input i
	beq	$s2, 107, bright_down	# input k
	# Sound
	beq	$s2, 109, toggle_sound	# input m
	# invalid input, ignore
	j	input_loop
	
	# process valid input
up:
	# Y_OFFSET += 8 * ZOOM_SCALE
	mul.s	$f26, $f26, $f25
	add.s	$f28, $f28, $f26
	div.s	$f26, $f26, $f25
	j save
down:
	# Y_OFFSET -= 8 * ZOOM_SCALE
	mul.s	$f26, $f26, $f25
	sub.s	$f28, $f28, $f26
	div.s	$f26, $f26, $f25
	j save
left:
	# X_MIN -= ZOOM_SCALE
	# X_MAX -= ZOOM_SCALE
	sub.s	$f1, $f1, $f23
	sub.s	$f2, $f2, $f23
	j save	
right:
	# X_MIN += ZOOM_SCALE
	# X_MAX += ZOOM_SCALE
	add.s	$f1, $f1, $f23
	add.s	$f2, $f2, $f23
	j save
zoom_in:
	# X_MIN += zoom_update
	# X_MAX -= zoom_update
	add.s	$f1, $f1, $f23
	sub.s	$f2, $f2, $f23
	# Y_OFFSET += zoom_update
	# add.s	$f28, $f28, $f23
	j save
zoom_out:
	# zoom_update *= 2
	mul.s	$f23, $f23, $f24
	# X_MIN -= zoom_update
	# X_MAX += zoom_update
	sub.s	$f1, $f1, $f23
	add.s	$f2, $f2, $f23
	# Y_OFFSET -= zoom_update
	# sub.s	$f28, $f28, $f23
	j save
hue_up:
	# HUE_COEFF *= 2
	mul.s	$f8, $f8, $f24
	j save
hue_down:
	# HUE_COEFF /= 2
	div.s	$f8, $f8, $f24
	j save
bright_down:
	# BRIGHT_COEFF *= 2
	mul.s	$f9, $f9, $f24
	j save
bright_up:
	# BRIGHT_COEFF /= 2
	div.s	$f9, $f9, $f24
	j save
toggle_sound:
	lw		$t8, USE_MUSIC
	not		$t8, $t8
	j save
save:
	swc1	$f1, X_MIN
	swc1	$f2, X_MAX
	swc1	$f8, HUE_COEFF
	swc1	$f9, BRIGHT_COEFF
	swc1	$f26, C_ZOOM_SCALE
	swc1	$f27, X_OFFSET
	swc1	$f28, Y_OFFSET
	sw		$t8, USE_MUSIC
	j main
exit:	
	li	$v0, 10
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
	# It is faster to store multiple times at different offsets than to
	# store at the current offset. This comes with diminishing returns,
	# I stopped noticing a difference at 4 saves per iteration
	mul		$t9, $a1, RESOLUTION_INT	# y * WIDTH
	add		$t9, $t9, $a0			# add X
	sll		$t9, $t9, 2				# multiply by 4 to get word offset
	add		$t9, $t9, $gp			# add to base address
	
	sw		$a2, ($t9)			# store color at memory
	sw		$a2, 4($t9)			# store color at memory
	sw		$a2, 8($t9)			# store color at memory
	sw		$a2, 12($t9)			# store color at memory
	
	# Increment X
	addi $a0, $a0, 4
	blt $a0, RESOLUTION_INT, black_out_loop
	
	# Increment Y, reset X
	li $a0, 0
	addi $a1, $a1, 1
	blt $a1, RESOLUTION_INT, black_out_loop
	
	jr $ra
