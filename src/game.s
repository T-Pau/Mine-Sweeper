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

GAME_BITMAP_OFFSET(xx, yy) = game_bitmap + xx * 8 + yy * $140
FIELD_POSITION_START = GAME_BITMAP_OFFSET(2, 1)

; XLR8: this should be a function, but that doesn't get evaluated 
.macro sprite_pointer address, offset = 0 {
    .data (address / 64) & $ff + offset:1
}

; Display digit in bitmap.
; Arguments:
;   A: digit
;   digits: graphics to use
;   xx: x coordinate to display at
;   yy: y coordinate to display at
.macro display_digit digits, xx, yy {
    asl
    asl
    asl
    tax
    ldy #0
:   lda digits,x
    sta GAME_BITMAP_OFFSET(xx, yy),y
    inx
    iny
    cpy #8
    bne :-
}

.section code

launch_game {
    set_bottom_next_action launch_game_faded_out
    set_bottom_action title_fade_out
    set_command COMMAND_PREPARE_GAME
    rts
}

launch_game_faded_out {
    set_bottom_next_action launch_game_done
    set_bottom_action wait_for_command
    rts
}

launch_game_done {
    lda #COMMAND_START_GAME
    sta current_command
    set_irq_table music_irq_table
    rts
}

prepare_game {
    rl_expand game_bitmap, game_small_bitmap
    rl_expand game_screen, game_small_screen
    rl_expand explosion_sprite, explosion_sprite_rl
    ldx #$80
:   lda title_pointer_sprite,x
    sta game_pointer_sprite,x
    dex
    bpl :-
    ldx #SPRITE_POINTER(game_pointer_sprite)
    stx game_screen + $3f8
    inx
    stx game_screen + $3f9

    ; TODO: Don't hardcode parameters.
    lda #3
    sta lives_left
    lda #16
    ldx #10
    ldy #10
    jsr init_field
    jsr compute_field_positions
    jsr clear_field_icons
    jsr display_lives_left
    jsr display_marked_fields
    rts
}

start_game {
    lda #COLOR_BLACK
    sta VIC_BACKGROUND_COLOR
    set_vic_bank $8000
    set_vic_text game_screen, game_bitmap
    set_vic_bitmap_mode
    lda #VIC_SCREEN_WIDTH_40 | VIC_SCREEN_MULTICOLOR
    sta VIC_CONTROL_2

    rl_expand COLOR_RAM, game_small_color

    ldx #$03
    stx VIC_SPRITE_ENABLE
    ldx #COLOR_WHITE
    stx VIC_SPRITE_0_COLOR
    dex
    stx VIC_SPRITE_1_COLOR
    ldx #0
    stx pointer_x
    stx pointer_x + 1
    stx pointer_y

    lda #COLOR_RED
    sta VIC_SPRITE_2_COLOR
    lda #COLOR_BROWN
    sta VIC_SPRITE_MULTICOLOR_0
    lda #COLOR_YELLOW
    sta VIC_SPRITE_MULTICOLOR_1
    lda #$04
    sta VIC_SPRITE_MULTICOLOR

    jsr reset_time
    ldx #$ff
    stx animation_index

    set_irq_table game_irq_table
    rts
}

compute_field_positions {
    lda #<FIELD_POSITION_START
    sta source_ptr
    sta destination_ptr
    lda #>FIELD_POSITION_START
    sta source_ptr + 1
    sta destination_ptr + 1
    ldy height
    iny
    sty tmp
    ldx width
    inx
    stx row_end + 1 

    ldy #0
row_loop:
    ldx #0
column_loop:
    lda source_ptr
    sta field_position_low,y
    clc
    adc #16
    sta source_ptr
    lda source_ptr + 1
    sta field_position_high,y
    adc #0
    sta source_ptr + 1
    iny
    inx
row_end:
    cpx #0
    bne column_loop
    lda destination_ptr
    clc
    adc #<640
    sta destination_ptr
    sta source_ptr
    lda destination_ptr + 1
    adc #>640
    sta source_ptr + 1
    sta destination_ptr + 1
    dec tmp
    bne row_loop
    rts
}

game_won {
    lda CIA1_TOD_SECONDS
    tax
    and #$f
    ora #$30
    sta screen_won + $61
    txa
    lsr
    lsr
    lsr
    lsr
    ora #$30
    sta screen_won + $60
    lda CIA1_TOD_MINUTES
    tax
    and #$f
    ora #$30
    sta screen_won + $5e
    txa
    lsr
    lsr
    lsr
    lsr
    ; TODO: Space instead of leading 0?
    ora #$30
    sta screen_won + $5d
    lda #<screen_won
    ldy #>screen_won
    jmp end_game
}

