.section .rodata
fmt_first:
	.asciz "%d"        # format for printing first number (no leading space)
fmt_next:
	.asciz " %d"       # format for printing rest (space before number)

.text
.globl main


main:
	addi sp, sp, -96
	sd ra, 88(sp)
	sd s0, 80(sp)
	sd s1, 72(sp)
	sd s2, 64(sp)
	sd s3, 56(sp)
	sd s4, 48(sp)
	sd s5, 40(sp)
	sd s6, 32(sp)
	sd s7, 24(sp)
	sd s8, 16(sp)

	mv s0, a0                  # s0 = argc
	mv s1, a1                  # s1 = argv
	addi s2, s0, -1            # s2 = n (number of input elements)

	# initialize pointers to NULL (helps safe free later)
	li s3, 0                   # s3 = arr
	li s4, 0                   # s4 = result
	li s5, 0                   # s5 = stack

	li s8, 0                   # exit status = 0 (success)

	# If no numbers given → just print newline
	ble s2, zero, .Lprint_only_newline

	# Allocate memory for 3 arrays:
	# arr[] → input values
	# result[] → answers
	# stack[] → indices for monotonic stack
	slli t0, s2, 2             # bytes = n * 4 (int size)

	mv a0, t0
	call malloc
	mv s3, a0
	beqz s3, .Lalloc_fail      # if allocation fails → exit

	mv a0, t0
	call malloc
	mv s4, a0
	beqz s4, .Lalloc_fail

	mv a0, t0
	call malloc
	mv s5, a0
	beqz s5, .Lalloc_fail

	# Convert argv strings → integers and store in arr[]
	li s7, 0                   # i = 0
.Lparse_loop:
	bge s7, s2, .Lcompute

	addi t0, s7, 1             # argv index = i + 1
	slli t0, t0, 3             # each argv entry is 8 bytes (pointer)
	add t0, s1, t0
	ld a0, 0(t0)               # load argv[i+1]
	call atoi                  # convert string → int

	slli t1, s7, 2
	add t1, s3, t1
	sw a0, 0(t1)               # arr[i] = value

	addi s7, s7, 1
	j .Lparse_loop


	# Main logic: Next Greater Element using monotonic stack
	# Stack stores indices whose values are in decreasing order

.Lcompute:
	li s6, -1                  # s6 = top of stack (-1 = empty)
	addi s7, s2, -1            # start from rightmost element (i = n-1)

.Louter_loop:
	blt s7, zero, .Lprint_result

	# current value = arr[i]
	slli t0, s7, 2
	add t0, s3, t0
	lw t1, 0(t0)

	# Pop all elements ≤ current (they can't be next greater)
.Lpop_loop:
	blt s6, zero, .Lset_answer

	slli t2, s6, 2
	add t2, s5, t2
	lw t3, 0(t2)               # index from stack

	slli t4, t3, 2
	add t4, s3, t4
	lw t5, 0(t4)               # value at that index

	# Stop if we found strictly greater element
	bgt t5, t1, .Lset_answer

	# Otherwise remove it (it’s useless)
	addi s6, s6, -1
	j .Lpop_loop


	# If stack not empty → top is answer
	# else → no greater element
.Lset_answer:
	slli t6, s7, 2
	add t6, s4, t6

	blt s6, zero, .Lstore_minus_one

	slli t2, s6, 2
	add t2, s5, t2
	lw t3, 0(t2)               # index of next greater
	sw t3, 0(t6)
	j .Lpush_i

.Lstore_minus_one:
	li t3, -1
	sw t3, 0(t6)

	# Push current index into stack
.Lpush_i:
	addi s6, s6, 1
	slli t2, s6, 2
	add t2, s5, t2
	sw s7, 0(t2)

	addi s7, s7, -1
	j .Louter_loop


	# Print results (space-separated, no trailing space)
.Lprint_result:
	la a0, fmt_first
	lw a1, 0(s4)
	call printf

	li s7, 1
.Lprint_loop:
	bge s7, s2, .Lprint_newline

	slli t0, s7, 2
	add t0, s4, t0
	lw a1, 0(t0)

	la a0, fmt_next
	call printf

	addi s7, s7, 1
	j .Lprint_loop

.Lprint_newline:
	li a0, 10                 # '\n'
	call putchar
	li s8, 0
	j .Lcleanup


# Case when no input elements
.Lprint_only_newline:
	li a0, 10
	call putchar
	li s8, 0
	j .Lcleanup


# Allocation failure → return non-zero exit code
.Lalloc_fail:
	li s8, 1


# Free memory safely (only if allocated)
.Lcleanup:
	beqz s5, .Lfree_result
	mv a0, s5
	call free

.Lfree_result:
	beqz s4, .Lfree_arr
	mv a0, s4
	call free

.Lfree_arr:
	beqz s3, .Ldone
	mv a0, s3
	call free


# Restore registers and return
.Ldone:
	mv a0, s8
	ld s8, 16(sp)
	ld s7, 24(sp)
	ld s6, 32(sp)
	ld s5, 40(sp)
	ld s4, 48(sp)
	ld s3, 56(sp)
	ld s2, 64(sp)
	ld s1, 72(sp)
	ld s0, 80(sp)
	ld ra, 88(sp)
	addi sp, sp, 96
	ret
