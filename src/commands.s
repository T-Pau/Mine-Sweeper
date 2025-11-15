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

COMMAND_START_GAME = 1
COMMAND_COPY_HELP_SCREEN = 2
COMMAND_SHOW_ATTRACT = 3
COMMAND_PREPARE_GAME = 4
COMMAND_GAME_WON = 5
COMMAND_GAME_LOST = 6
COMMAND_REVEAL_ZERO = 7
COMMAND_COPY_MENU_SCREEN = 8

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
    .data show_attract
    .data prepare_game
    .data game_won
    .data game_lost
    .data reveal_zero
    .data copy_menu_screen
}

.section reserved

current_command .reserve 1
