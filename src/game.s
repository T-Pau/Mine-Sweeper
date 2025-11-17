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

GAME_MAP_ORIGINAL = 0
GAME_MAP_SMALL = 2
GAME_MAP_LARGE = 4

; XLR8: this should be a function, but that doesn't get evaluated 
.macro sprite_pointer address, offset = 0 {
    .data (address / 64) & $ff + offset:1
}

.section code

; Arguments:
;   A: digit
;   Y: x coordinate * 8
display_digit {
    asl
    asl
    asl
    tax
:   lda digits,x
    sta (destination_ptr),y
    inx
    iny
    tya
    and #$07
    bne :-
    rts
}

launch_original_game {
    set_bottom_next_action launch_game_faded_out
    set_bottom_action title_fade_out
    set_command COMMAND_PREPARE_GAME
    
    lda #GAME_MAP_ORIGINAL
    sta game_map
    lda #10
    sta width
    lda #10
    sta height
    lda #0
    sta reveal_zeroes
    lda #3
    sta lives_left
    lda #GAME_ORIGINAL_OFFSET_X
    sta offset_x
    lda #GAME_ORIGINAL_OFFSET_Y
    sta offset_y
    lda #16
    sta mines

    jmp setup_square
}

launch_game {
    set_bottom_next_action launch_game_faded_out
    set_bottom_action title_fade_out
    set_command COMMAND_PREPARE_GAME

    ldx game_size
    lda game_map,x
    sta game_map

    lda #1
    sta reveal_zeroes
    lda #3
    sta lives_left
    lda game_size
    asl
    ora game_shape
    tay
    lda game_width,y
    sta width
    lda game_height,y
    sta height
    lda game_offset_x,y
    sta offset_x
    lda game_offset_y,y
    sta offset_y
    sty tmp
    lda game_difficulty
    asl
    asl
    asl
    ora tmp
    tay
    lda game_mines,y
    sta mines

    jmp setup_shape
}

; Set up game map to use.
; Arguments:
;   A: game map index
set_game_map {
    ldx game_map
    lda game_map_lives_position,x
    sta position_lives
    lda game_map_lives_position + 1,x
    sta position_lives + 1
    lda game_map_time_position,x
    sta position_time
    lda game_map_time_position + 1,x
    sta position_time + 1
    lda game_map_mines_position,x
    sta position_mines
    lda game_map_mines_position + 1,x
    sta position_mines + 1

    lda game_map_bitmap,x
    sta source_ptr
    lda game_map_bitmap + 1,x
    sta source_ptr + 1
    store_word destination_ptr, game_bitmap
    jsr rl_expand

    ldx game_map
    lda game_map_screen,x
    sta source_ptr
    lda game_map_screen + 1,x
    sta source_ptr + 1
    store_word destination_ptr, game_screen
    jsr rl_expand

    rl_expand explosion_sprite, explosion_sprite_rl

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
    jsr set_game_map
    ldx #$80
:   lda title_pointer_sprite,x
    sta game_pointer_sprite,x
    dex
    bpl :-
    ldx #SPRITE_POINTER(game_pointer_sprite)
    stx game_screen + $3f8
    inx
    stx game_screen + $3f9

    jsr init_field
    jsr compute_field_positions
    jsr clear_field_icons
    jsr display_lives_left
    jsr display_mines
    rts
}

