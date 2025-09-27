GAME_ORIGINAL = 0
GAME_NEW = 1
GAME_HEX = 2

.section code

launch_game {
    set_bottom_next_action launch_game_faded_out
    set_bottom_action menu_fade_out
    rts
}

launch_game_faded_out {
    lda #COMMAND_START_GAME
    sta current_command
    set_irq_table music_irq_table
    rts
}


launch_game_original {
    lda #GAME_ORIGINAL
    sta game_mode
    jmp launch_game
}

launch_game_new {
    lda #GAME_NEW
    sta game_mode
    jmp launch_game
}

launch_game_hex {
    lda #GAME_HEX
    sta game_mode
    jmp launch_game
}

start_game {
    lda #COLOR_BLACK
    sta VIC_BACKGROUND_COLOR
    set_vic_bank $4000
    set_vic_text game_screen, game_bitmap
    set_vic_bitmap_mode
    lda #VIC_SCREEN_WIDTH_40 | VIC_SCREEN_MULTICOLOR
    sta VIC_CONTROL_2

    ldx #250
:   lda game_color - 1,x
    sta COLOR_RAM - 1,x
    lda game_color + 249,x
    sta COLOR_RAM + 249,x
    lda game_color + 499,x
    sta COLOR_RAM + 499,x
    lda game_color + 749,x
    sta COLOR_RAM + 749,x
    dex
    bne :-

    ; TODO: Take parameters from game_mode.
    lda #$16
    ldx #10
    ldy #10
    jsr init_field


    ldx #$03
    stx VIC_SPRITE_ENABLE
    ldx #$01
    stx VIC_SPRITE_0_COLOR
    dex
    stx VIC_SPRITE_1_COLOR
    ldx #0
    stx pointer_x
    stx pointer_x + 1
    stx pointer_y

    set_irq_table game_irq_table
    rts
}

game_irq {
    jsr music_play
    jsr handle_input
    rts
}

update_pointer {
    ldx pointer_x
    ldy pointer_x + 1
    bne high_x
    ldy #$00
    cpx #$17
    bcs set_x
    ldx #$17
    bne set_x
high_x:
    ldy #$03
    cpx #$57
    bcc set_x
    ldx #$56
set_x:
    stx pointer_x
    stx VIC_SPRITE_0_X
    stx VIC_SPRITE_1_X
    sty VIC_SPRITE_X_MSB
    ldx pointer_y
    cpx #$31
    bcs :+
    ldx #$31
:   cpx #$f9
    bcc :+
    ldx #$f8
:   stx pointer_y
    stx VIC_SPRITE_0_Y
    stx VIC_SPRITE_1_Y
    rts
}


.section data

game_irq_table {
    .data SCREEN_TOP:2, game_irq
}


music_irq_table {
    .data SCREEN_TOP:2, music_play
}

.section reserved

game_mode .reserve 1
