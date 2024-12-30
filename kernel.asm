#This is starter code, so that you know the basic format of this file.
#Use _ in your system labels to decrease the chance that labels in the "main"
#program will conflict

.data
.text

# create-switch like functionality to jump to the _syscall chosen in $v0
_syscallStart_:

# if $v0 is 0 go to _syscall0
beq $v0, $0, _syscall0

# allocate space to the stack for $t0 and store the contents of it there
addi $sp, $sp, -4
sw $t0, 0($sp)

# if $v0 is 1 go to _syscall1
addi $t0, $0, 1
beq $v0, $t0, _syscall1

# if $v0 is 5 go to _syscall5
addi $t0, $0, 5
beq $v0, $t0, _syscall5

# if $v0 is 9 go to _syscall9
addi $t0, $0, 9
beq $v0, $t0, _syscall9

# if $v0 is 10 go to _syscall10
addi $t0, $0, 10
beq $v0, $t0, _syscall10

# if $v0 is 11 go to _syscall11
addi $t0, $0, 11
beq $v0, $t0, _syscall11

# if $v0 is 12 go to _syscall12
addi $t0, $0, 12
beq $v0, $t0, _syscall12

# error state
j _syscall10


# create functionality for _syscall0
_syscall0:
    # set the initial value of the stack pointer to 0x03FFF000 / 0xFFFFF000 / -4096
    addi $sp, $sp, -4096

    # heap location pointer
    la $k1, End_Static_Mem
    sw, $k1, -4092($0)
    j _syscallEnd_


# Use the appropriate lw/sw to the appropriate addresses to communicate with
# the terminal register and print the integer that is stored in $a0, then return.
# You may NOT assume that the integer is positive.
_syscall1:

    # check if integer is zero
    beq $a0, $0, ZeroInt1

    # store $t1, $t2, and $t3 to stack so you can use them
    addi $sp, $sp, -4
    sw $t1, 0($sp)
    addi $sp, $sp -4
    sw $t2, 0($sp)
    addi $sp, $sp -4
    sw $t3, 0($sp)
    addi $sp, $sp -4
    sw $t4, 0($sp)

    # save current stack pointer for later comparison
    add $t4, $sp, $0

    # check if the integer is negative
    slt $t0, $a0, $0

    # using this to divide into $a0
    addi $t2, $0, 10

    # using this as indicator of negative number
    addi $t3, $0, 0
    
    # if less than ($t0 is 1) the number is negative
    bne $t0, $0, Negative1

    # if here then the number was positive
    # divide by 10 over and over til you store the whole number
    NumLoop1:

        # divide $a0 by 10
        div $a0, $t2
        mfhi $t0
        mflo $t1

        beq $t1, $0 QuoZero1 # branch if quotient is zero

        # quotient is not zero
        # store remainder on stack to later be printed
        addi $sp, $sp, -4
        sw $t0, 0($sp)

        # set a0 to be the quotient and jump back to the loop
        add $a0, $t1, $0
        j NumLoop1


    QuoZero1:

        # print out remainder digit
        addi $t0, $t0, 48
        sw $t0, -256($0)

        # jump to PrintStackLoop1
        j PrintStackLoop1

    PrintStackLoop1:

        # check if our current stack pointer is where it was before we put the digits on the stack
        # done if they are equal
        beq $sp, $t4, End1

        # need to load every digit back, add 48 to it for proper ASCII value, and print to terminal
        lw $t0, 0($sp)
        addi $t0, $t0, 48
        sw $t0, -256($0)
        addi $sp, $sp, 4
        j PrintStackLoop1

    # number is negative
    Negative1:
        # make $a0 positive
        sub $a0, $0, $a0

        # print out the negative sign and enter NumLoop1
        addi $t3, $0, 45
        sw $t3, -256($0)
        j NumLoop1

    ZeroInt1:
        # adding 48 because it is ASCII value of 0
        addi $t0, $0, 48

        # terminal is located in -256($0) so store $t0 there
        sw $t0, -256($0)

    End1:
        # load data back into registers from stack
        lw $t4, 0($sp)
        addi $sp, $sp, 4

        lw $t3, 0($sp)
        addi $sp, $sp, 4

        lw $t2, 0($sp)
        addi $sp, $sp, 4

        lw $t1, 0($sp)
        addi $sp, $sp, 4

        lw $t0, 0($sp)
        addi $sp, $sp, 4

        # end the _syscall
        jr $k0


