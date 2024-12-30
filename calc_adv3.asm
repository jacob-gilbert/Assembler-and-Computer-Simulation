# implementing function calls for parenthesis
# take in everything as chars determine which are parenthesis, operations, and integers in
# the program and not the syscall
# no nested parenthesis

.data
.text
.align 2 
.globl main
main:

# save initial stack location
add $s1, $sp, $0

# initialize $s4 indicates if sub is used btwn segments
add $s4, $0, $0

# initialize $s5 indicates if mult or div is used btwn segments
add $s5, $0, $0

# count for selecting operation
add $s6, $0, $0

GetLeftParenthesis:

    # check previous operation, if mult, div, or sub must compute now to maintain order of operations
    addi $t0, $0, 42
    beq $s5, $t0, ComputeMult

    addi $t0, $0, 47
    beq $s5, $t0, ComputeDiv

    addi $t0, $0, 45
    beq $s4, $t0, ComputeSub

    ReturnFromMultDivSub:
        addi $v0, $0, 12 # read the operation character
        syscall

        add $s0, $v0, $0

        # check if the ASCII value is an enter
        addi $t0, $0, 10
        beq $s0, $t0, FinalCalc

        # print operation to terminal
        add $a0, $s0, $0
        jal CharToTerminal

        # check if the ASCII value is a left parenthesis
        addi $t0, $0, 40
        beq $s0, $t0, StartSegment

        # checks for multiplication
        addi $t0, $0, 42 # multiplication
        bne $s0, $t0, OutCheckAdd
        add $s5, $s0, $0 # storing mult op in $s5, have to get next segment first
        j GetLeftParenthesis

        # checks addition
        OutCheckAdd:
            addi $t0, $0, 43 # addition
            bne $s0, $t0, OutCheckSub
            j StoreOpToStack

        # checks subtraction
        OutCheckSub:
            addi $t0, $0, 45 # subtraction
            bne $s0, $t0, OutCheckDiv
            add $s4, $s0, $0 # storing sub op in $s4, have to get next segment first
            j GetLeftParenthesis

        # checks division
        OutCheckDiv:
            addi $t0, $0, 47 # division
            bne $s0, $t0, PrintError
            add $s5, $s0, $0 # storing div op in $s5, have to get next segment first
            j GetLeftParenthesis

        StoreOpToStack:
            addi $sp, $sp, -4
            sw $s0, 0($sp)
            j GetLeftParenthesis

ComputeSub:
    addi $s6, $s6, 1
    addi $t0, $0, 2
    bne $s6, $t0, ReturnFromMultDivSub

    lw $t0, 0($sp) # dont add 4 to stack because we will put the operation in its place

    addi $t1, $0, 43
    sw $t1, 0($sp)

    sub $t0, $0, $t0

    addi $sp, $sp -4
    sw $t0, 0($sp)

    add $s4, $0, $0 # reset $s4
    add $s6, $0, $0 # reset $s6

    j ReturnFromMultDivSub

ComputeMult:
    addi $s6, $s6, 1
    addi $t0, $0, 2
    bne $s6, $t0, ReturnFromMultDivSub

    lw $t0, 0($sp)
    addi $sp, $sp, 4

    lw $t1, 0($sp) # dont add 4 to stack because we will put the product in its place

    mult $t1, $t0
    mflo $t0

    sw $t0, 0($sp)

    add $s5, $0, $0 # reset $s5
    add $s6, $0, $0 # reset $s6

    j ReturnFromMultDivSub

ComputeDiv:
    addi $s6, $s6, 1
    addi $t0, $0, 2
    bne $s6, $t0, ReturnFromMultDivSub

    lw $t0, 0($sp)
    addi $sp, $sp, 4

    lw $t1, 0($sp) # dont add 4 to stack because we will put the product in its place

    div $t1, $t0
    mflo $t0

    sw $t0, 0($sp)

    add $s5, $0, $0 # reset $s5
    add $s6, $0, $0 # reset $s6

    j ReturnFromMultDivSub

