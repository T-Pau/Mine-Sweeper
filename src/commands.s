COMMAND_START_GAME = 1
COMMAND_COPY_HELP_SCREEN = 2
COMMAND_SHOW_MARQUEE = 3
COMMAND_PREPARE_GAME = 4
COMMAND_GAME_WON = 5
COMMAND_GAME_LOST = 6

.section code

.macro set_command command {
    lda #command
    sta current_command
}

command_loop {
    lda current_command
    beq command_loop
    asl
    cmp #.sizeof(command_table) + 2
    bcs command_loop
    tay
    lda command_table - 2,y
    sta subroutine + 1
    lda command_table - 1,y
    beq command_loop
    sta subroutine + 2
subroutine:
    jsr $1000
    lda #0
    sta current_command
    beq command_loop
}

.section data

command_table {
    .data start_game
    .data copy_help_screen
    .data show_marquee
    .data prepare_game
    .data game_won
    .data game_lost
}

.section reserved

current_command .reserve 1
