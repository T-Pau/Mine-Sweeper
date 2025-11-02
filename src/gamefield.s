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

RND = $e09e
RND1 = $e0be
FAC = $61

MAX_WIDTH = 18
MAX_HEIGHT = 11
MAX_NEIGHBORS = 8
MAX_GAMEFIELD_SIZE = (MAX_WIDTH + 1) * (MAX_HEIGHT + 2) + 2

FIELD_REVEALED = $80
FIELD_MARKED = $40
FIELD_MINE = $20
FIELD_BORDER = $ff

.section code

; Initialize game field
init_field {
    lda mines
    sta marked_mines
    ldx width
    inx
    stx row_span

    ; Initialize gamefield
    ldy #0
    sty tmp
    ; Top border
    lda #FIELD_BORDER
:   sta gamefield,y
    iny
    cpy row_span
    bne :-

    ; Side border and rows
row_loop:
    lda #FIELD_BORDER
    sta gamefield,y
    iny
    ldx tmp
    tya
    sta gamefield_row_offsets,x
    lda row_shift,x
    ldx width
    cmp #0
    beq :+
    dex
:   stx row_end + 1
    lda #0
    tax
column_loop:
    sta gamefield,y
    iny
    inx
row_end:
    cpx #0
    bne column_loop    
    ldx tmp
    inx
    stx tmp
    cpx height
    bne row_loop

    ; Bottom border
    lda #FIELD_BORDER
    ldx #0
:   sta gamefield,y
    iny
    inx
    cpx row_span
    bcc :-
    beq :-
    sty gamefield_size

    jsr calculate_neighbors

    lda #$37
    sta $01

    ; Set mines.
    jsr RND
:   jsr RND1
    ldy FAC + 3
    cpy gamefield_size
    bcs :-
    lda gamefield,y
    and #$f0
    bne :-
    lda #FIELD_MINE
    sta gamefield,y
    jsr adjust_neighbors
    dec marked_mines
    bne :-
    lda #0
    sta marked_fields

    lda #$36
    sta $01

    rts
}

calculate_neighbors {
    lda game_shape
    bne :+
    jmp calculate_neighbors_square
:   jmp calculate_neighbors_hex
}

; Calculate neighbors for square fields.
calculate_neighbors_square {
    ldx #0
    stx neighbor_offsets
    inx
    stx neighbor_offsets + 1
    inx
    stx neighbor_offsets + 2
    lda row_span
    tax
    stx neighbor_offsets + 3
    inx
    inx
    stx neighbor_offsets + 4
    asl
    tax
    stx neighbor_offsets + 5
    inx
    stx neighbor_offsets + 6
    inx
    stx neighbor_offsets + 7
    ldx #8
    stx neighbor_count
    rts
}

; Calculate neighbors for hex fields.
calculate_neighbors_hex {
    ldx #1
    stx neighbor_offsets
    inx
    stx neighbor_offsets + 1
    lda row_span
    tax
    stx neighbor_offsets + 2
    inx
    inx
    stx neighbor_offsets + 3
    asl
    tax
    stx neighbor_offsets + 4
    inx
    stx neighbor_offsets + 5
    ldx #6
    stx neighbor_count
    rts
}

; Adjust count for neighboring fields
; Arguments:
;   Y: index of field with new mine
adjust_neighbors {
    tya
    clc
    sbc row_span
    sta load + 1
    sta store + 1

    ldx neighbor_count
    dex
loop:
    ldy neighbor_offsets,x
load:
    lda gamefield,y
    cmp #$10
    bcs :+
    clc
    adc #1
store:
    sta gamefield,y
:   dex
    bpl loop
    rts
}

; Check if game is won.
; Returns:
;   Z: set if won
check_win {
    lda marked_fields
    cmp marked_mines
    bne :+
    cmp mines
:   rts    
}

.section reserved

gamefield .reserve MAX_GAMEFIELD_SIZE .align $100
gamefield_row_offsets .reserve MAX_HEIGHT
row_span .reserve 1
gamefield_size .reserve 1

neighbor_offsets .reserve MAX_NEIGHBORS
neighbor_count .reserve 1

width .reserve 1
height .reserve 1
mines .reserve 1

marked_fields .reserve 1
marked_mines .reserve 1
