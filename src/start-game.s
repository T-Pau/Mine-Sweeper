GAME_SHAPE_SQUARE = 0
GAME_SHAPE_HEX = 1

GAME_SIZE_SMALL = 0
GAME_SIZE_MEDIUM = 1
GAME_SIZE_LARGE = 2

GAME_DIFFICULTY_EASY = 0
GAME_DIFFICULTY_NORMAL = 1
GAME_DIFFICULTY_HARD = 2

.section code

enter_start_game {
    set_bottom_next_action show_start_game
    set_bottom_action menu_fade_out
    rts
}

show_start_game {
    lda #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_1x1)
    sta text_charset
    lda #COMMAND_COPY_START_GAME_SCREEN
    sta current_command
    set_bottom_next_action start_game_fade_in
    set_bottom_action wait_for_command
    rts
}

start_game_fade_in {
    set_bottom_next_action setup_start_game
    set_bottom_action menu_fade_in
    rts
}

setup_start_game {
    set_keyhandler_table keyhandler_table_start_game

    ldx #$03
    stx VIC_SPRITE_ENABLE
    ldx #COLOR_WHITE
    stx VIC_SPRITE_0_COLOR
    dex
    stx VIC_SPRITE_1_COLOR
    ldx #0
    stx pointer_x
    stx pointer_x + 1
    stx pointer_y
    ldx #pointer_sprite_menu/64
    stx SCREEN_RAM + $03f8
    inx
    stx SCREEN_RAM + $03f9
    ldx #0
    stx pointer_x
    ldy #(TEXT_SCREEN_START-SCREEN_RAM)/40*8+$31
    sty pointer_y

    lda #$ff
    sta highlighted_field
    set_bottom_action start_game_action
    rts
}
start_game_action {
    jsr read_input
    jsr pointer_to_field
    bpl in_field
    ldx highlighted_field
    bmi end
    ldy #COLOR_GREY_3
    jsr highlight_field
    ldx #$ff
    stx highlighted_field
    rts
in_field:
    cpx highlighted_field
    beq no_change
    stx store + 1
    ldx highlighted_field
    ldy #COLOR_GREY_3
    jsr highlight_field
store:
    ldx #0
    stx highlighted_field
    ldy #COLOR_WHITE
    jsr highlight_field
no_change:
    lda buttons
    and #BUTTON_LEFT
    beq end
    jmp start_game_handle_left_click
end:
    rts
}

copy_start_game_screen {
    store_word source_ptr, start_game_screen
    store_word destination_ptr, TEXT_SCREEN_START
    jsr rl_expand
    ldx game_shape
    jsr start_game_toggle_field
    lda game_size
    clc
    adc #4
    tax
    jsr start_game_toggle_field
    lda game_difficulty
    clc
    adc #8
    tax
    jsr start_game_toggle_field
    lda game_reveal_zeroes
    clc
    adc #12
    tax
    jsr start_game_toggle_field
    rts
}

start_game_change_difficulty {
    lda game_difficulty
    clc
    adc #8
    tax
    jsr start_game_toggle_field
    ldx game_difficulty
    inx
    cpx #3
    bne :+
    ldx #0
:   stx game_difficulty
    txa
    clc
    adc #8
    tax
    jmp start_game_toggle_field
}

start_game_change_size {
    lda game_size
    clc
    adc #4
    tax
    jsr start_game_toggle_field
    ldx game_size
    inx
    cpx #3
    bne :+
    ldx #0
:   stx game_size
    txa
    clc
    adc #4
    tax
    jmp start_game_toggle_field
}

start_game_change_shape {
    ldx game_shape
    jsr start_game_toggle_field
    lda game_shape
    eor #1
    sta game_shape
    tax
    jmp start_game_toggle_field
}

start_game_change_reveal_zeroes {
    lda game_reveal_zeroes
    clc
    adc #12
    tax
    jsr start_game_toggle_field
    lda game_reveal_zeroes
    eor #1
    sta game_reveal_zeroes
    clc
    adc #12
    tax
    jmp start_game_toggle_field
}

start_game_handle_left_click {
    lda highlighted_field
    cmp #$10
    bne :+
    jmp launch_game
:   and #$fc
    sta click_field
    lsr
    lsr
    tax
    stx index + 1
    lda highlighted_field
    and #$03
    sta click_value

    lda game_config,x
    cmp click_value
    beq end
    ora click_field
    tax
    jsr start_game_toggle_field
index:
    ldx #$00    
    lda click_value
    sta game_config,x
    ora click_field
    tax
    jsr start_game_toggle_field
end:
    rts
}


; Toggle field in start game screen.
; Arguments:
;   X: field index
; Preserves: X
start_game_toggle_field {
    lda start_game_field_low,x
    sta source_ptr
    lda start_game_field_high,x
    sta source_ptr + 1
    ldy start_game_field_length,x
    dey
:   lda (source_ptr),y
    eor #$80
    sta (source_ptr),y
    dey
    bpl :-
    rts
}    