start_game {
    lda #GAME_BACKGROUND_COLOR
    sta VIC_BACKGROUND_COLOR
    set_vic_bank $8000
    set_vic_text game_screen, game_bitmap
    set_vic_bitmap_mode
    lda #VIC_SCREEN_WIDTH_40 | VIC_SCREEN_MULTICOLOR
    sta VIC_CONTROL_2

    ldx game_map
    lda game_map_color,x
    sta source_ptr
    lda game_map_color + 1,x
    sta source_ptr + 1
    store_word destination_ptr, COLOR_RAM
    jsr rl_expand

    ldx #$03
    stx VIC_SPRITE_ENABLE
    ldx #COLOR_WHITE
    stx VIC_SPRITE_0_COLOR
    dex
    stx VIC_SPRITE_1_COLOR

    ldx #0
    stx pointer_min_y

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
    lda #0
    sta destination_ptr + 1
    lda offset_y ; *8 <= $18
    asl ; *16 <= $30
    asl ; *32 <= $60
    asl ; *64 <= $c0
    sta destination_ptr
    asl ; *128 <= $180
    rol destination_ptr + 1
    asl ; *256 <= $300
    rol destination_ptr + 1
    adc destination_ptr
    sta destination_ptr
    bcc :+
    inc destination_ptr + 1
    clc
:   lda offset_x
    adc destination_ptr
    sta destination_ptr
    bcc :+
    inc destination_ptr + 1

:   lda destination_ptr + 1
    ora #>game_bitmap
    sta destination_ptr + 1

    lda destination_ptr
    sec
    sbc #16
    sta destination_ptr
    sta source_ptr
    bcs :+
    dec destination_ptr + 1
:   lda destination_ptr + 1
    sta source_ptr + 1

    ldx #0
    ldy row_span

row_loop:
    lda row_shift,x
    beq column_loop
    clc
    adc source_ptr
    sta source_ptr
    bcc column_loop
    inc source_ptr + 1
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
    lda gamefield,y
    cmp #FIELD_BORDER
    bne column_loop
    ; Next row
    lda destination_ptr
    clc
    adc #<640
    sta destination_ptr
    sta source_ptr
    lda destination_ptr + 1
    adc #>640
    sta source_ptr + 1
    sta destination_ptr + 1
    inx
    cpx height
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
    copy_word destination_ptr, position_time
    lda CIA1_TOD_SECONDS
    and #$0f
    ldy #$20
    jsr display_digit
    lda CIA1_TOD_SECONDS
    lsr
    lsr
    lsr
    lsr
    ldy #$18
    jsr display_digit
    lda CIA1_TOD_MINUTES
    and #$0f
    clc 
    adc #DIGITS_RIGHT_OFFSET
    ldy #$08
    jsr display_digit
    lda CIA1_TOD_MINUTES
    lsr
    lsr
    lsr
    lsr
    bne :+
    lda #DIGIT_EMPTY
:   clc
    adc #DIGITS_RIGHT_OFFSET
    ldy #$00
    jmp display_digit
}

display_lives_left {
    copy_word destination_ptr, position_lives
    lda lives_left
    ldy #0
    jmp display_digit
}

display_mines {
    copy_word destination_ptr, position_mines
    ldx #DIGIT_EMPTY
    lda mines
    sec
    sbc marked_fields
    bcs :+
    eor #$ff
    adc #$01
    inx
:   stx sign + 1
    ldx #0
:   cmp #10
    bcc done
    sec
    sbc #10
    inx
    bne :-
done:
    stx tens + 1
    ldy #$10
    jsr display_digit
tens:
    lda #$00
    bne :+
    ldx #DIGIT_EMPTY
    lda sign + 1
    stx sign + 1
:   ldy #$08
    jsr display_digit
sign:
    lda #$00
    ldy #$00
    jmp display_digit
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

    ; Calculate sprite X position.
    ldy pointer_row
    ldx #0
    lda pointer_column
    asl
    asl
    asl
    asl
    bcc :+
    inx
    clc
:   adc row_shift,y
    bcc :+
    inx
    clc
:   adc offset_x
    bcc :+
    inx
    clc
:   adc #$18 
    bcc :+
    inx
:   sta VIC_SPRITE_2_X
    lda VIC_SPRITE_X_MSB
    cpx #0
    beq :+
    ora #$04
    bne high_x
:   and #$fb
high_x:
    sta VIC_SPRITE_X_MSB

    ; Calculate sprite Y position.
    tya
    asl
    asl
    asl
    asl
    adc offset_y
    adc #$31 + 8 ; offset_y is one row above actual field due to top border of field
    sta VIC_SPRITE_2_Y

    lda #7
    sta VIC_SPRITE_ENABLE
    rts
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
.pre_if .false
    txa
    clc
    sbc row_span
    sta offset + 1
    ldy #0
loop:
    lda neighbor_offsets,y
    clc
offset:
    adc #0
    tax
    lda #1
    sty restore + 1
    jsr display_field_icon    
restore:
    ldy #0
    iny
    cpy neighbor_count
    bne loop
    rts
.pre_end

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
    ldy reveal_zeroes
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
    jsr display_mines
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
    jsr display_mines
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
    ldx reveal_zero_stack,y
    sty reveal_zero_index
    txa
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
    cmp #FIELD_MARKED
    bcs next_neighbor
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
    cpy neighbor_count
    bne neighbor_loop
    lda reveal_zero_index
    bne reveal_zero
    rts
}