StartSegment:
    # save stack pointer
    add $s2, $sp, $0

    # get the first integer from the keyboard
    addi $v0, $0, 5 # read the first integer from keyboard
    syscall # this should return the integer into $v0

    # store first integer from the stack
    addi $sp, $sp, -4
    sw $v0, 0($sp)

    # print integer to terminal
    add $a0, $v0, $0
    jal IntToTerminal

    # get operation
    addi $v0, $0, 12 # read the operation character
    syscall

    add $s0, $v0, $0

    # print operation to terminal
    add $a0, $v0, $0
    jal CharToTerminal

    # only one int was inputted so go back to GetLeftParenthesis
    addi $t0, $0, 41
    beq $s0, $t0, GetLeftParenthesis

    # check if it is a valid operation
    addi $a0, $s0, 0
    jal ValidChar

    # if valid continue, else print out error message
    beq $v0, $0, PrintError

    # branch if operation is multipication or division
    beq $v1, $0, GetMultDivInt

    # checks addition
    addi $t3, $0, 43 # addition
    bne $s0, $t3, GoCheckSub

    # store add/sub op on the stack
    addi $sp, $sp, -4
    sw $s0, 0($sp)

    j IntegerLoop

IntegerLoop:
    # get the next integer from the keyboard
    addi $v0, $0, 5
    syscall

    # store integer from the stack
    addi $sp, $sp, -4
    sw $v0, 0($sp)

    # print integer to terminal
    add $a0, $v0, $0
    jal IntToTerminal

    j GetOperation


GetOperation:
    # get operation
    addi $v0, $0, 12 # read the operation character
    syscall

    add $s0, $v0, $0

    # print operation to terminal
    add $a0, $v0, $0
    jal CharToTerminal

    # calculate total if right parenthesis was inputted
    addi $t0, $0, 41
    beq $s0, $t0, CalculateTotal

    # check if it is a valid operation
    addi $a0, $s0, 0
    jal ValidChar

    # if valid continue, else print out error message
    beq $v0, $0, PrintError

    # branch if operation is multipication or division
    beq $v1, $0, GetMultDivInt

    # checks addition
    addi $t3, $0, 43 # addition
    bne $s0, $t3, GoCheckSub

    # store add/sub op on the stack
    addi $sp, $sp, -4
    sw $s0, 0($sp)

    j IntegerLoop

    # checks subtraction
    GoCheckSub:
        addi $t3, $0, 45 # subtraction
        bne $s0, $t3, PrintError
        j GetSubInt


GetSubInt:
    # get the next int
    addi $v0, $0, 5
    syscall

    # make the number negative
    sub $t2, $0, $v0

    # print to terminal
    add $a0, $v0, $0
    jal IntToTerminal

    # store addition
    addi $t0, $0, 43
    addi $sp, $sp, -4
    sw $t0, 0($sp)

    addi $sp, $sp, -4
    sw $t2, 0($sp)
    j GetOperation


GetMultDivInt:
    # a mult or div is not stored on the stack and is still in s0
    # the integer before the mult or div has been stored on the stack
    # load the previous int back, don't add 4 to the stack because
    # we will put the product/quotient in the previous int's place
    lw $t0, 0($sp)

    # get the next int
    addi $v0, $0, 5
    syscall

    add $t2, $v0, $0

    add $a0, $v0, $0
    jal IntToTerminal

    # check which operation it is
    addi $t1, $0, 42
    beq $s0, $t1, MultApply
    
    # apply division
    div $t0, $t2
    mflo $t0

    j EndGetMultDivInt

    # apply multipication
    MultApply:
        mult $t0, $t2
        mflo $t0

    EndGetMultDivInt:
        sw $t0, 0($sp)
        j GetOperation

    
# take all the numbers back from the stack and add/sub them together
CalculateTotal:
    # last inputted int
    lw $s3, 0($sp)
    addi $sp, $sp, 4

    # check if this was the only inputted int
    beq $s2, $sp, CheckDone

    GetCharIntFromStack:
        lw $t0, 0($sp) # operation loaded in $t0
        addi $sp, $sp, 4

        lw $t1, 0($sp) # integer loaded in $t1
        addi $sp, $sp, 4

        # determin add or sub
        addi $t2, $0, 43 # addition
        beq $t2, $t0, AddApply

        # apply subtraction
        sub $s3, $t1, $s3
        j CheckDone

        # apply addition
        AddApply:
            add $s3, $t1, $s3
            
        CheckDone:
            # if done store total to stack else jump to get rest from stack
            bne $s2, $sp, GetCharIntFromStack

            # add segment total to stack
            addi $sp, $sp, -4
            sw $s3, 0($sp)

            # jump back to see if there are more segments
            j GetLeftParenthesis


