;  Copyright (C) Dieter Baron
;
;  This file is part of Mine Sweeper.
;  The authors can be contacted at <mine-sweeper@tpau.group>.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
;  1. Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
;  2. The names of the authors may not be used to endorse or promote
;     products derived from this software without specific prior
;     written permission.
;
;  THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS
;  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
;  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
;  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
;  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

GAME_SHAPE_SQUARE = 0
GAME_SHAPE_HEX = 1

GAME_SIZE_TINY = 0
GAME_SIZE_SMALL = 1
GAME_SIZE_MEDIUM = 2
GAME_SIZE_LARGE = 3

GAME_DIFFICULTY_EASY = 0
GAME_DIFFICULTY_NORMAL = 1
GAME_DIFFICULTY_HARD = 2

.section code

enter_menu {
    set_bottom_next_action show_menu
    set_bottom_action title_fade_out
    rts
}

show_menu {
    lda #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_1x1)
    sta text_charset
    lda #COMMAND_COPY_MENU_SCREEN
    sta current_command
    set_bottom_next_action menu_fade_in
    set_bottom_action wait_for_command
    set_keyhandler_table keyhandler_table_menu
    lda #0
    sta menu_update_screen
    rts
}

menu_fade_in {
    set_bottom_next_action setup_menu
    set_bottom_action title_fade_in
    lda #1
    sta menu_update_screen
    ldx game_shape
    jsr menu_toggle_field
    lda game_size
    clc
    adc #4
    tax
    jsr menu_toggle_field
    lda game_difficulty
    clc
    adc #8
    tax
    jsr menu_toggle_field
    rts
}

setup_menu {
    ldx #88
    stx pointer_min_y

    ldx #$03
    stx VIC_SPRITE_ENABLE
    ldx #COLOR_WHITE
    stx VIC_SPRITE_0_COLOR
    dex
    stx VIC_SPRITE_1_COLOR
    ldx #title_pointer_sprite/64
    stx SCREEN_RAM + $03f8
    inx
    stx SCREEN_RAM + $03f9
    ldx #0
    stx pointer_x
    ldy #(TEXT_SCREEN_START-SCREEN_RAM)/40*8+$31
    sty pointer_y

    lda #$ff
    sta highlighted_field
    set_bottom_action menu_action
    rts
}
menu_action {
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
    jmp menu_handle_left_click
end:
    rts
}

copy_menu_screen {
    store_word source_ptr, menu_screen
    store_word destination_ptr, TEXT_SCREEN_START
    jmp rl_expand
}

menu_change_difficulty {
    lda game_difficulty
    clc
    adc #8
    tax
    jsr menu_toggle_field
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
    jmp menu_toggle_field
}

menu_change_size {
    lda game_size
    clc
    adc #4
    tax
    jsr menu_toggle_field
    ldx game_size
    inx
    cpx #4
    bne :+
    ldx #0
:   stx game_size
    txa
    clc
    adc #4
    tax
    jmp menu_toggle_field
}

menu_change_shape {
    ldx game_shape
    jsr menu_toggle_field
    lda game_shape
    eor #1
    sta game_shape
    tax
    jmp menu_toggle_field
}

menu_handle_left_click {
    lda highlighted_field
    cmp #$0c
    bne :+
    jmp launch_modern_game
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
    jsr menu_toggle_field
index:
    ldx #$00    
    lda click_value
    sta game_config,x
    ora click_field
    tax
    jsr menu_toggle_field
end:
    rts
}


; Toggle field in start game screen. Skip update if menu_update_screen is zero.
; Arguments:
;   X: field index
; Preserves: X
menu_toggle_field {
    lda menu_update_screen
    beq end
    lda menu_field_low,x
    sta source_ptr
    lda menu_field_high,x
    sta source_ptr + 1
    ldy menu_field_length,x
    dey
:   lda (source_ptr),y
    eor #$80
    sta (source_ptr),y
    dey
    bpl :-
end:
    rts
}    

; Highlight field in start game screen.
; Arguments:
;   Y: color
;   X: field index
; Preserves: X
highlight_field {
    lda menu_field_low,x
    sta source_ptr
    lda menu_field_high,x
    eor #>(SCREEN_RAM ^ COLOR_RAM)
    sta source_ptr + 1
    tya
    ldy menu_field_length,x
    dey
:   sta (source_ptr),y
    dey
    bpl :-
    rts
}


