# Run this test once you have hooked up your terminal and memory
.data
    functions: .word end f
    info: .word 72 101 108 108 111 44 32 119 111 114 108 100 33 10 0
.text
.globl main
main:
    addi $sp, $sp, -4096
    la $s0, functions
begin:
    lw $t0, 4($s0)
    la $a0, info
    jalr $t0
    lw $t0, 0($s0)
    jalr $t0
f:
    lw $t0, 0($a0)
    beq $t0, $0, endf
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    sw $t0, -256($0)
    addi $a0, $a0, 4
    jal f
    lw $ra, 0($sp)
    addi $sp, $sp, 4
endf:
    jr $ra
end:
    j end