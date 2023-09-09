def PROTOCOL_VERSION equ 1
def PROTOCOL_BITMASK equ 1

; we've got loads of space, this ends up taking up only $924 bytes!!
macro SGB_Start_Packet
    ld [hl], $00
    rept 2
        nop
    endr
    ld [hl], $30
    rept 12
        nop
    endr
endm

macro SGB_Send_Zero
    ld [hl], $20
    rept 2
        nop
    endr
    ld [hl], $30
    rept 12
        nop
    endr
endm

macro SGB_Send_One
    ld [hl], $10
    rept 2
        nop
    endr
    ld [hl], $30
    rept 12
        nop
    endr
endm

macro SGB_Send_A
    ld [hl], a
    rept 3
        nop
    endr
    ld [hl], $30
    rept 12
        nop
    endr
endm

section "ROM", ROM0[$0000]
; Page 0 routines
    jr RST_00
    ds $08 - @

    jr RST_08
    ds $10 - @

    jr RST_10
    ds $18 - @

    jr RST_18
    ds $20 - @

    jr RST_20
    ds $28 - @

    jr RST_28
    ds $30 - @

    jr RST_30
    ds $38 - @

    jr RST_38
    ds $40 - @

    jr VBlank_ISR
    ds $48 - @

    jr STAT_ISR
    ds $50 - @

    jr Timer_ISR
    ds $58 - @

    jr Serial_ISR
    ds $60 - @

    jr Joypad_ISR
    ds $100 - @

; Header
Entrypoint:
    jr ROM_Code
    ds $150 - @

; Free space
ROM_Code:
Platform_Check:
    ld sp, RST_00
    ; build system byte in C
    ld c, 0
    ; GBC-compatible check
    cp $11
    jr nz, .not_GBC
    set 0, c
    ; GBA and GBC-compatible check
    dec b
    jr nz, .not_GBC
    set 1, c
.not_GBC:
    ; SGB check
    ld hl, $ff00
    ld a, $10
    call Send_MLT_REQ_Packet
    call Frame_Wait
    call Frame_Wait
    call Frame_Wait
    call Frame_Wait
    ld hl, $ff00
    ld [hl], $30
    ld b, [hl]
    ld [hl], $00
    ld [hl], $30
    ld a, [hl]
    cp b
    jr z, .not_SGB
    set 2, c
    ld a, $20
    call Send_MLT_REQ_Packet
.not_SGB:
    ld a, c
    ldh [system_byte], a

Connect_Prompt:
    ; turn off screen
    call Frame_Wait
    ld hl, $ff40
    res 7, [hl]

.load_tile_data:
    ld de, Tile_Data
    ld hl, $8000 + $20 * $10
    ld bc, Tile_Data_End - Tile_Data
.loop:
    ld a, [de]
    inc de
    ld [hl+], a
    ld [hl+], a
    dec bc
    xor a
    cp c
    jr nz, .loop
    cp b
    jr nz, .loop

; set GBC palettes. does nothing on dmg
    ld a, $80
    ldh [$ff68], a
    xor a
    cpl
    ld c, $ff69 - $ff00
rept 8
    ldh [c], a
    ldh [c], a
    cpl
rept 3
    ldh [c], a
    ldh [c], a
endr
    cpl
endr
.load_string:
    ; clear background
    ld a, $20
    ld hl, $9800
    ld bc, 1024
    call Memset

    ld bc, connect_prompt
    call Print_String

    ; set joypad to listen to action buttons
    ld a, $10
    ldh [$ff00], a

    ; turn on screen
    ld hl, $ff40
    set 7, [hl]

Wait_For_Start:
    ld hl, $ff00
    ; stabilize input
    ld a, [hl]
    ld a, [hl]
    ld a, [hl]
    ld a, [hl]

.loop:
    bit 3, [hl]
    jr nz, .loop

    ld a, $08
    ldh [$ffff], a

Establish_Connection:
    call Send_Byte
    call Receive_Byte
; connection present
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
; connection established
    ld a, PROTOCOL_BITMASK
    call Send_Byte
    call Receive_Byte
    or a
    call z, Panic
    cp PROTOCOL_VERSION
    jr c, .compatible_version
    jr z, .compatible_version
    ld a, $ff
    call Send_Byte
    call Panic
