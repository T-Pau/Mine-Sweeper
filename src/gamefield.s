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

MAX_WIDTH = 10
MAX_HEIGHT = 10
MAX_NEIGHBORS = 8
MAX_GAMEFIELD_SIZE = (MAX_WIDTH + 1) * (MAX_HEIGHT + 2) + 2

FIELD_REVEALED = $80
FIELD_MARKED = $40
FIELD_MINE = $20
FIELD_BORDER = $ff

.section code

; Initialize game field
; Arguments:
;   X: width
;   Y: height
;   A: number of mines
init_field {
    ; Store parameters.
    sta mines
    sta marked_mines
    stx width
    sty height
    inx
    stx row_span

    ; Calculate row offsets.
    inx
    txa
    ldy #0
    clc
:   sta gamefield_row_offsets,y
    adc row_span
    iny 
    cpy height
    bne :-
    adc row_span
    sta gamefield_size

    ; Clear field.
    tax
    lda #0
:   dex
    sta gamefield,x
    bne :-

    ; Set top and bottom borders.
    ldy gamefield_size
    dey
    ldx #0
    lda #FIELD_BORDER
:   sta gamefield,x
    sta gamefield,y
    dey
    inx
    cpx row_span
    bne :-
    sta gamefield,y
    dey
    sta gamefield,y

    ; Set side border.
    ldy #0
:   ldx gamefield_row_offsets,y
    sta gamefield - 1,x
    iny
    cpy height
    bne :-

    ; Calculate neighbors.
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
    rts
}


; Adjust count for neighboring fields
; Arguments:
;   Y: index of field with new mine
adjust_neighbors {
    tya
    ; Subtract row_span + 1 to get index of first neighbor.
    clc
    sbc row_span
    sta source_ptr
    lda #>gamefield
    sta source_ptr + 1

    ldx #MAX_NEIGHBORS - 1
loop:
    ldy neighbor_offsets,x
    lda (source_ptr),y
    cmp #$10
    bcs :+
    clc
    adc #1
    sta (source_ptr),y
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

width .reserve 1
height .reserve 1
mines .reserve 1

marked_fields .reserve 1
marked_mines .reserve 1