FinalCalc:
    # last inputted int
    lw $s3, 0($sp)
    addi $sp, $sp, 4

    # check if this was the only inputted int
    beq $s1, $sp, PrintTotal

    GetCharIntFromStackFinal:
        lw $t0, 0($sp) # operation loaded in $t0
        addi $sp, $sp, 4

        lw $t1, 0($sp) # integer loaded in $t1
        addi $sp, $sp, 4

        # determine add or sub
        addi $t2, $0, 43 # addition
        beq $t2, $t0, AddApplyFinal

        # apply subtraction
        sub $s3, $t1, $s3
        j CheckDoneFinal

        # apply addition
        AddApplyFinal:
            add $s3, $t1, $s3
            
        CheckDoneFinal:
            # if done print total to terminal else jump to get rest from stack
            beq $s1, $sp, PrintTotal

            j GetCharIntFromStackFinal


# function that prints an integer to the terminal
IntToTerminal: # use $a0 as parameter
    # print integer to terminal
    addi $v0, $zero, 1
    syscall

    jr $ra


# function that prints a char to the terminal
CharToTerminal: # use $a0 as parameter
    # print char to terminal 
    addi $v0, $zero, 11
    syscall
    
    jr $ra


# function that checks if an inputted function is a valid character
ValidChar:
    # checks multiplication
    addi $t3, $0, 42 # multiplication
    bne $a0, $t3, CheckAdd
    addi $v1, $0, 0 # 0 means it is multipication or division
    j ReturnFromValidChar

    # checks addition
    CheckAdd:
        addi $t3, $0, 43 # addition
        bne $a0, $t3, CheckSub
        addi $v1, $0, 1 # 1 means it is addition or subtraction or equals
        j ReturnFromValidChar

    # checks subtraction
    CheckSub:
        addi $t3, $0, 45 # subtraction
        bne $a0, $t3, CheckDiv
        addi $v1, $0, 1
        j ReturnFromValidChar

    # checks division
    CheckDiv:
        addi $t3, $0, 47 # division
        bne $a0, $t3, ErrorChar
        addi $v1, $0, 0

    ReturnFromValidChar:
        addi $v0, $0, 1
        jr $ra

    ErrorChar:
        add $v0, $0, $0
        jr $ra

# prints an equals sign and then the final total
PrintTotal:
    # print equal sign to terminal
    addi $a0, $0, 61
    addi $v0, $zero, 11
    syscall

    # final total is in $s3
    # print calculation to terminal
    add $a0, $s3, $0
    addi $v0, $zero, 1
    syscall

    j EndMain

# prints after only one integer
# PrintOneDoneTotal:
    # print equal sign to terminal
    #addi $a0, $0, 61
    #addi $v0, $zero, 11
    #syscall

    #lw $a0, 0($sp)
    #addi $sp, $sp, 4
    #addi $v0, $zero, 1
    #syscall

# function that prints an error code to terminal when an invalid operation is picked
PrintError:
    # write to terminal - "INVALID CHAR"
    addi $v0, $zero, 11          # syscall 11 to print character
    addi $a0, $zero, 10
    syscall
    addi $a0, $zero, 73 # I
    syscall
    addi $a0, $zero, 78 # N
    syscall
    addi $a0, $zero, 86 # V
    syscall
    addi $a0, $zero, 65 # A
    syscall
    addi $a0, $zero, 76 # L
    syscall
    addi $a0, $zero, 73 # I
    syscall
    addi $a0, $zero, 68 # D
    syscall
    addi $a0, $zero, 32 # space
    syscall
    addi $a0, $zero, 67 # C
    syscall
    addi $a0, $zero, 72 # H
    syscall
    addi $a0, $zero, 65 # A
    syscall
    addi $a0, $zero, 82 # R
    syscall

EndMain:

    addi $v0, $zero, 10
    syscall # should be infinite loop