; Highlight field in start game screen.
; Arguments:
;   Y: color
;   X: field index
; Preserves: X
highlight_field {
    lda start_game_field_low,x
    sta source_ptr
    lda start_game_field_high,x
    eor #>(SCREEN_RAM ^ COLOR_RAM)
    sta source_ptr + 1
    tya
    ldy start_game_field_length,x
    dey
:   sta (source_ptr),y
    dey
    bpl :-
    rts
}


pointer_to_field {
    lda pointer_x
    ldy pointer_x + 1
    sec
    sbc #$17
    bcs :+
    dey
:   lsr
    lsr
    lsr
    cpy #0
    beq :+
    clc
    adc #32
:   sta x_offset + 1

    lda pointer_y
    sec
    sbc #$31
    and #$f8
    sta source_ptr
    ldy #0
    sty source_ptr + 1
    asl
    rol source_ptr + 1
    asl
    rol source_ptr + 1
    clc
    adc source_ptr
    bcc x_offset
    inc source_ptr + 1
    clc
x_offset:
    adc #0
    sta source_ptr
    bcc :+
    inc source_ptr + 1
:   lda source_ptr +1
    ora #>SCREEN_RAM
    sta source_ptr +1

    ldx #.sizeof(start_game_field_length) - 1
field_loop:
    lda source_ptr
    sec
    sbc start_game_field_low,x
    tay
    lda source_ptr + 1
    sbc start_game_field_high,x
    bcc next_field
    bne next_field
    tya
    cmp start_game_field_length,x
    bcs next_field
    cpx #0
    rts

next_field:
    dex
    bpl field_loop

    ldx #$ff
    rts
}

.section data

keyhandler_table_start_game {
    .data $0000 ; fire
    .data launch_game ; space
    .data start_game_change_shape ; F1
    .data start_game_change_size ; F3
    .data start_game_change_difficulty ; F5
    .data start_game_change_reveal_zeroes ; F7
}

.macro field line, row, length {
    .data TEXT_SCREEN_START + (line * 40) + row
    .data TEXT_SCREEN_START + (line * 40) + row + length
}

FIELD_ADDRESS(line, row) = TEXT_SCREEN_START + (line * 40) + row

start_game_field_low {
    ; Shape
    .data <FIELD_ADDRESS(4, 19)
    .data <FIELD_ADDRESS(4, 27)
    .data 0, 0

    ; Size
    .data <FIELD_ADDRESS(6, 15)
    .data <FIELD_ADDRESS(6, 22)
    .data <FIELD_ADDRESS(6, 30)
    .data 0

    ; Difficulty
    .data <FIELD_ADDRESS(8, 18)
    .data <FIELD_ADDRESS(8, 24)
    .data <FIELD_ADDRESS(8, 32)
    .data 0

    ; Reveal Zeroes
    .data <FIELD_ADDRESS(10, 25)
    .data <FIELD_ADDRESS(10, 29)
    .data 0, 0

    ; Start Game
    .data <FIELD_ADDRESS(13, 11)
}

start_game_field_high {
    ; Shape
    .data >FIELD_ADDRESS(4, 19)
    .data >FIELD_ADDRESS(4, 27)
    .data 0, 0

    ; Size
    .data >FIELD_ADDRESS(6, 15)
    .data >FIELD_ADDRESS(6, 22)
    .data >FIELD_ADDRESS(6, 30)
    .data 0

    ; Difficulty
    .data >FIELD_ADDRESS(8, 18)
    .data >FIELD_ADDRESS(8, 24)
    .data >FIELD_ADDRESS(8, 32)
    .data 0

    ; Reveal Zeroes
    .data >FIELD_ADDRESS(10, 25)
    .data >FIELD_ADDRESS(10, 29)
    .data 0, 0

    ; Start Game
    .data >FIELD_ADDRESS(13, 11)
}

start_game_field_length {
    ; Shape
    .data 8
    .data 5
    .data 0
    .data 0

    ; Size
    .data 7
    .data 8
    .data 5
    .data 0

    ; Difficulty
    .data 6
    .data 8
    .data 6
    .data 0

    ; Reveal Zeros
    .data 4
    .data 5
    .data 0
    .data 0

    ; Start Game
    .data 18
}

game_config {
.public game_shape:
    .data GAME_SHAPE_SQUARE
.public game_size:
    .data GAME_SIZE_SMALL
.public game_difficulty:
    .data GAME_DIFFICULTY_NORMAL
.public game_reveal_zeroes:
    .data 1
}

.section reserved

highlighted_field .reserve 1

click_field .reserve 1
click_value .reserve 1