; Convert pointer coordinates to gamefield index.
; Returns:
;   X: index
;   Z: set if pointer outside gamefield.
;   pointer_column: column of field pointed to
;   pointer_row: row of field pointed to
pointer_to_index {
    lda pointer_y
    sec
    sbc #8
    sbc offset_y
    lsr
    lsr
    lsr
    lsr
    cmp height
    bcs invalid
    tay
    sty pointer_row

    ldx pointer_x + 1
    lda pointer_x
    sec
    sbc offset_x
    bcs :+
    dex
    sec
:   sbc row_shift,y
    bcs :+
    dex
:   lsr
    lsr
    lsr
    lsr
    cpx #0
    beq :+
    clc
    adc #16
:   cmp width
    bcs invalid
    sta pointer_column
    clc
    adc gamefield_row_offsets,y
    tax
    rts
invalid:
    ldx #0
    rts
}

update_pointer {
    lda pointer_x
    ldx pointer_x + 1
    clc
    adc #$17
    bcc :+
    inx
:   sta VIC_SPRITE_0_X
    sta VIC_SPRITE_1_X
    lda VIC_SPRITE_X_MSB
    cpx #0
    beq :+
    ora #$03
    bne high_x
:   and #$fc
high_x:
    sta VIC_SPRITE_X_MSB
    lda pointer_y
    clc
    adc #$31
    sta VIC_SPRITE_0_Y
    sta VIC_SPRITE_1_Y
    rts
}

; Clear displayed playing field.
clear_field_icons {
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
.public field_icon_mask_up = op_field_icon_mask_up + 2
.public field_icon_mask_mid = op_field_icon_mask_mid + 2
.public field_icon_mask_down = op_field_icon_mask_down + 2
.public field_icon_up = op_field_icon_mask_up + 5
.public field_icon_mid = op_field_icon_mask_mid + 5
.public field_icon_down = op_field_icon_mask_down + 5

    asl a
    asl a
    asl a
    asl a
    sta icon_offset + 1
    lda field_position_low,x
    sta source_up + 1
    sta destination_up + 1
    clc
    adc #<320
    sta source_mid + 1
    sta destination_mid + 1
    lda field_position_high,x
    sta source_up + 2
    sta destination_up + 2
    adc #>320
    sta source_mid + 2
    sta destination_mid + 2
    clc
    lda source_mid + 1
    adc #<320
    sta source_down + 1
    sta destination_down + 1
    lda source_mid + 2
    adc #>320
    sta source_down + 2
    sta destination_down + 2
icon_offset:
    ldx #$00
    ldy #$00
source_up:
    lda game_bitmap,y
op_field_icon_mask_up:
    and field_icons_square_mask,x
    ora field_icons_square,x
destination_up:
    sta game_bitmap,y
source_mid:
    lda game_bitmap,y
op_field_icon_mask_mid:
    and field_icons_square_mask + FIELD_ICON_ROW_SIZE,x
    ora field_icons_square + FIELD_ICON_ROW_SIZE,x
destination_mid:
    sta game_bitmap,y
source_down:
    lda game_bitmap,y
op_field_icon_mask_down:
    and field_icons_square_mask + FIELD_ICON_ROW_SIZE * 2,x
    ora field_icons_square + FIELD_ICON_ROW_SIZE * 2,x
destination_down:
    sta game_bitmap,y
    inx
    iny
    cpy #$10
    bne source_up
    rts
}

; Compute row shifts.
; Arguments:
;   A: shift for odd rows
compute_row_shifts {
    ldx #0
    sta shift + 1
:   sta row_shift,x
shift:
    eor #$00
    inx
    cpx height
    bne :-
    rts
}

; Set up for the selected game shape.
setup_shape {
    lda game_shape
    bne :+
    jmp setup_square
:   jmp setup_hex
}

; Set up for square fields.
setup_square {
    lda #0
    jsr compute_row_shifts
    ldx #>field_icons_square
    jsr set_field_icons
    ; TODO: pointer_to_index
    rts
}

; Setup for hex fields.
setup_hex {
    lda #8
    jsr compute_row_shifts
    ldx #>field_icons_hex
    jsr set_field_icons
    ; TODO: pointer_to_index
    rts
}

set_field_icons {
    stx field_icon_up
    stx field_icon_mid
    inx
    stx field_icon_down
    inx 
    stx field_icon_mask_up
    inx
    stx field_icon_mask_mid
    inx
    stx field_icon_mask_down
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
row_shift .reserve MAX_HEIGHT

position_lives .reserve 2
position_time .reserve 2
position_mines .reserve 2

offset_x .reserve 1
offset_y .reserve 1

animation_index .reserve 1

pointer_column .reserve 1
pointer_row .reserve 1

reveal_zero_stack .reserve MAX_WIDTH * MAX_HEIGHT
reveal_zero_index .reserve 1 ; Points to first free element in reveal_zero_stack.

reveal_zeroes .reserve 1

game_map .reserve 1
