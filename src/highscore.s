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

; High score table format:
; Each entry is 16 bytes:
; 0-12: name (padded with spaces)
; 13-14: score
; 15: game mode bit field:
;   0: shape
;   1-2: size
;   3-4: difficulty
;   5: controller (0: joystick, 1: mouse)

HIGHSCORE_OFFSET_NAME = 0
HIGHSCORE_OFFSET_SCORE = 13
HIGHSCORE_OFFSET_GAME_MODE = 15

HIGHSCORE_SCREEN_SCORE_OFFSET = 14
HIGHSCORE_SCREEN_GAME_MODE_OFFSET = HIGHSCORE_SCREEN_SCORE_OFFSET + 6
ICON_OFFSET_SHAPE = $40
ICON_OFFSET_SIZE = $42
ICON_OFFSET_DIFFICULTY = $46
ICON_OFFSET_CONTROLLER = $49
ICON_OFFSET_LIVE = $4b

SCORE_SCREEN_OFFSET_SHAPE = 40 * 4 + 21
SCORE_SCREEN_OFFSET_SIZE = SCORE_SCREEN_OFFSET_SHAPE + 1
SCORE_SCREEN_OFFSET_CONTROLLER = SCORE_SCREEN_OFFSET_SHAPE + 40 * 3
SCORE_SCREEN_OFFSET_LIVES = SCORE_SCREEN_OFFSET_CONTROLLER + 40
SCORE_SCREEN_OFFSET_DIFFICULTY = SCORE_SCREEN_OFFSET_LIVES + 40

.section code

; Display score screen after winning.
display_score {
    rl_expand TEXT_SCREEN_START, score_screen
    lda game_shape
    sta current_game_mode
    lda game_size
    asl
    ora current_game_mode
    sta current_game_mode
    lda game_difficulty
    asl
    asl
    asl
    ora current_game_mode
    sta current_game_mode
    lda used_mouse
    beq :+
    lda #%100000 
:   ora current_game_mode
    sta current_game_mode
    jsr calculate_score_icons

    lda score_icon_shape
    sta TEXT_SCREEN_START + SCORE_SCREEN_OFFSET_SHAPE
    lda score_icon_size
    sta TEXT_SCREEN_START + SCORE_SCREEN_OFFSET_SIZE
    lda score_icon_difficulty
    sta TEXT_SCREEN_START + SCORE_SCREEN_OFFSET_DIFFICULTY
    lda score_icon_controller
    sta TEXT_SCREEN_START + SCORE_SCREEN_OFFSET_CONTROLLER
    ldy lives_left
    lda #ICON_OFFSET_LIVE
:   sta TEXT_SCREEN_START + SCORE_SCREEN_OFFSET_LIVES - 1,y
    dey
    bne :-

    ; TODO: compute score and rank
    ; TODO: if in highscore table, set up action to enter name
    jsr setup_title
    lda #CHARSET_1x1
    sta text_charset
    jmp setup_attract_fade
}

; Write high score table to screen.
; Arguments:
;   destination_ptr: pointer to first name in screen memory
render_highscore_table {
    store_word source_ptr, highscore_table
loop:    
    ldy #12
    ; Copy name.
:   lda (source_ptr),y
    sta (destination_ptr),y
    dey
    bpl :-

    ldy #HIGHSCORE_OFFSET_SCORE
    lda (source_ptr),y
    sta current_score
    iny
    lda (source_ptr),y
    sta current_score + 1
    jsr calculate_score_digits
    ldy #HIGHSCORE_SCREEN_SCORE_OFFSET
    jsr print_score

    ; Render game mode icons.
    ldy #HIGHSCORE_OFFSET_GAME_MODE
    lda (source_ptr),y
    jsr calculate_score_icons

    ldy #HIGHSCORE_SCREEN_GAME_MODE_OFFSET
    ldx #0
:   lda score_icons,x
    sta (destination_ptr),y
    iny
    inx
    cpx #4
    bne :- 

    ; Next entry.
    lda source_ptr
    clc
    adc #16
    cmp #.sizeof(highscore_table)
    bne :+
    rts
:   sta source_ptr
    clc
    lda destination_ptr
    adc #40
    sta destination_ptr
    bcc :+
    inc destination_ptr + 1
:   jmp loop
}

