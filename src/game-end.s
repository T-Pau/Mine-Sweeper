.section code

setup_game_end {
    set_keyhandler_table keyhandler_table_game_over
    set_bottom_action wait_for_command
    add_bottom_action title_fade_in
    rts
}

title_continue {
    set_keyhandler_table keyhandler_table_title
    set_bottom_action title_fade_out
    add_bottom_action attract_faded_out
    rts
}

.section data

keyhandler_table_game_over {
    .data title_continue ; fire
    .data title_continue ; space
    .data $0000 ; F1
    .data $0000 ; F3
    .data $0000 ; F5
    .data $0000 ; F7 
}
