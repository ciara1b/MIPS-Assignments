                .globl  main
.data
inputStr:       .space  20
ask:            .asciiz "$ Enter a real number [xxx.yyy]: "
str2float:      .float  000.000
signBit:        .asciiz "\n$ The sign bit of your number is: "
exponent:       .asciiz "\n$ The exponent of your number is: "
fraction:       .asciiz "\n$ The fraction of your number is: "
exponentBinary: .space  33
exponentHex:    .space  33
FractionBinary: .space  33
fractionHex:    .space  33
separate:       .asciiz " || "
.text
main:
    la      $a0,            ask
    li      $v0,            4
    syscall

input:
    li      $v0,            8                                   #load read_string into $v0
    la      $a0,            inputStr                            #allocate string space
    li      $a1,            10                                  #allocate byte space
    syscall

stringLen:
    li      $s1,            0                                   #initialize 0 to $s1
strLoop:
    lb      $t0,            0($a0)                              #load next character of string into $t0
    beq     $t0,            45,                     removeSign  #if the first character is a "-", jump and decrement character count by 1, then come back
strLoop1:
    beqz    $t0,            enterKey                            #check if $t0 is NULL, and if so exit loop
    addi    $a0,            $a0,                    1           #increment $a0 to get to next character
    addi    $s1,            $s1,                    1           #increment character counter
    j       strLoop

removeSign:
    addi    $s1,            $s1,                    -1
    j       strLoop1

enterKey:
    addi    $s1,            $s1,                    -1          #decrement character count to account for the enter key

    la      $s0,            inputStr                            #load it into $s0 now to manipulate
    addi    $t1,            $t1,                    100
    lb      $t2,            0($s0)                              #load first character into $t2
    beq     $t2,            45,                     signed      #check if it's a signed number
back0:
    addi    $t2,            $t2,                    -48         #convert first digit
    mtc1    $t2,            $f2
    mtc1    $t1,            $f1
    cvt.s.w $f1,            $f1
    cvt.s.w $f2,            $f2
    mul.s   $f2,            $f2,                    $f1
    add.s   $f0,            $f0,                    $f2         #add to sum
    add.s   $f3,            $f3,                    $f1
    addi    $t1,            $zero,                  10
    mtc1    $t1,            $f4
    cvt.s.w $f4,            $f4
    addi    $s1,            $s1,                    -1          #decrement character count
floatConvert:
    div.s   $f3,            $f3,                    $f4         #decrease n by 1 (10^n)
    addi    $s0,            $s0,                    1           #go to next character in string
    lb      $t2,            ($s0)                               #load next character into $t7
    beq     $t2,            46,                     point       #check if it's a signed number
back1:
    addi    $t2,            $t2,                    -48         #convert digit
    mtc1    $t2,            $f2
    cvt.s.w $f2,            $f2
    mul.s   $f2,            $f2,                    $f3
    add.s   $f0,            $f0,                    $f2         #add to sum
    addi    $s1,            $s1,                    -1          #decrement character count by 1
    beq     $s1,            0,                      prep0       #check if the last character has been converted and added, if so, jump to prep0
    j       floatConvert                                        #loop to next character

point:
    addi    $s0,            $s0,                    1           #increment
    addi    $s1,            $s1,                    -1          #decrement character count by 1
    lb      $t2,            0($s0)                              #load first character into $t2
    j       back1

signed:
    add     $s6,            $s4,                    $t2         #store "-" character in $t1
    addi    $s0,            $s0,                    1           #increment to first number
    lb      $t2,            0($s0)                              #load first character into $t2
    j       back0

prep0:
    s.s     $f0,            str2float
    mfc1    $t8,            $f0                                 #store in $t8

    #extract exponent
    ori     $t2,            $zero,                  0xFF
    sll     $t2,            $t2,                    23
    and     $t4,            $t2,                    $t8
    srl     $t4,            $t4,                    23
    add     $t7,            $t7,                    $t4

binaryConvert0:
    la      $t3,            ($t4)                               #load integer into $t2
    div     $t1,            $t3,                    2           #integer/2
    mflo    $t4                                                 #store integer result into $t4
    mfhi    $t3                                                 #store remainder (either a 1 or 0) in $t3
    addi    $t3,            $t3,                    48          #convert the integer into a character
    sw      $t3,            0($sp)                              #push character to stack
    addi    $sp,            $sp,                    4           #increment stack
    add     $t5,            $t5,                    1           #keep a count of characters
    add     $t6,            $t6,                    1           #keep another counter for spaces
    beq     $t4,            0,                      prepend0    #pop everything back into a string when we're done
    beq     $t6,            4,                      addSpace0
    j       binaryConvert0                                      #loop to get next digit

