	.syntax unified

	.global main
main:
	stmfd	sp!, {r4, r5, r6, fp, lr}
        add     fp, sp, #12      @ set our frame pointer

	@ Ask for the first number
	ldr	r0, =message1
	bl	printf

	@ Read the first number and put it in r4
	ldr	r0, =inputPatt
	sub	sp, sp, #4
	mov	r1, sp
	bl	scanf
	ldr	r4, [sp],#4

	@ Ask for the second number
	ldr	r0, =message2
	bl	printf

	@ Read the second number and put it in r5
	ldr	r0, =inputPatt
	sub	sp, sp, #4
	mov	r1, sp
	bl	scanf
	ldr	r5, [sp],#4

	@ Multiply the two inputs
	mov	r0, r4
	mov	r1, r5
	bl 	mult_2_num
	mov	r6, r0

	@ Print the result
	ldr	r0, =message3
	mov	r1, r4
	mov	r2, r5
	mov	r3, r6
	bl	printf 

	mov	r0, #0 	@ return 0;
         
	ldmfd	sp!, {r4, r5, r6, fp, lr}
	
	bx      lr              @ return

message1:
	.asciz "Insert the first number:\n"
message2:
	.asciz "Insert the second number:\n"
message3:
	.asciz "Result: %d * %d = %d\n"
inputPatt:
	.asciz "%d"