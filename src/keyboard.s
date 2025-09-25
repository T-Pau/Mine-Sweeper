.section code

KEY_FIRE = $01
KEY_SPACE = $02
KEY_F1 = $03
KEY_F3 = $04
KEY_F5 = $05
KEY_F7 = $06
KEY_RETURN = $07
KEY_RUNSTOP = $08

read_keyboard {
    lda #$00
    sta CIA1_DDRA
    sta CIA1_DDRB
    lda #$ff
    sta CIA1_PRA
    sta CIA1_PRB

    lda CIA1_PRA
    and CIA1_PRB
    tax
    and #$10
    bne :+
    lda #KEY_FIRE
    bne got_key

:   cpx #$ff
    bne no_key

    lda #$ff
    sta CIA1_DDRA
    lda #$fe
    sta CIA1_PRA

    lda CIA1_PRB
    lsr
    lsr
    bcs :+
    lda #KEY_RETURN
    bne got_key
:   lsr
    lsr
    bcs :+
    lda #KEY_F7
    bne got_key    
:   lsr 
    bcs :+
    lda #KEY_F1
    bne got_key   
:   lsr
    bcs :+
    lda #KEY_F3
    bne got_key
:   lsr
    bcs :+
    lda #KEY_F5
    bne got_key

:   lda #$7f
    sta CIA1_PRA
    lda CIA1_PRB
    bmi :+
    lda #KEY_RUNSTOP
    bne got_key
:   and #$10
    bne :+
    lda #KEY_SPACE
    bne got_key
:   lda #0
    beq no_key
got_key:
    cmp last_key
    beq no_key
    sta current_key
no_key:
    sta last_key
    rts
}

; Set command table.
; Arguments:
;   A: size of table
;   X/Y: address of table
set_keyhandler_table {
    sta keyhandler_table_size
    stx keyhandler_table
    sty keyhandler_table + 1
    rts
}

; Set command table.
; Arguments:
;   table: table object
.macro set_keyhandler_table table {
    lda #.sizeof(table)
    ldx #<table
    ldy #>table
    jsr set_keyhandler_table
}

handle_keyboard {
    jsr read_keyboard
    lda current_key
    beq done
    asl
    tay
    dey
    dey
    cpy keyhandler_table_size
    bcs done
    lda (keyhandler_table),y
    sta subroutine + 1
    iny
    lda (keyhandler_table),y
    beq done
    sta subroutine + 2
subroutine:
    jsr $1000
done:
    lda #0
    sta current_key
    rts
}

.section reserved

last_key .reserve 1
current_key .reserve 1
keyhandler_table_size .reserve 1

.section zero_page

keyhandler_table .reserve 2