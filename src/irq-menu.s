.section code

SCREEN_TOP = 50

irq_menu_top {
    set_vic_text SCREEN_RAM, charset_logo
    lda #VIC_SCREEN_WIDTH_40 | VIC_SCREEN_MULTICOLOR
    sta VIC_CONTROL_2
    lda #COLOR_GREY_3
    sta VIC_BACKGROUND_COLOR
    jsr handle_keyboard
    rts
}

irq_menu_sweeper {
    ldx #$72 ; TODO: symbolic constant
:   cpx VIC_RASTER
    bne :-
    ldx #$09
:   dex
    bpl :-
    ldx #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_1x1)
    stx VIC_VIDEO_ADDRESS
    rts
}

irq_menu_text {
.public text_charset = text_charset_lda + 1

    ldx #$87 ; TODO: symbolic constant
:   cpx VIC_RASTER
    bne :-
    ldx #$00
    stx VIC_BACKGROUND_COLOR
    ldy #VIC_SCREEN_WIDTH_40
text_charset_lda:
    lda #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_2x2)
    ldx #$8a
:   cpx VIC_RASTER
    bne :-
    ldx #$0a
:   dex
    bne :-
    sty VIC_CONTROL_2
    sta VIC_VIDEO_ADDRESS
    jsr music_play
    rts
}

.macro set_bottom_action addr {
    lda #<addr
    sta irq_menu_bottom + 1
    lda #>addr
    sta irq_menu_bottom + 2
}

; Set the next action to be performed at the bottom of the screen
; Arguments:
;   addr: address of next action
.macro set_bottom_next_action addr {
    lda #<addr
    sta menu_next_action
    lda #>addr
    sta menu_next_action + 1
}

; Set the next action to be performed at the bottom of the screen
; Arguments:
;   X/Y: address of next action
; Preserves: A, X, Y
set_bottom_next_action {
    stx irq_menu_bottom + 1
    sty irq_menu_bottom + 2
    rts

}

; Activate the next action to be performed at the bottom of the screen
; Preserves: X, Y
activate_bottom_next_action {
    lda menu_next_action
    sta irq_menu_bottom + 1
    lda menu_next_action + 1
    sta irq_menu_bottom + 2
    rts
}

irq_menu_bottom {
    jsr $1000
    rts
}

menu_fade_in {
    ldx menu_fade_index
    jsr fade
    inx
    cpx #.sizeof(fade_colors) - 31
    beq done
    stx menu_fade_index
    rts
done:
    jmp activate_bottom_next_action
}

menu_fade_out {
    ldx menu_fade_index
    jsr fade
    dex
    bmi done
    stx menu_fade_index
    rts
done:
    jmp activate_bottom_next_action 
}   

menu_marquee_faded_in {
    lda #$ff
    sta menu_fade_delay
    set_bottom_next_action menu_marquee_fade_out
    set_bottom_action menu_delay
    rts
}

menu_marquee_fade_out {
    set_bottom_next_action menu_marquee_faded_out
    set_bottom_action menu_fade_out
    rts
}

menu_marquee_faded_out {
    ldx menu_marquee_current_page
    lda menu_screens,x
    ldy menu_screens + 1,x
    inx
    inx
    cpx #.sizeof(menu_screens)
    bne :+    
    ldx #0
:   stx menu_marquee_current_page
    jsr copy_2x2_screen
    set_bottom_next_action menu_marquee_fade_in
    set_bottom_action menu_fade_in
    rts
}

menu_marquee_fade_in {
    set_bottom_next_action menu_marquee_faded_in
    set_bottom_action menu_fade_in
    rts
}

menu_delay {
    dec menu_fade_delay
    beq :+
    rts
:   jmp activate_bottom_next_action
}

menu_nop {
    rts
}

.section data

irq_menu_table {
    .data SCREEN_TOP - 2:2, irq_menu_top
    .data SCREEN_TOP + (8 * 8) -3:2, irq_menu_sweeper
    .data SCREEN_TOP + (11 * 8) -3:2, irq_menu_text
    .data SCREEN_TOP + 25 * 8:2, irq_menu_bottom
}

keyhandler_table_marquee {
    .data launch_game ; fire
    .data launch_game ; space
    .data launch_game_original ; F1
    .data launch_game_new ; F3
    .data launch_game_hex ; F5
    .data show_help ; F7 
}

.section reserved

menu_fade_index .reserve 1
menu_next_action .reserve 2
menu_fade_delay .reserve 1
menu_marquee_current_page .reserve 1