addSpace0:
    sub     $t6,            $t6,                    4           #put counter back to 0
    addi    $t3,            $zero,                  32          #store space character in $t3
    sw      $t3,            0($sp)                              #push character to stack
    addi    $sp,            $sp,                    4           #increment stack
    addi    $t5,            $t5,                    1
    bgt     $s5,            0,                      zeroLoop0
    j       binaryConvert0                                      #jump back to next instruction in print

binaryPop0:
    addi    $t6,            $zero,                  0
binPopLoop0:
    addi    $sp,            $sp,                    -4          #decrement stack pointer
    lw      $t3,            0($sp)                              #pop from stack
    sb      $t3,            exponentBinary($s2)                 #add it to binary string
    addi    $s2,            $s2,                    1           #increment
    addi    $t5,            $t5,                    -1          #decrement character count
    beq     $t5,            0,                      hexConvert0 #finished storing characters in string
    j       binPopLoop0

hexConvert0:
    la      $t3,            ($t7)                               #load integer into $t2
    div     $t1,            $t3,                    16          #integer/16
    mflo    $t7                                                 #store integer result into $t4
    mfhi    $t3                                                 #store remainder (either a 1 or 0) in $t3
    bgt     $t3,            9,                      letter0
    addi    $t3,            $t3,                    48          #convert the integer into a character
    j       number0
letter0:
    addi    $t3,            $t3,                    55
number0:
    sw      $t3,            0($sp)                              #push character to stack
    addi    $sp,            $sp,                    4           #increment stack
    add     $t5,            $t5,                    1           #keep a count of characters
    beq     $t7,            0,                      hexPop0     #pop everything back into a string when we're done
    j       hexConvert0                                         #loop to get next digit

hexPop0:
    addi    $t6,            $zero,                  0
hexPopLoop0:
    addi    $sp,            $sp,                    -4          #decrement stack pointer
    lw      $t3,            0($sp)                              #pop from stack
    sb      $t3,            exponentHex($s3)                    #add it to binary string
    addi    $s3,            $s3,                    1           #increment
    addi    $t5,            $t5,                    -1          #decrement character count
    beq     $t5,            0,                      prep1       #finished storing characters in string
    j       hexPopLoop0

prepend0:
    beq     $t5,            9,                      binaryPop0
    beq     $t6,            4,                      addSpace0
    addi    $s5,            $zero,                  1
zeroLoop0:                                                      #push n 0s to stack where n = $t6
    addi    $t3,            $zero,                  48          #store the zero character into $t3
    sw      $t3,            0($sp)                              #push zero to stack
    addi    $sp,            $sp,                    4           #increment stack
    add     $t6,            $t6,                    1           #keep another counter for spaces
    addi    $t5,            $t5,                    1
    beq     $t5,            9,                      binaryPop0  #jump to pop when done
    beq     $t6,            4,                      addSpace0
    j       zeroLoop0

prep1:
    addi    $s2,            $zero,                  0
    addi    $s3,            $zero,                  0
    #extract mantissa
    ori     $t2,            $zero,                  0xFFFF
    sll     $t2,            $t2,                    7
    ori     $t2,            $t2,                    0x7F
    and     $t4,            $t2,                    $t8
    add     $t7,            $zero,                  $t4
    add     $t9,            $zero,                  $t4

binaryConvert1:
    la      $t3,            ($t4)                               #load integer into $t2
    div     $t1,            $t3,                    2           #integer/2
    mflo    $t4                                                 #store integer result into $t4
    mfhi    $t3                                                 #store remainder (either a 1 or 0) in $t3
    addi    $t3,            $t3,                    48          #convert the integer into a character
    sw      $t3,            0($sp)                              #push character to stack
    addi    $sp,            $sp,                    4           #increment stack
    add     $t5,            $t5,                    1           #keep a count of characters
    add     $t6,            $t6,                    1           #keep another counter for spaces
    beq     $t4,            0,                      prepend1    #pop everything back into a string when we're done
    beq     $t6,            4,                      addSpace1
    j       binaryConvert1                                      #loop to get next digit

