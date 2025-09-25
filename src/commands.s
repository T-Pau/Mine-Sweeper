COMMAND_START_GAME = 1
COMMAND_COPY_HELP_SCREEN = 2
COMMAND_SHOW_MARQUEE = 3

.section code

handle_command {
    lda current_command
    beq done
    asl
    tay
    cpy #.sizeof(command_table) + 2
    bcs done
    lda command_table - 2,y
    sta subroutine + 1
    lda command_table - 1,y
    beq done
    sta subroutine + 2
subroutine:
    jsr $1000
done:
    lda #0
    sta current_command
    rts
}

.section data

command_table {
    .data start_game
    .data copy_help_screen
    .data show_marquee
}

.section reserved

current_command .reserve 1
