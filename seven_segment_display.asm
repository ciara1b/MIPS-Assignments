.text
main:
    addi    $a0,            $0,         0
    jal     init7SegDisp
mainRepeat:
    jal     getPressedKey
    add     $a0,            $v0,        $zero
    jal     Num2SegDisp
    j       mainRepeat
    #  The program is finished. Exit.
exit:           li      $v0,            10                                                                          # system call for exit
    syscall                                                                                                         # Exit!

.data
SegBytes:   .byte   0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

.text

    #This procedure initialize the 7-Segment display to 00
init7SegDisp:
    addi    $s0,            $zero,      -1
    lui     $t0,            0xffff                                                                                  # load $t0 with base IO address
    addi    $t1,            $zero,      0x3f                                                                        # load seven segment display pattern for 0
    sb      $t1,            0x10($t0)                                                                               # send 0 to right segment display
    sb      $t1,            0x11($t0)                                                                               # send 0 to left segment display
    jr      $ra

    #This procedure displays two digits to the seven segment display (only one at 1st key press, but moves the 1st after displaying the 2nd)
Num2SegDisp:
    la      $t0,            SegBytes                                                                                # load the base address of seven-seg patterns
    add     $t0,            $t0,        $a0                                                                         # calculate the address of the target pattern
    lb      $t1,            0($t0)                                                                                  # load the target pattern
    lui     $t0,            0xffff                                                                                  # load $t0 with base IO address
    sb      $t1,            0x10($t0)                                                                               # send the target pattern to the 7-segment disp
    bne     $t8,            0,          Num2LeftDisplay                                                             # if this is the second key press, go put the first key press in the left display
    add     $t8,            $zero,      $t1                                                                         # store the pattern to be moved to left display later
    jr      $ra

Num2LeftDisplay:
    lui     $t0,            0xffff                                                                                  # load $t0 with base IO address
    sb      $t8,            0x11($t0)                                                                               # send the target pattern to the 7-segment disp
    j       exit

    #This procedure captures the pressed key from any row and returns its integer value in $v0
getPressedKey:
    lui     $t0,            0xffff                                                                                  # load $t0 with base IO address
Rows:           addi    $t4,            $zero,      1                                                               # set $t4 to 1 to scan the first row
    addi    $t5,            $zero,      2                                                                           # set $t4 to 2 to scan the second row
    addi    $t6,            $zero,      4                                                                           # set $t4 to 4 to scan the third row
    addi    $t7,            $zero,      8                                                                           # set $t4 to 8 to scan the fourth row
    sb      $t4,            0x12($t0)                                                                               # command first row scanning at 0xFFFF0012
    lb      $t2,            0x14($t0)                                                                               # read  0xFFFF0014 for pressed keys
    bne     $t2,            $zero,      KeyPress                                                                    # check any pressed keys [zero --> nothing pressed]
    sb      $t5,            0x12($t0)                                                                               # command second row scanning at 0xFFFF0012
    lb      $t2,            0x14($t0)
    bne     $t2,            $zero,      KeyPress
    sb      $t6,            0x12($t0)                                                                               # command third row scanning at 0xFFFF0012
    lb      $t2,            0x14($t0)
    bne     $t2,            $zero,      KeyPress
    sb      $t7,            0x12($t0)                                                                               # command fourth row scanning at 0xFFFF0012
    lb      $t2,            0x14($t0)
    bne     $t2,            $zero,      KeyPress
    j       Rows                                                                                                    #scan next row

KeyPress:
    beq     $t2,            0xffffff88, exit                                                                        # check if the key was "f", and exit the program if so
    andi    $t3,            $t2,        0xf0                                                                        # Mask 0xFFFF0014 most significant nibble s
    andi    $t2,            $t2,        0xf                                                                         # Mask 0xFFFF0014 least significant nibble
    srl     $t3,            $t3,        4                                                                           # shift $t3 for further processing
    ####  Calculate log $t3   ##########
    add     $t5,            $zero,      $zero
logt3:          srl     $t3,            $t3,        1
    beqz    $t3,            t5_t3
    addi    $t5,            $t5,        1
    j       logt3
t5_t3:          move    $t3,            $t5
    ####  Calculate log $t3   ##########
    add     $t5,            $zero,      $zero
logt2:          srl     $t2,            $t2,        1
    beqz    $t2,            t5_t2
    addi    $t5,            $t5,        1
    j       logt2
t5_t2:          move    $t2,            $t5
    ## calculate the value of the pressed key ##
    mul     $t2,            $t2,        4
    add     $v0,            $t3,        $t2
    jr      $ra