addSpace1:
    sub     $t6,            $t6,                    4           #put counter back to 0
    addi    $t3,            $zero,                  32          #store space character in $t3
    sw      $t3,            0($sp)                              #push character to stack
    addi    $sp,            $sp,                    4           #increment stack
    addi    $t5,            $t5,                    1
    bgt     $s4,            0,                      zeroLoop1
    j       binaryConvert1                                      #jump back to next instruction in print

binaryPop1:
binPopLoop1:
    addi    $sp,            $sp,                    -4          #decrement stack pointer
    lw      $t3,            0($sp)                              #pop from stack
    sb      $t3,            FractionBinary($s2)                 #add it to binary string
    addi    $s2,            $s2,                    1           #increment
    addi    $t5,            $t5,                    -1          #decrement character count
    beq     $t5,            0,                      doWeAppend  #finished storing characters in string
    j       binPopLoop1

doWeAppend:
    bgt     $t9,            4194303,                append
nextHex:
    addi    $t6,            $zero,                  0
hexConvert1:
    la      $t3,            ($t7)                               #load integer into $t2
    div     $t1,            $t3,                    16          #integer/16
    mflo    $t7                                                 #store integer result into $t4
    mfhi    $t3                                                 #store remainder (either a 1 or 0) in $t3
    bgt     $t3,            9,                      letter1
    addi    $t3,            $t3,                    48          #convert the integer into a character
    j       number1
letter1:
    addi    $t3,            $t3,                    55
number1:
    sw      $t3,            0($sp)                              #push character to stack
    addi    $sp,            $sp,                    4           #increment stack
    add     $t5,            $t5,                    1           #keep a count of characters
    beq     $t7,            0,                      hexPop1     #pop everything back into a string when we're done
    j       hexConvert1                                         #loop to get next digit

hexPop1:
    addi    $t6,            $zero,                  0
    addi    $t5,            $zero,                  23
hexPopLoop1:
    addi    $sp,            $sp,                    -4          #decrement stack pointer
    lw      $t3,            0($sp)                              #pop from stack
    sb      $t3,            fractionHex($s3)                    #add it to binary string
    addi    $s3,            $s3,                    1           #increment
    addi    $t5,            $t5,                    -1          #decrement character count
    beq     $t5,            0,                      end         #finished storing characters in string
    j       hexPopLoop1

prepend1:
    beq     $t5,            28,                     binaryPop1
    addi    $t3,            $zero,                  28
    beq     $t6,            4,                      addSpace1
    add     $s4,            $t3,                    $t5
    bgt     $t9,            4194303,                binaryPop1
zeroLoop1:                                                      #push n 0s to stack where n = $t6
    addi    $t3,            $zero,                  48          #store the zero character into $t3
    sw      $t3,            0($sp)                              #push zero to stack
    addi    $sp,            $sp,                    4           #increment stack
    addi    $t5,            $t5,                    1
    add     $t6,            $t6,                    1           #keep another counter for spaces
    beq     $t5,            28,                     binaryPop1  #jump to pop when done
    beq     $t6,            4,                      addSpace1
    j       zeroLoop1

append:
    beq     $s4,            0,                      nextHex
    beq     $t6,            4,                      addSpace2
appendLoop:
    addi    $t3,            $zero,                  48
    sb      $t3,            FractionBinary($s2)
    addi    $s2,            $s2,                    1           #increment
    addi    $t6,            $t6,                    1           #increment
    beq     $s4,            0,                      nextHex
    beq     $t6,            4,                      addSpace2
    j       append

addSpace2:
    sub     $t6,            $t6,                    4           #put counter back to 0
    addi    $t3,            $zero,                  32          #store space character in $t3
    sb      $t3,            FractionBinary($s2)
    addi    $s2,            $s2,                    1           #increment
    j       appendLoop

end:
    li      $v0,            4
    la      $a0,            signBit
    syscall
    beq     $s6,            45,                     signBit1
    li      $v0,            1
    li      $a0,            0
    syscall
    j       exponentPrint
signBit1:
    li      $v0,            1
    li      $a0,            1
    syscall

exponentPrint:
    li      $v0,            4
    la      $a0,            exponent
    syscall
    li      $v0,            4
    la      $a0,            exponentBinary
    syscall
    li      $v0,            4
    la      $a0,            separate
    syscall
    li      $v0,            4
    la      $a0,            exponentHex
    syscall

    li      $v0,            4
    la      $a0,            fraction
    syscall
    li      $v0,            4
    la      $a0,            FractionBinary
    syscall
    li      $v0,            4
    la      $a0,            separate
    syscall
    li      $v0,            4
    la      $a0,            fractionHex
    syscall
