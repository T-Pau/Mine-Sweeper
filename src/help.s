.section code

show_help {
    lda #0
    sta current_help_page
    set_bottom_next_action help_show_page
    set_bottom_action menu_fade_out
    set_keyhandler_table keyhandler_table_help
    rts
}

help_show_page {
    lda #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_1x1)
    sta text_charset
    lda #COMMAND_COPY_HELP_SCREEN
    sta current_command
    set_bottom_next_action menu_fade_in
    set_bottom_action wait_for_command
    rts
}

wait_for_command {
    lda current_command
    bne :+
    jsr activate_bottom_next_action
    set_bottom_next_action menu_nop
:   rts
}

copy_help_screen {
    ldx current_help_page
    lda help_screens,x
    sta source_ptr
    lda help_screens + 1,x
    sta source_ptr + 1
    store_word destination_ptr, TEXT_SCREEN_START
    jmp rl_expand
}


help_next_page {
    ldx current_help_page
    inx
    inx
    cpx #.sizeof(help_screens)
    bne :+
    ldx #0
:   stx current_help_page
    set_bottom_next_action help_show_page
    set_bottom_action menu_fade_out
    rts
}

help_previous_page {
    ldx current_help_page
    dex
    dex
    bpl :+
    ldx #.sizeof(help_screens) - 2
:   stx current_help_page
    set_bottom_next_action help_show_page
    set_bottom_action menu_fade_out
    rts
}

help_exit {
    set_bottom_next_action enter_marquee
    set_bottom_action menu_fade_out
    rts
}

enter_marquee {
    set_keyhandler_table keyhandler_table_menu
    lda #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_2x2)
    sta text_charset
    lda #COMMAND_SHOW_MARQUEE
    sta current_command
    set_bottom_next_action menu_marquee_faded_out
    set_bottom_action wait_for_command
    rts
}

.section data

keyhandler_table_help {
    .data enter_start_game ; fire
    .data help_next_page ; space
    .data help_exit ; F1
    .data $0000 ; F3
    .data $0000 ; F5
    .data enter_start_game ; F7 
    .data help_previous_page; return
    .data help_exit; run/stop
}

.section reserved

current_help_page .reserve 1