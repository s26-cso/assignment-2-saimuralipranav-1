.text

# struct Node* make_node(int val)
# Creates a new BST node with given value.
# Layout:
#   offset 0  -> int val
#   offset 8  -> left pointer
#   offset 16 -> right pointer
.globl make_node
make_node:
	addi sp, sp, -16
	sd ra, 8(sp)
	sd s0, 0(sp)

	mv s0, a0              # Save input val because malloc will overwrite a0.
	li a0, 24              # Allocate 24 bytes (struct size).
	call malloc

	beqz a0, .Lmake_done   # If malloc fails → return NULL.
	sw s0, 0(a0)           # node->val = val
	sd zero, 8(a0)         # node->left = NULL
	sd zero, 16(a0)        # node->right = NULL

.Lmake_done:
	ld s0, 0(sp)
	ld ra, 8(sp)
	addi sp, sp, 16
	ret


###############################################################################


# struct Node* insert(struct Node* root, int val)
# Inserts val into BST if not already present.
# Returns original root pointer.
.globl insert
insert:
	addi sp, sp, -24
	sd ra, 16(sp)
	sd s0, 8(sp)
	sd s1, 0(sp)

	mv s0, a0              # s0 = root (we preserve it to return later)
	mv s1, a1              # s1 = value to insert

	beqz s0, .Linsert_empty_tree   # If tree is empty → create root node.

	mv t0, s0              # t0 = current node (iterator)
.Linsert_walk:
	lw t1, 0(t0)           # t1 = current->val

	# Standard BST logic:
	# if val < current → go left
	# if val > current → go right
	blt s1, t1, .Linsert_left_branch
	bgt s1, t1, .Linsert_right_branch

	# Duplicate case → do not insert
	mv a0, s0
	j .Linsert_done

.Linsert_left_branch:
	ld t2, 8(t0)           # t2 = current->left
	beqz t2, .Linsert_here_left   # If NULL → insert here
	mv t0, t2              # Else keep traversing
	j .Linsert_walk

.Linsert_here_left:
	mv a0, s1
	call make_node         # Create new node
	sd a0, 8(t0)           # Attach as left child
	mv a0, s0              # Return original root
	j .Linsert_done

.Linsert_right_branch:
	ld t2, 16(t0)          # t2 = current->right
	beqz t2, .Linsert_here_right
	mv t0, t2
	j .Linsert_walk

.Linsert_here_right:
	mv a0, s1
	call make_node
	sd a0, 16(t0)          # Attach as right child
	mv a0, s0
	j .Linsert_done

.Linsert_empty_tree:
	mv a0, s1
	call make_node         # If tree empty → new node becomes root

.Linsert_done:
	ld s1, 0(sp)
	ld s0, 8(sp)
	ld ra, 16(sp)
	addi sp, sp, 24
	ret



###############################################################################


# struct Node* get(struct Node* root, int val)
# Searches BST and returns pointer to node with value.
# Returns NULL if not found.
.globl get
get:
	mv t0, a0              # t0 = current node
	mv t1, a1              # t1 = target value

.Lget_loop:
	beqz t0, .Lget_not_found   # If reached NULL → not found
	lw t2, 0(t0)           # t2 = current->val
	beq t2, t1, .Lget_found   # Found exact match

	# BST traversal decision
	blt t1, t2, .Lget_go_left

	ld t0, 16(t0)          # Go right
	j .Lget_loop

.Lget_go_left:
	ld t0, 8(t0)           # Go left
	j .Lget_loop

.Lget_found:
	mv a0, t0              # Return pointer to node
	ret

.Lget_not_found:
	li a0, 0               # Return NULL
	ret


#################################################################################


# int getAtMost(int val, struct Node* root)
# Finds largest value <= val in BST.
# If none exists → returns -1.
.globl getAtMost
getAtMost:
	mv t0, a1              # t0 = current node
	mv t1, a0              # t1 = query value

	li t2, 0               # found flag (0 = not found yet)
	li t3, -1              # best candidate so far

.Lgat_loop:
	beqz t0, .Lgat_done    # Stop when traversal ends
	lw t4, 0(t0)           # t4 = current->val

	# If current value > query → cannot be answer → go left
	bgt t4, t1, .Lgat_go_left

	# current value <= query → valid candidate
	# Store it and try to find a larger valid one
	mv t3, t4
	li t2, 1

	ld t0, 16(t0)          # Move right to get closer
	j .Lgat_loop

.Lgat_go_left:
	ld t0, 8(t0)           # Go left (values smaller)
	j .Lgat_loop

.Lgat_done:
	beqz t2, .Lgat_none    # If no candidate found

	mv a0, t3              # Return best candidate
	ret

.Lgat_none:
	li a0, -1              # No valid value exists
	ret
	