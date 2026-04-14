.section .rodata
input_file:
	.asciz "input.txt"     # file name to read from
yes_str:
	.asciz "Yes"           # output if palindrome
no_str:
	.asciz "No"            # output if not palindrome

.text
.globl main

# int main(void)

main:
	addi sp, sp, -64
	sd ra, 56(sp)
	sd s0, 48(sp)
	sd s1, 40(sp)
	sd s2, 32(sp)
	sd s3, 24(sp)
	sd s4, 16(sp)

	# Open file in read-only mode
	la a0, input_file          # filename
	li a1, 0                   # O_RDONLY
	call open
	mv s0, a0                  # s0 = file descriptor

	# If open fails → treat as "No"
	blt s0, zero, .Lprint_no

	# Find file length using lseek
	mv a0, s0
	li a1, 0
	li a2, 2                   # SEEK_END
	call lseek
	mv s3, a0                  # s3 = file length

	# If lseek fails → print No
	blt s3, zero, .Lprint_no_close

	# If length ≤ 1 → automatically palindrome
	li t0, 1
	ble s3, t0, .Lprint_yes_close

	# Initialize two pointers:
	# left = 0, right = length - 1
	li s1, 0
	addi s2, s3, -1

.Lcheck_loop:
	# Stop when pointers meet or cross → palindrome
	bge s1, s2, .Lprint_yes_close

	# ---- Read left character ----
	mv a0, s0
	mv a1, s1
	li a2, 0                   # SEEK_SET
	call lseek

	# If lseek fails → treat as No
	blt a0, zero, .Lprint_no_close

	mv a0, s0
	addi a1, sp, 0             # store left char at sp[0]
	li a2, 1
	call read

	# If read fails → treat as No
	li t0, 1
	bne a0, t0, .Lprint_no_close

	# ---- Read right character ----
	mv a0, s0
	mv a1, s2
	li a2, 0                   # SEEK_SET
	call lseek

	blt a0, zero, .Lprint_no_close

	mv a0, s0
	addi a1, sp, 1             # store right char at sp[1]
	li a2, 1
	call read

	li t0, 1
	bne a0, t0, .Lprint_no_close

	# Compare left and right characters
	lbu t1, 0(sp)
	lbu t2, 1(sp)

	# If mismatch → not palindrome
	bne t1, t2, .Lprint_no_close

	# Move pointers inward
	addi s1, s1, 1
	addi s2, s2, -1

	j .Lcheck_loop


.Lprint_yes_close:
	# Close file before printing
	mv a0, s0
	call close

	# Print "Yes"
	la a0, yes_str
	call puts

	li a0, 0
	j .Ldone


.Lprint_no_close:
	# Close file before printing No
	mv a0, s0
	call close

.Lprint_no:
	# Print "No"
	la a0, no_str
	call puts

	li a0, 0


.Ldone:
	# Restore registers and return
	ld s4, 16(sp)
	ld s3, 24(sp)
	ld s2, 32(sp)
	ld s1, 40(sp)
	ld s0, 48(sp)
	ld ra, 56(sp)
	addi sp, sp, 64
	ret