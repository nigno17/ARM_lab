        .syntax unified         @ modern syntax

@ Constants for assembler
@ The following are defined in /usr/include/asm-generic/fcntl.h:
@ Note that the values are specified in octal.
        .equ    O_RDWR,00000002   @ open for read/write
        .equ    O_DSYNC,00010000  @ synchronize virtual memory
        .equ    __O_SYNC,04000000 @      programming changes with
        .equ    O_SYNC,__O_SYNC|O_DSYNC @ I/O memory
@ The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   @ page can be read
        .equ    PROT_WRITE,0x2  @ page can be written
        .equ    MAP_SHARED,0x01 @ share changes
@ Definition of parameters flags for open and mmap functions:
        .equ    O_FLAGS,O_RDWR|O_SYNC @ open file flags
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  @ Raspbian memory page
@ Definition of GPIO addresses:
        .equ    GPIO,0x3f200000   @ start of GPIO device
	.equ	GPIOSEL0, 0x0
	.equ	GPIOSEL2, 0x8
	.equ	GPSET0, 0x1C
	.equ	GPCLR0, 0x28
	.equ	GPLEV0, 0x34
	.equ	GPIO5, 0x20
	.equ	GPIO6, 0x40
	.equ	GPIO22, 0x400000
	.equ	GPIO26, 0x4000000
@ Others paramerters
	.equ	NUMPUSH, 10

@ The program
        .global main
main:
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, fp, lr}
        add     fp, sp, #24      @ set our frame pointer

@ Open /dev/gpiomem for read/write and syncing        
        ldr     r0, =#device      @ address of /dev/gpiomem
        ldr     r1, =#O_FLAGS    @ flags for accessing device
        bl      open
	mov	r4, r0		@ save the file descriptor in r4

@ Map the GPIO registers to a virtual memory location so we can access them
        ldr     r1, =#GPIO        @ address of GPIO
	stmfd	sp!, {r0, r1} @ push the /dev/gpiomem file descriptor and the address of GPIO
        mov     r0, #NO_PREF     @ let kernel pick memory
        mov     r1, #PAGE_SIZE   @ get 1 page of memory
        mov     r2, #PROT_RDWR   @ read/write this memory
        mov     r3, #MAP_SHARED  @ share with other processes
        bl      mmap
        mov     r5, r0          @ save virtual memory address in r5
	add	sp, sp, #8	@ pop parameters

@ Set GPIO 5, 6, 26 as outputs (GPIO22 is already initialized as input)
	ldr	r0, =#0x48000		@ set pin 15 and 18 to 1 (GPIO 5 and 6)
	str	r0, [r5, #GPIOSEL0]	@ update pins status
	ldr	r0, =#0x40000		@ set pin 18 to 1 (GPIO 26)
	str	r0, [r5, #GPIOSEL2]	@ update pins status       

@ Turn off all the leds
	ldr	r0, =#GPIO5|GPIO6|GPIO26
	str	r0, [r5, #GPCLR0]

@ Initialize registers
	ldr	r1, =#GPIO5
	ldr	r2, =#GPIO6
	ldr	r3, =#GPIO26
	ldr	r6, =#GPIO22		@ Initialize the button state
	mov	r7, #0			@ Initialize led5 state
	mov	r8, #0			@ Initialize led6 state
	mov	r9, #0			@ Initialize push count

loop:

@ Turn on the led in GPIO26 if the button in GPIO22 is pressed (pin value 0)
@ Switch on/off the led in GPIO5 if the button in GPIO22 is pressed (rising edge)
@ Switch on/off the led in GPIO6 if the button in GPIO22 is pressed (falling edge)
pressed:
	ldr	r0, [r5, #GPLEV0]
	and	r0, r0, #GPIO22
	cmp	r0, r6
	beq	updateButton
	bgt	fallingEdge
risingEdge:
@ GPIO26 update
	str	r3, [r5, #GPSET0]	
@ GPIO5 update
	cmp	r7, #0
	bne	offGPIO5
	str	r1, [r5, #GPSET0]
	b	updateGPIO5
offGPIO5:
	str	r1, [r5, #GPCLR0]
updateGPIO5:
	mvn	r7, r7
	b	updateButton	
fallingEdge:
@ GPIO26 update	
	str	r3, [r5, #GPCLR0]
@ GPIO6 update
	cmp	r8, #0
	bne	offGPIO6
	str	r2, [r5, #GPSET0]
	b	updateGPIO6
offGPIO6:
	str	r2, [r5, #GPCLR0]
updateGPIO6:
	mvn	r8, r8
@ count one button push
	add	r9, r9, #1

updateButton:
	mov	r6, r0
	
	cmp	r9, #NUMPUSH
	blt	loop

@ Turn off all the leds
	ldr	r0, =#GPIO5|GPIO6|GPIO26
	str	r0, [r5, #GPCLR0]

@ Unmap and close the file                
        mov     r0, r5          @ memory to unmap
        mov     r1, #PAGE_SIZE   @ amount we mapped
        bl      munmap          @ unmap it

        mov     r0, r4          @ /dev/gpiomem file descriptor
        bl      close           @ close the file
        
        mov     r0, 0           @ return 0;
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, fp, lr}
        bx      lr              @ return

@ Constant program data
device:
        .asciz  "/dev/gpiomem"