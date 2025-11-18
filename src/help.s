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

.section code

show_help {
    lda #0
    sta current_help_page
    set_bottom_next_action help_show_page
    set_bottom_action title_fade_out
    set_keyhandler_table keyhandler_table_help
    rts
}

help_show_page {
    lda #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_1x1)
    sta text_charset
    lda #COMMAND_COPY_HELP_SCREEN
    sta current_command
    set_bottom_next_action title_fade_in
    set_bottom_action wait_for_command
    rts
}

wait_for_command {
    lda current_command
    bne :+
    jsr activate_bottom_next_action
    set_bottom_next_action title_nop
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
    set_bottom_action title_fade_out
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
    set_bottom_action title_fade_out
    rts
}

help_exit {
    set_bottom_next_action enter_attract
    set_bottom_action title_fade_out
    rts
}

enter_attract {
    set_keyhandler_table keyhandler_table_title
    lda #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_2x2)
    sta text_charset
    lda #COMMAND_SHOW_ATTRACT
    sta current_command
    set_bottom_next_action attract_faded_out
    set_bottom_action wait_for_command
    rts
}

.section data

keyhandler_table_help {
    .data enter_menu ; fire
    .data help_next_page ; space
    .data help_exit ; F1
    .data $0000 ; F3
    .data launch_original_game ; F5
    .data enter_menu ; F7 
    .data help_previous_page; return
    .data help_exit; run/stop
}

.section reserved

current_help_page .reserve 1