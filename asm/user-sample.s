    .set     noreorder
    .set     noat
    .globl   __start
    .section text

__start:
# .text
# ori $t0, $zero, 0x1 # t0 = 1
# ori $t1, $zero, 0x1 # t1 = 1
# xor $v0, $v0, $v0 # v0 = 0
# ori $v1, $zero, 8 # v1 = 8
# lui $a0, 0x8040 # a0 = 0x80400000

# loop:
# addu $t2, $t0, $t1 # t2 = t0+t1
# ori $t0, $t1, 0x0 # t0 = t1
# ori $t1, $t2, 0x0 # t1 = t2
# sw $t1, 0($a0)
# addiu $a0, $a0, 4 # a0 += 4
# addiu $v0, $v0, 1 # v0 += 1

# bne $v0, $v1, loop
# ori $zero, $zero, 0 # nop

# jr $ra
# ori $zero, $zero, 0 # nop

    .text

find_max:
    lui      $a0, 0x8040
    lui      $a1, 0x8070

    lw       $v0, 0($a0)
    addiu    $a0, $a0, 4

find_max_loop:
    lw       $t0, 0($a0)
    slt      $t1, $v0, $t0           # sltu in cpu
    bne      $t1, ,$zero, update_max
    ori      $zero, $zero, 0         # nop

    addiu    $a0, $a0, 4
    bne      $a1, $a0, find_max_loop
    ori      $zero, $zero, 0         # nop
    j        done_find
    ori      $zero, $zero, 0         # nop

update_max:
    ori      $v0, $t0, 0x0
    j        find_max_loop
    ori      $zero, $zero, 0         # nop

done_find:
    sw       $v0, 0($a1)
    jr       $ra
    ori      $zero, $zero, 0         # nop
