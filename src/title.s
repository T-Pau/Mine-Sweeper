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

SCREEN_TOP = 50

irq_title_top {
    set_vic_text SCREEN_RAM, charset_logo
    lda #VIC_SCREEN_WIDTH_40 | VIC_SCREEN_MULTICOLOR
    sta VIC_CONTROL_2
    lda #COLOR_GREY_3
    sta VIC_BACKGROUND_COLOR
    jsr handle_keyboard
    rts
}

irq_title_sweeper {
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

irq_title_text {
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
    sta irq_ittle_bottom + 1
    lda #>addr
    sta irq_ittle_bottom + 2
}

; Set the next action to be performed at the bottom of the screen
; Arguments:
;   addr: address of next action
.macro set_bottom_next_action addr {
    lda #<addr
    sta title_next_action
    lda #>addr
    sta title_next_action + 1
}

; Set the next action to be performed at the bottom of the screen
; Arguments:
;   X/Y: address of next action
; Preserves: A, X, Y
set_bottom_next_action {
    stx irq_ittle_bottom + 1
    sty irq_ittle_bottom + 2
    rts

}

; Activate the next action to be performed at the bottom of the screen
; Preserves: X, Y
activate_bottom_next_action {
    lda title_next_action
    sta irq_ittle_bottom + 1
    lda title_next_action + 1
    sta irq_ittle_bottom + 2
    rts
}

irq_ittle_bottom {
    jsr $1000
    rts
}

title_fade_in {
    ldx title_fade_index
    jsr fade
    inx
    cpx #.sizeof(fade_colors) - 31
    beq done
    stx title_fade_index
    rts
done:
    jmp activate_bottom_next_action
}

title_fade_out {
    ldx title_fade_index
    jsr fade
    dex
    bmi done
    stx title_fade_index
    rts
done:
    jmp activate_bottom_next_action 
}   

attract_faded_in {
    lda #$ff
    sta title_fade_delay
    set_bottom_next_action attract_fade_out
    set_bottom_action title_delay
    rts
}

attract_fade_out {
    set_bottom_next_action attract_faded_out
    set_bottom_action title_fade_out
    rts
}

attract_faded_out {
    ldx attract_current_page
    lda attract_screens,x
    ldy attract_screens + 1,x
    inx
    inx
    cpx #.sizeof(attract_screens)
    bne :+    
    ldx #0
:   stx attract_current_page
    jsr copy_2x2_screen
    set_bottom_next_action attract_fade_in
    set_bottom_action title_fade_in
    rts
}

attract_fade_in {
    set_bottom_next_action attract_faded_in
    set_bottom_action title_fade_in
    rts
}

title_delay {
    dec title_fade_delay
    beq :+
    rts
:   jmp activate_bottom_next_action
}

title_nop {
    rts
}

.section data

irq_table_title {
    .data SCREEN_TOP - 2:2, irq_title_top
    .data SCREEN_TOP + (8 * 8) -3:2, irq_title_sweeper
    .data SCREEN_TOP + (11 * 8) -3:2, irq_title_text
    .data SCREEN_TOP + 25 * 8:2, irq_ittle_bottom
}

keyhandler_table_title {
    .data enter_menu ; fire
    .data enter_menu ; space
    .data show_help ; F1
    .data $0000 ; F3
    .data launch_original_game ; F5
    .data enter_menu ; F7 
}

.section reserved

title_fade_index .reserve 1
title_next_action .reserve 2
title_fade_delay .reserve 1
attract_current_page .reserve 1
