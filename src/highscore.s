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
;   5: controller (0: mouse, 1: joystick)

HIGHSCORE_OFFSET_NAME = 0
HIGHSCORE_OFFSET_SCORE = 13
HIGHSCORE_OFFSET_GAME_MODE = 15

HIGHSCORE_SCREEN_SCORE_OFFSET = 14
HIGHSCORE_SCREEN_GAME_MODE_OFFSET = HIGHSCORE_SCREEN_SCORE_OFFSET + 6
ICON_OFFSET_SHAPE = $40
ICON_OFFSET_SIZE = $42
ICON_OFFSET_DIFFICULTY = $46
ICON_OFFSET_CONTROLLER = $49

.section code

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

    ; Convert score to digits using Double Dabble algorithm.
    ldy #HIGHSCORE_OFFSET_SCORE
    lda (source_ptr),y
    sta current_score
    iny
    lda (source_ptr),y
    sta current_score + 1
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

    ; Print score.
    ldy #HIGHSCORE_SCREEN_SCORE_OFFSET
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

    ; Render game mode icons.
    ldy #HIGHSCORE_OFFSET_GAME_MODE
    lda (source_ptr),y
    ldy #HIGHSCORE_SCREEN_GAME_MODE_OFFSET
    tax
    and #1
    clc
    adc #ICON_OFFSET_SHAPE
    sta (destination_ptr),y
    iny
    txa
    lsr
    tax
    and #3
    clc
    adc #ICON_OFFSET_SIZE
    sta (destination_ptr),y
    iny
    txa
    lsr
    lsr
    tax
    and #3
    clc
    adc #ICON_OFFSET_DIFFICULTY
    sta (destination_ptr),y
    iny
    txa
    lsr
    lsr
    and #1
    clc
    adc #ICON_OFFSET_CONTROLLER
    sta (destination_ptr),y

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
    .data "dillo        ":screen, 295:2, %00110000 ; 4
    .data "exa          ":screen, 250:2, %00010111 ; 5
    .data "spockie      ":screen, 245:2, %00110100 ; 6
    .data "thunderblade ":screen, 200:2, %00010101 ; 7
    .data "spockie      ":screen, 190:2, %00100001 ; 8
    .data "spockie      ":screen, 180:2, %00110110 ; 9
    .data "thunderblade ":screen, 175:2, %00010010 ; 10
}

.section reserved

current_score .reserve 2
current_game_mode .reserve 1

score_digits .reserve 5