game_lost {
    lda #<screen_failed
    ldy #>screen_failed
    jmp end_game
}

end_game {
    jsr copy_2x2_screen
    set_bottom_action title_fade_in
    set_bottom_next_action attract_faded_in
    jsr setup_title
    rts
}

handle_input {
    jsr read_input

    ; Handle button clicks.
    lda current_command
    bne done
    lda animation_index
    bpl done
    lda buttons
    beq done
    jsr pointer_to_index
    beq done
    lda buttons
    lsr
    bcc :+
    jmp handle_left_click
:   jmp handle_right_click
done:
    rts
}

reset_time {
    lda #$00
    sta CIA1_TOD_HOURS
    sta CIA1_TOD_MINUTES
    sta CIA1_TOD_SECONDS
    sta CIA1_TOD_SUB_SECOND
    rts
}

display_time {
    lda CIA1_TOD_SECONDS
    and #$0f
    display_digit digits_left, 38, 21
    lda CIA1_TOD_SECONDS
    lsr
    lsr
    lsr
    lsr
    display_digit digits_left, 37, 21
    lda CIA1_TOD_MINUTES
    and #$0f
    display_digit digits_right, 35, 21
    lda CIA1_TOD_MINUTES
    lsr
    lsr
    lsr
    lsr
    bne :+
    lda #DIGIT_EMPTY
:   display_digit digits_right, 34, 21
    rts
}

display_lives_left {
    lda lives_left
    display_digit digits_left, 38, 19
    rts
}

display_marked_fields {
    lda marked_fields
    ldx #0
:   cmp #10
    bcc done
    sec
    sbc #10
    inx
    bne :-
done:
    stx tens + 1
    display_digit digits_left, 38, 23
tens:
    lda #$00
    bne :+
    lda #DIGIT_EMPTY
:   display_digit digits_left, 37, 23  
    rts      
}

game_irq {
    jsr music_play
    jsr display_time
    jsr handle_input
    jsr handle_animation
    rts
}

start_animation {
    lda #0
    sta animation_index
    lda #7
    sta VIC_SPRITE_ENABLE
    lda pointer_x
    sec
    sbc #$18
    and #$f0
    clc
    adc #$18
    sta VIC_SPRITE_2_X
    lda pointer_y
    sec
    sbc #$3a
    and #$f0
    clc
    adc #$3a
    sta VIC_SPRITE_2_Y
    jmp handle_animation
}

handle_animation {
    ldx animation_index
    cpx #$ff
    beq end
    cpx #.sizeof(animation_sprite)
    bcc :+
    ldx #$ff
    stx animation_index
    lda #3
    sta VIC_SPRITE_ENABLE
    jmp animation_done

:   lda animation_sprite,x
    sta game_screen + $3fa
    inx
    stx animation_index
end:
    rts
}

animation_done {
    lda lives_left
    bne :+
    lda #COMMAND_GAME_LOST
    bne game_end
:   jsr check_win
    bne done
    lda #COMMAND_GAME_WON
game_end:
    sta current_command
    lda #KEY_FIRE
    sta last_key
done:
    rts
}

; Handle left click on field X.
; Arguments:
;   X: field index
handle_left_click {
    lda gamefield,x
    tay
    cmp #FIELD_MARKED
    bcs end
    ora #FIELD_REVEALED
    sta gamefield,x
    and #FIELD_MINE
    bne explode
    tya
    bne :+
    ldy game_reveal_zeroes
    beq :+
    stx reveal_zero_stack
    ldy #1
    sty reveal_zero_index
    ldy #COMMAND_REVEAL_ZERO
    sty current_command
:   jmp display_field_icon

explode:
    dec mines
    dec lives_left
    lda #ICON_SKULL
    jsr display_field_icon
    jsr display_lives_left
    jsr start_animation
end:
    rts
}

; Handle right click on field X.
; Arguments:
;   X: field index
handle_right_click {
    lda gamefield,x
    bmi end
    eor #FIELD_MARKED
    sta gamefield,x
    cmp #FIELD_MARKED
    bcs mark
    ; Unmark field
    dec marked_fields
    and #FIELD_MINE
    beq :+
    dec marked_mines
:   lda #ICON_EMPTY
    bne update
mark:
    inc marked_fields
    and #FIELD_MINE
    beq :+
    inc marked_mines
:   lda #ICON_FLAG
update:
    jsr display_field_icon
    jsr display_marked_fields
    jsr check_win
    bne end
    lda #KEY_F7
    sta last_key
    set_command COMMAND_GAME_WON
end:
    rts
}