.compatible_version:
    ld b, a
    xor a
    call Send_Byte
    ; there's only one version, v1, so we can assume v1

Protocol_V1:
    ldh a, [system_byte]
    call Send_Byte
    call Receive_Byte
    or a
    jr z, .compatible_system
    ld a, $ff
    call Send_Byte
    call Panic
.compatible_system:
    call Frame_Wait
    ld hl, $ff40
    res 7, [hl]
    ; clear background
    ld a, $20
    ld hl, $9800
    ld bc, 1024
    call Memset
    call Send_Byte

; ready to go!
    call Receive_Byte
    ld l, a
    call Receive_Byte
    ld h, a

.segments_loop:
    call Receive_Byte
    ld c, a
    call Receive_Byte
    ld b, a
    call Receive_Byte
    ld e, a
    call Receive_Byte
    ld d, a

    xor a
    cp e
    jr nz, .loop_segment
    cp d
    jr z, End
.loop_segment:
    call Receive_Byte
    ld [bc], a
    inc bc
    dec de
    xor a
    cp e
    jr nz, .loop_segment
    cp d
    jr nz, .loop_segment
    jr .segments_loop

End:
    jp hl

; =======================
; ====== FUNCTIONS ======
; =======================

include "common.asm"

; parameters:
; - hl: pointer to memory to set
; - bc: amount of memory to set
; - a: value to set memory to
; destroys all registers except e
Memset:
    ld [hl+], a
    ld d, a
    dec bc
    xor a
    cp c
    jr nz, .loop
    cp b
    ret z
.loop:
    ld a, d
    jr Memset

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
    ret z
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

; destroys af and hl
Frame_Wait:
    ld hl, $ff41
.vblank_wait_1:
    ld a, [hl]
    and $03
    cp $01
    jr nz, .vblank_wait_1
.non_vblank_wait:
    ld a, [hl]
    and $03
    cp $01
    jr z, .non_vblank_wait
.vblank_wait_2:
    ld a, [hl]
    and $03
    cp $01
    jr nz, .vblank_wait_2

    ret

; parameters:
;   a: set to $10 to enable multiple joypads, and $20 to disable
;   hl: set to $ff00
Send_MLT_REQ_Packet:
    ; start packet
    SGB_Start_Packet
    ; byte 0: (command << 3) | length_packets. ($11 << 3) | 1 -> $89 -> 10001001 -> 10010001 (LSB first)
    SGB_Send_One
    SGB_Send_Zero
    SGB_Send_Zero
    SGB_Send_One
    SGB_Send_Zero
    SGB_Send_Zero
    SGB_Send_Zero
    SGB_Send_One
    ; byte 1: multiplayer control (0 - One Player, 1 - Two Player, 3 - Four Player) - AA000000 (LSB first)
    SGB_Send_A
    SGB_Send_A
    SGB_Send_Zero
    SGB_Send_Zero
    SGB_Send_Zero
    SGB_Send_Zero
    SGB_Send_Zero
    SGB_Send_Zero
    ; byte 2-f: zero
    rept $f - 2 + 1
        rept 8
            SGB_Send_Zero
        endr
    endr
    ; last bit to end packet (why?)
    SGB_Send_Zero
    ret

; =======================
; ======== DATA =========
; =======================

Tile_Data:
    incbin "chicago8x8.tiledata"
Tile_Data_End:

connect_prompt:
    db "Press Start after\nconnecting a cable.", 0

section "HRAM", HRAM[$ff80]
system_byte:
    ds 1
    ds $ff95 - @
stack_word:
    ds 2
RST_00:
    ds 8
RST_08:
    ds 8
RST_10:
    ds 8
RST_18:
    ds 8
RST_20:
    ds 8
RST_28:
    ds 8
RST_30:
    ds 8
RST_38:
    ds 8
VBlank_ISR:
    ds 8
STAT_ISR:
    ds 8
Timer_ISR:
    ds 8
Serial_ISR:
    ds 8
Joypad_ISR:
    ds 8

    assert @ == $ffff