; Convert score to digits using Double Dabble algorithm.
; Arguments:
;   current_score: score to convert
; Result:
;   score_digits: digits of the score, least significant digit first
calculate_score_digits {
    lda #0
    sta score_digits
    sta score_digits + 1
    sta score_digits + 2
    sta score_digits + 3
    sta score_digits + 4
    ldx #15
process_bit:
    ldy #4
adjust_digits:
    lda score_digits,y
    cmp #5
    bcc :+
    adc #122 ; add 123 to the digit, carry is set
    sta score_digits,y
:   dey
    bpl adjust_digits
    asl current_score
    rol current_score + 1
    rol score_digits
    rol score_digits + 1
    rol score_digits + 2
    rol score_digits + 3
    rol score_digits + 4
    dex
    bpl process_bit
    rts
}

; Print score to screen.
; Arguments:
;   Y: offset of the first digit in screen memory
;   score_digits: digits of the score, least significant digit first
;   destination_ptr: pointer to screen
print_score {
    ldx #4
    ; Skip leading zeros.
:   lda score_digits,x
    bne output
    lda #' '
    sta (destination_ptr),y
    iny
    dex
    bne :-
output:
    lda score_digits,x
    ora #$30
    sta (destination_ptr),y
    iny
    dex
    bpl output
    rts
}

; Calculate icons for game mode.
; Arguments:
;   A: game mode bit field
; Result:
;   score_icons: screen codes for shape, size, difficulty, controller
calculate_score_icons {
    tax
    and #1
    clc
    adc #ICON_OFFSET_SHAPE
    sta score_icons
    txa
    lsr
    tax
    and #3
    clc
    adc #ICON_OFFSET_SIZE
    sta score_icons + 1
    txa
    lsr
    lsr
    tax
    and #3
    clc
    adc #ICON_OFFSET_DIFFICULTY
    sta score_icons + 2
    txa
    lsr
    lsr
    and #1
    clc
    adc #ICON_OFFSET_CONTROLLER
    sta score_icons + 3
    rts
}

; Insert empty entry into high score table.
; Arguments:
;  X: offset of the entry in highscore_table
insert_highscore_entry {
    ; Move entries down.
    ldy #.sizeof(highscore_table) - 17
    stx loop + 1
loop:
    cpy #$00
    beq done
    lda highscore_table, y
    sta highscore_table + 16, y
    dey
    jmp loop
done:

    ; Clear entry.
    ldx #0
    lda #$20
:   sta highscore_table,y
    iny
    inx
    cpx #13
    bne :-
    lda current_score
    sta highscore_table, y
    lda current_score + 1
    sta highscore_table + 1, y
    lda current_game_mode
    sta highscore_table + 2, y
    rts
}

; Find index of current score in high score table.
; Arguments:
;   current_score: score to compare against
; Result:
;   X: offset of the entry in highscore_table, $ff if the score is too low.
find_highscore_position {
    ldx #0
loop:
    lda current_score + 1
    cmp highscore_table + 14,x
    bcc found
    bne next
    lda current_score
    cmp highscore_table + 13,x
    bcc found
next:
    txa
    clc
    adc #16
    cmp #.sizeof(highscore_table)
    bcc loop

    ; score is too low
    ldx #$ff
found:
    rts
}


.section data 

; Initial high score table.
highscore_table .align $100 { 
    ;                                       cddSSs
    .data "spockie      ":screen, 450:2, %00110010 ; 1
    .data "dillo        ":screen, 350:2, %00110111 ; 2
    .data "exa          ":screen, 300:2, %00000010 ; 3
    .data "dillo        ":screen, 295:2, %00101000 ; 4
    .data "exa          ":screen, 250:2, %00010111 ; 5
    .data "spockie      ":screen, 245:2, %00110100 ; 6
    .data "thunderblade ":screen, 200:2, %00010101 ; 7
    .data "spockie      ":screen, 190:2, %00100001 ; 8
    .data "spockie      ":screen, 180:2, %00101110 ; 9
    .data "thunderblade ":screen, 175:2, %00010010 ; 10
}

.section reserved

current_score .reserve 2
current_game_mode .reserve 1

score_digits .reserve 5 ; digits of the score, least significant digit first

score_icons .reserve 4 ; screen codes for shape, size, difficulty, controller
score_icon_shape = score_icons
score_icon_size = score_icons + 1
score_icon_difficulty = score_icons + 2
score_icon_controller = score_icons + 3
