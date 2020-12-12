	.syntax unified

	.global mult_2_num
mult_2_num:
	stmfd	sp!, {fp, lr}
        add     fp, sp, #0      @ set our frame pointer

	mov	r2, #0	@ r2 will contain the product

@ if the second factor is negative do the two's component of the two factors
	cmp	r1, #0
	bge	loop
	mvn	r0, r0
	add	r0, r0, #1
	mvn	r1, r1
	add	r1, r1, #1

loop:
	cmp	r1, #0
	beq	endmult
	sub	r1, r1, #1	@ update counter
	add	r2, r2, r0	@ update partial product
	b	loop

endmult:
	mov	r0, r2		@ return the product
         
	ldmfd	sp!, {fp, lr}
	bx      lr              @ return