pointer_to_field {
    lda pointer_x
    ldy pointer_x + 1
    lsr
    lsr
    lsr
    cpy #0
    beq :+
    clc
    adc #32
:   sta x_offset + 1

    lda pointer_y
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

    ldx #.sizeof(menu_field_length) - 1
field_loop:
    lda source_ptr
    sec
    sbc menu_field_low,x
    tay
    lda source_ptr + 1
    sbc menu_field_high,x
    bcc next_field
    bne next_field
    tya
    cmp menu_field_length,x
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

keyhandler_table_menu {
    .data $0000 ; fire
    .data launch_modern_game ; space
    .data menu_change_shape ; F1
    .data menu_change_size ; F3
    .data menu_change_difficulty ; F5
    .data launch_modern_game ; F7
}

.macro field line, row, length {
    .data TEXT_SCREEN_START + (line * 40) + row
    .data TEXT_SCREEN_START + (line * 40) + row + length
}

FIELD_ADDRESS(line, row) = TEXT_SCREEN_START + (line * 40) + row

menu_field_low {
    ; Shape
    .data <FIELD_ADDRESS(5, 19)
    .data <FIELD_ADDRESS(5, 27)
    .data 0, 0

    ; Size
    .data <FIELD_ADDRESS(7, 12)
    .data <FIELD_ADDRESS(7, 18)
    .data <FIELD_ADDRESS(7, 25)
    .data <FIELD_ADDRESS(7, 33)

    ; Difficulty
    .data <FIELD_ADDRESS(9, 18)
    .data <FIELD_ADDRESS(9, 24)
    .data <FIELD_ADDRESS(9, 32)
    .data 0

    ; Start Game
    .data <FIELD_ADDRESS(12, 6)
}

menu_field_high {
    ; Shape
    .data >FIELD_ADDRESS(5, 19)
    .data >FIELD_ADDRESS(5, 27)
    .data 0, 0

    ; Size
    .data >FIELD_ADDRESS(7, 12)
    .data >FIELD_ADDRESS(7, 18)
    .data >FIELD_ADDRESS(7, 25)
    .data >FIELD_ADDRESS(7, 33)

    ; Difficulty
    .data >FIELD_ADDRESS(9, 18)
    .data >FIELD_ADDRESS(9, 24)
    .data >FIELD_ADDRESS(9, 32)
    .data 0

    ; Start Game
    .data >FIELD_ADDRESS(12, 6)
}

menu_field_length {
    ; Shape
    .data 8
    .data 5
    .data 0
    .data 0

    ; Size
    .data 6
    .data 7
    .data 8
    .data 5

    ; Difficulty
    .data 6
    .data 8
    .data 6
    .data 0

    ; Start Game
    .data 26
}

game_config {
.public game_shape:
    .data GAME_SHAPE_SQUARE
.public game_size:
    .data GAME_SIZE_SMALL
.public game_difficulty:
    .data GAME_DIFFICULTY_NORMAL
}

GAME_ORIGINAL_OFFSET_X = 32
GAME_ORIGINAL_OFFSET_Y = 16

; indexed by size << 1 | shape
game_width {
    .data 8, 8,  10, 10,  14, 14,  18, 19
}
game_height {
    .data 8, 8,  10, 10,  10, 10,  10, 10
}
game_offset_x { ; in pixels
    .data 48, 48, 32, 32,  48, 48,  16, 8
}
game_offset_y { ; in pixels
    .data 24, 24, 16, 16,  0, 0,  0, 0
}

; indexed by difficulty << 3 | size << 1 | shape
game_mines {
    .data  7,  6,  11, 10,  15, 14,  21, 20
    .data 10,  9,  16, 15,  23, 22,  32, 30
    .data 13, 12,  20, 19,  28, 27,  40, 37
}

game_map {
    .data GAME_MAP_SMALL
    .data GAME_MAP_SMALL
    .data GAME_MAP_LARGE
    .data GAME_MAP_LARGE
}

.section reserved

highlighted_field .reserve 1
menu_update_screen .reserve 1

click_field .reserve 1
click_value .reserve 1