; Reveal all neighboring zeros and their neighbors.
reveal_zero {
    ldy reveal_zero_index
    dey
    lda reveal_zero_stack,y
    sty reveal_zero_index
    clc
    sbc row_span
    sta offset + 1
    ldy #0
neighbor_loop:
    lda neighbor_offsets,y
    clc
offset:
    adc #0
    tax
    lda gamefield,x
    bmi next_neighbor
    ora #FIELD_REVEALED
    sta gamefield,x
    and #$0f
    bne :+
    txa
    ldx reveal_zero_index
    sta reveal_zero_stack,x
    inx
    stx reveal_zero_index
    tax
    lda #0
:   sty restore + 1
    jsr display_field_icon
restore:
    ldy #0
next_neighbor:
    iny
    cpy #8
    bne neighbor_loop
    lda reveal_zero_index
    bne reveal_zero
    rts
}


; Convert pointer coordinates to gamefield index.
; Returns:
;   X: index
;   Z: set if pointer outside gamefield.
pointer_to_index {
    lda pointer_y
    sec
    sbc #$4a
    lsr
    lsr
    lsr
    lsr
    cmp height
    bcs invalid
    tay

    ldx pointer_x + 1
    bne invalid
    lda pointer_x
    sec
    sbc #$38
    lsr
    lsr
    lsr
    lsr
    cmp width
    bcs invalid
    clc
    adc gamefield_row_offsets,y
    tax
    rts
invalid:
    ldx #0
    rts
}

update_pointer {
    ldx pointer_x
    ldy pointer_x + 1
    bne high_x
    ldy #$00
    cpx #$17
    bcs set_x
    ldx #$17
    bne set_x
high_x:
    ldy #$03
    cpx #$57
    bcc set_x
    ldx #$56
set_x:
    stx pointer_x
    stx VIC_SPRITE_0_X
    stx VIC_SPRITE_1_X
    sty VIC_SPRITE_X_MSB
    ldx pointer_y
    cpx #$31
    bcs :+
    ldx #$31
:   cpx #$f9
    bcc :+
    ldx #$f8
:   stx pointer_y
    stx VIC_SPRITE_0_Y
    stx VIC_SPRITE_1_Y
    rts
}

; Clear displayed playing field.
clear_field_icons {
    ldx #1
:   lda #ICON_TOP
    stx restore_top + 1
;    jsr display_field_icon
restore_top:
    ldx #0
    inx
    cpx gamefield_row_offsets
    bne :-

    lda gamefield_size
    sec
    sbc width
    tax
loop:
    lda #ICON_EMPTY
    ldy gamefield,x
    cpy #FIELD_BORDER
    bne :+
    lda #ICON_LEFT
:   stx restore + 1
    jsr display_field_icon
restore:    
    ldx #0
next:    
    dex
    cpx width
    bne loop
    rts
}

; Display icon for field.
; Arguments:
;   A: icon index
;   X: field index
display_field_icon {
    asl a
    asl a
    asl a
    asl a
    sta icon_offset + 1
    lda field_position_low,x
    sta destination_up + 1
    clc
    adc #<320
    sta destination_down + 1
    lda field_position_high,x
    sta destination_up + 2
    adc #>320
    sta destination_down + 2
icon_offset:
    ldx #$00
    ldy #$00
:   lda field_icons,x
destination_up:
    sta game_bitmap,y
    lda field_icons + .sizeof(field_icons)/2,x
destination_down:
    sta game_bitmap,y
    inx
    iny
    cpy #$10
    bne :-
    rts
}

.section data

game_irq_table {
    .data SCREEN_TOP:2, game_irq
}


music_irq_table {
    .data SCREEN_TOP:2, music_play
}

animation_sprite {
    .repeat i, 9 {
        sprite_pointer explosion_sprite, i
        sprite_pointer explosion_sprite, i
        sprite_pointer explosion_sprite, i
    }
}

.section reserved

lives_left .reserve 1

field_position_low .reserve MAX_GAMEFIELD_SIZE
field_position_high .reserve MAX_GAMEFIELD_SIZE

animation_index .reserve 1


reveal_zero_stack .reserve MAX_WIDTH * MAX_HEIGHT
reveal_zero_index .reserve 1 ; Points to first free element in reveal_zero_stack.