# Use the appropriate lw/sw to the appropriate addresses to communicate with
# the keyboard registers and read an integer that is stored into $v0, then return.
# You may assume that the integer ends when the next character is a non-digit.
# (Leave that character on the keyboard queue). You may NOT assume that the integer
# is positive. You may assume that the integer is smaller than 32 bytes.
_syscall5: 

    # store $t1 and $t2 to stack so you can use them
    addi $sp, $sp, -4
    sw $t1, 0($sp)
    addi $sp, $sp, -4
    sw $t2, 0($sp)

    # set $t2 to zero to use as indicator of negative number
    addi $t2, $0, 0

    # reinitialize $v0 to 0
    addi $v0, $0, 0

    # a digit has an ASCII code of 48 to 57 and a hyphen/negative sign is 45
    # get the integer from the keyboard
    GetInteger:

        lw $t0, -240($0)
        bne $t0, $0, GetKeypress5 # this branches if there is a keypress otherwise try again
        j GetInteger

    GetKeypress5:

        # load the keypress from -236($0) to $t0
        lw $t0, -236($0)

        # check if the ASCII value is a hyphen
        addi $t1, $0, 45
        beq $t1, $t0, Negative5

        # check if the ASCII value is a number
        addi $t1, $0, 48
        slt $t1, $t0, $t1 # 1 if not a number
        bne $t1, $0, End5

        addi $t1, $0, 57
        slt $t1, $t1, $t0 # 1 if not a number
        bne $t1, $0, End5

        # ASCII value is a number if we are here, convert from ASCII to digit
        addi $t0, $t0, -48

        # multiple previous number by 10 and then add the new digit
        addi $t1, $0, 10
        mult $v0, $t1
        mflo $v0
        add $v0, $v0, $t0

        # sw to -240($0) for next integer and jump back to GetInteger to complete loop
        addi $t0, $0, 0
        sw $t0, -240($0)
        j GetInteger

    # number is negative
    Negative5:
        # check if we have already gotten a hyphen before, would mean this is just a regular char and not for number
        bne $t2, $0, End5

        # check if $v0 is not 0, if it is not zero hyphen comes after number and its not part of it
        bne $v0, 0, End5

        # negative identifier
        addi $t2, $0, 1

        addi $t0, $0, 0
        sw $t0, -240($0)

        j GetInteger

    End5:
        # check if the number was initially negative
        beq $t2, $0, NotNegative
        sub $v0, $0, $v0

        NotNegative:
            # load data back from the stack
            lw $t2, 0($sp)
            addi $sp, $sp, 4

            lw $t1, 0($sp)
            addi $sp, $sp, 4

            lw $t0, 0($sp)
            addi $sp, $sp, 4

            # end the _syscall
            jr $k0


# the calling program will request a number of bytes in register $a0, and you
# will provide a block of that many bytes, returning a pointer in $v0. No two
# separate _syscalls should return overlapping memory, and you do not need to
# worry about releasing memory.
_syscall9:

    lw $t0, -4092($0)
    add $v0, $t0, $0
    add $t0, $a0, $t0
    sw $t0, -4092($0)

    lw $t0, 0($sp)
    addi $sp, $sp, 4

    jr $k0


# create infinite loop for _syscall 10
_syscall10:

    j _syscall10


# Use the appropriate lw/sw to the appropriate addresses to communicate with
# the terminal registers and print the character that is stored in $a0, then return.
_syscall11:

    # load data back into $t0 from stack
    lw $t0, 0($sp)
    addi $sp, $sp, 4

    # terminal is located in -256($0) so store $a0 there
    sw $a0, -256($0)

    # end the _syscall
    jr $k0

# Use the appropriate lw/sw to the appropriate addresses to communicate with
# the keyboard registers and read a character, if there is one. If not, loop
# until there is. Return the character in register $v0.
_syscall12:

    GetStatus:

        # first need to check if there is a new keypress in -240($sp)
        # note $t0 is safe to use since its already been saved to the stack and hasn't been loaded back yet
        lw $t0, -240($0)
        bne $t0, $0, GetKeypress # this branches if there is a keypress otherwise try again
        j GetStatus

    # a keyboard read requires a sw and is in address -236 from $sp
    GetKeypress:

        # save the keypress from -236($sp) to $v0
        lw $v0, -236($0)

        sw $0, -240($0)

        # load the data back onto $t0 from the stack since we no longer need the register
        lw $t0, 0($sp)
        addi $sp, $sp, 4

        # end the _syscall (return)
        jr $k0


_syscallEnd_: