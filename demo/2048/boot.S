.text
.set noreorder
.set mips32

.extern bootup
.extern exception
.global entry
.global handler


.align 4
.ent entry

entry:
	nop
	nop
	li $sp, 0x000FF000
	li $gp, 0x000FF000
	li $t0, 0xFFEEDDCC
	sw $t0, 0($sp)
	sw $t0, 4($sp)
  set_handler:
	la $t0, handler
	mtc0 $t0, $3
  realloc_data:
	la $t0, _realloc
	la $t1, _data
	la $t2, _edata
  realloc_data_loop:
	slt $t3, $t1, $t2
	beq $t3, $0, realloc_bss
	nop
	lw $t4, 0($t0)
	nop
	sw $t4, 0($t1)
	nop
	addi $t0, $t0, 4
	addi $t1, $t1, 4
	b realloc_data_loop
	nop
  realloc_bss:
	la $t1, _bss
	la $t2, _ebss
  realloc_bss_loop:
	slt $t3, $t1, $t2
	beq $t3, $0, realloc_done
	nop
	sw $0, 0($t1)
	nop
	addi $t1, $t1, 4
	b realloc_bss_loop
	nop
  realloc_done:
	jal bootup
	nop
  dead_loop:
	j dead_loop
	nop

.end entry
.size entry, .-entry



.align 4
.ent handler

handler:
	addiu $sp, $sp, -140
	sw $1, 132($sp)
	sw $2, 128($sp)
	sw $3, 124($sp)
	sw $4, 120($sp)
	sw $5, 116($sp)
	sw $6, 112($sp)
	sw $7, 108($sp)
	sw $8, 104($sp)
	sw $9, 100($sp)
	sw $10, 96($sp)
	sw $11, 92($sp)
	sw $12, 88($sp)
	sw $13, 84($sp)
	sw $14, 80($sp)
	sw $15, 76($sp)
	sw $16, 72($sp)
	sw $17, 68($sp)
	sw $18, 64($sp)
	sw $19, 60($sp)
	sw $20, 56($sp)
	sw $21, 52($sp)
	sw $22, 48($sp)
	sw $23, 44($sp)
	sw $24, 40($sp)
	sw $25, 36($sp)
	sw $26, 32($sp)
	sw $27, 28($sp)
	sw $28, 24($sp)
	sw $29, 20($sp)
	sw $30, 16($sp)
	sw $31, 12($sp)
	mfc0 $t0, $1
	sw $t0, 8($sp)
	mfc0 $t0, $2
	sw $t0, 4($sp)
	li $t0, 0x01234567
	sw $t0, 136($sp)
	li $t0, 0xFEDCBA98
	sw $t0, 0($sp)
	jal exception
	nop
	lw $t0, 4($sp)
	mtc0 $t0, $2
	lw $t0, 8($sp)
	mtc0 $t0, $1
	lw $31, 12($sp)
	lw $30, 16($sp)
	lw $29, 20($sp)
	lw $28, 24($sp)
	lw $27, 28($sp)
	lw $26, 32($sp)
	lw $25, 36($sp)
	lw $24, 40($sp)
	lw $23, 44($sp)
	lw $22, 48($sp)
	lw $21, 52($sp)
	lw $20, 56($sp)
	lw $19, 60($sp)
	lw $18, 64($sp)
	lw $17, 68($sp)
	lw $16, 72($sp)
	lw $15, 76($sp)
	lw $14, 80($sp)
	lw $13, 84($sp)
	lw $12, 88($sp)
	lw $11, 92($sp)
	lw $10, 96($sp)
	lw $9, 100($sp)
	lw $8, 104($sp)
	lw $7, 108($sp)
	lw $6, 112($sp)
	lw $5, 116($sp)
	lw $4, 120($sp)
	lw $3, 124($sp)
	lw $2, 128($sp)
	lw $1, 132($sp)
	addiu $sp, $sp, 140
	eret
	nop
	nop
	
.end handler
.size handler, .-handler
