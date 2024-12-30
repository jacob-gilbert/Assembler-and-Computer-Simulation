#run this test once you have hooked up your RGBmonitor, keyboard, and memory
.data
.text
.globl main
main:
    #uncomment the below if you haven't added the stack
    #pointer initialization to your assembler yet
    addi $sp, $0, -4096 #Initialize stack pointer
    addi $sp, $sp, -48
    #Store RGB values in stack allocated array
    #Mixing palette
    addi $t0, $0, 255 #blue
    sll $t1, $t0, 8  #green
    sll $t2, $t0, 16 #red
    addi $t3, $0, 127 #less blue
    sll $t4, $t3, 8 #less green
    sll $t5, $t3, 16 #less red
    #red - 0
    sw $t2, 0($sp)
    #red-orange - 1
    add $t8, $t2, $t4
    sw $t8, 4($sp)
    #yellow - 2
    add $t8, $t2, $t1
    sw $t8, 8($sp)
    #green-yellow - 3
    add $t8, $t5, $t1
    sw $t8, 12($sp)
    #green - 4
    sw $t1, 16($sp)
    #cyan-green - 5
    add $t8, $t3, $t1
    sw $t8, 20($sp)
    #cyan-6
    add $t8, $t0, $t1
    sw $t8, 24($sp)
    #cyan-blue
    add $t8, $t0, $t4
    sw $t8, 28($sp)
    #blue - 8
    sw $t0, 32($sp)
    #blue-magenta - 9
    add $t8, $t0, $t5
    sw $t8, 36($sp)
    #magenta - 10
    add $t8, $t0, $t2
    sw $t8, 40($sp)
    #red-magenta - 11
    add $t8, $t3, $t2
    sw $t8, 44($sp)

    addi $s0, $0, 0 #x coordinate
    addi $s1, $0, 0 #y coordinate
    addi $s2, $0, 0 #color

loop:
    #check for keypress
    lw $t0, -240($0) #0xFFFFFF10 = keyboard ready
    beq $t0, $0, colorchange #if no keypress, jump to change color
    #if keypress, update x,y coordinate
    lw $t0, -236($0) #0xFFFFFF14 = read keyboard character
    addi $t1, $0, 119 #ascii w
    bne $t0, $t1, notw
    beq $s1, $0, endkeypress #if y coord = 0, do nothing
    addi $s1, $s1, -1
    j endkeypress
notw:
    addi $t1, $0, 97 #ascii a
    bne $t0, $t1, nota
    beq $s0, $0, endkeypress #if x coord = 0, do nothing
    addi $s0, $s0, -1
    j endkeypress
nota:
    addi $t1, $0, 115 #ascii s
    bne $t0, $t1, nots
    addi $t2, $0, 255 #assuming monitor width = 255
    beq $s1, $t2, endkeypress #if y coord = 255, do nothing
    addi $s1, $s1, 1
    j endkeypress
nots:
    addi $t1, $0, 100 #ascii d
    bne $t0, $t1, endkeypress
    addi $t2, $0, 255 #assuming monitor width = 255
    beq $s0, $t2, endkeypress #if x coord = 255, do nothing
    addi $s0, $s0, 1
endkeypress:
    sw $0, -240($0) #set keyboard ready to 0 to get next character
colorchange:
    #change color
    addi $s2, $s2, 1
    addi $t0, $0, 12
    div $s2, $t0
    mfhi $s2 #s2 = (s2 + 1) % 12
    sll $t0, $s2, 2
    add $t0, $t0, $sp #get address of color
    lw $t0, 0($t0) #t0 = load rgb color from memory
    #display pixel
    sw $s0, -224($0) #0xFFFFFF20 = monitor x coordinate
    sw $s1, -220($0) #0xFFFFFF24 = monitor y coordinate
    sw $t0, -216($0) #0xFFFFFF28 = monitor color
    sw $0, -212($0)  #0xFFFFFF2C = write pixel
    j loop
