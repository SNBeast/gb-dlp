def PROTOCOL_VERSION equ 1

section "ROM", ROM0[$0000]
    ds $100 - @
Entrypoint:
    jr ROM_Code
    ds $150 - @
ROM_Code:
    ld a, $08
    ldh [$ffff], a
    ld a, $82
    ldh [$ff02], a
    call Receive_Byte
    call Send_Byte
; connection present
    call Receive_Byte
    cp "g"
    call nz, Panic
    call Receive_Byte
    cp "b"
    call nz, Panic
    call Receive_Byte
    cp "-"
    call nz, Panic
    call Receive_Byte
    cp "d"
    call nz, Panic
    call Receive_Byte
    cp "l"
    call nz, Panic
    call Receive_Byte
    cp "p"
    call nz, Panic
    call Receive_Byte
    or a
    call nz, Panic
    ld a, "g"
    call Send_Byte
    ld a, "b"
    call Send_Byte
    ld a, "-"
    call Send_Byte
    ld a, "d"
    call Send_Byte
    ld a, "l"
    call Send_Byte
    ld a, "p"
    call Send_Byte
    xor a
    call Send_Byte
; connection established
    call Receive_Byte
    cp PROTOCOL_VERSION
    jr z, .correct_protocol
    call Panic
.correct_protocol:
    ld a, PROTOCOL_VERSION
    call Send_Byte
    call Receive_Byte
    or a
    jr z, .protocol_negotiated
    call Panic
.protocol_negotiated:

Protocol_v0:
    call Receive_Byte
; we don't care about platform
    xor a
    call Send_Byte
    call Receive_Byte

; ready to go!
; code entrypoint
    ld hl, Code_To_Send_Beginning
    ld a, l
    call Send_Byte
    ld a, h
    call Send_Byte
; first segment address
    ld a, l
    call Send_Byte
    ld a, h
    call Send_Byte
; first segment length
    ld bc, Code_To_Send_End - Code_To_Send_Beginning
    ld a, c
    call Send_Byte
    ld a, b
    call Send_Byte
; first segment data
    ld hl, Code_To_Send_ROM_Location
.loop_segment:
    ld a, [hl+]
    call Send_Byte
    dec bc
    xor a
    cp c
    jr nz, .loop_segment
    cp b
    jr nz, .loop_segment
; done sending first segment. now to send empty segment
; empty segment address
    call Send_Byte
    call Send_Byte
; empty segment length
    call Send_Byte
    call Send_Byte
; done!
    halt

Code_To_Send_ROM_Location:
load "WRAM on DLP Partner", WRAM0[$C000]
Code_To_Send_Beginning:
    ld bc, string_to_print
; parameter:
; - bc: pointer to string to print
; destroys all registers
Print_String:
    ld hl, $9800
    ld d, l
    ld e, l
.loop:
    inc d
    ld a, [bc]
    or a
    jr z, .end
    cp "\n"
    jr z, .add_Line
    ld a, d
    cp 21
    jr nz, .skip_Line_Add
.add_Line:
    ld d, 0
    ld a, e
    add $20
    ld e, a
    ld l, a
    jr nz, .skip_Inc_H
    inc h
.skip_Inc_H:
    inc bc
    jr .loop
.skip_Line_Add:
    ld a, [bc]
    inc bc
    ld [hl+], a
    jr .loop

.end:
    ld hl, $ff40
    set 7, [hl]
    halt

string_to_print:
    db "Download\nsuccessful.", 0

Code_To_Send_End:
endl ; WRAM on DLP Partner

include "common.asm"
