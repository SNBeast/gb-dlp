; parameter:
; - a: byte to send
Send_Byte:
    ldh [$ff01], a
    ld a, $83
    ldh [$ff02], a
    dec a
    halt
    ldh [$ff02], a
    xor a
    ldh [$ff0f], a
    rept 32 ; works but may not be optimal
        nop
    endr
    ret

; parameter:
; - a: set to byte received
Receive_Byte:
    ld a, $82
    halt
    ldh [$ff02], a
    xor a
    ldh [$ff0f], a
    ldh a, [$ff01]
    ret

Panic:
    db $d3
    jr @
    ret
