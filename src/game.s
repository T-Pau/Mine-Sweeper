GAME_ORIGINAL = 0
GAME_NEW = 1
GAME_HEX = 2

GAME_BITMAP_OFFSET(xx, yy) = game_bitmap + xx * 8 + yy * $140

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
    set_bottom_action menu_fade_out
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


launch_game_original {
    lda #GAME_ORIGINAL
    sta game_mode
    jmp launch_game
}

launch_game_new {
    lda #GAME_NEW
    sta game_mode
    jmp launch_game
}

launch_game_hex {
    lda #GAME_HEX
    sta game_mode
    jmp launch_game
}

prepare_game {
    ; TODO: Take parameters from game_mode.
    lda #3
    sta lives_left
    lda #16
    ldx #10
    ldy #10
    jmp init_field
}

start_game {
    lda #COLOR_BLACK
    sta VIC_BACKGROUND_COLOR
    set_vic_bank $4000
    set_vic_text game_screen, game_bitmap
    set_vic_bitmap_mode
    lda #VIC_SCREEN_WIDTH_40 | VIC_SCREEN_MULTICOLOR
    sta VIC_CONTROL_2

    ldx #250
:   lda game_color - 1,x
    sta COLOR_RAM - 1,x
    lda game_color + 249,x
    sta COLOR_RAM + 249,x
    lda game_color + 499,x
    sta COLOR_RAM + 499,x
    lda game_color + 749,x
    sta COLOR_RAM + 749,x
    dex
    bne :-

    jsr clear_field_icons
    jsr display_lives_left
    jsr display_marked_fields

    ldx #$03
    stx VIC_SPRITE_ENABLE
    ldx #$01
    stx VIC_SPRITE_0_COLOR
    dex
    stx VIC_SPRITE_1_COLOR
    ldx #0
    stx pointer_x
    stx pointer_x + 1
    stx pointer_y

    jsr reset_time

    set_irq_table game_irq_table
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
    set_bottom_action menu_fade_in
    set_bottom_next_action menu_marquee_faded_in
    jsr setup_menu
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
display:
    ldx current_field_x
    ldy current_field_y
    jmp display_field_icon

explode:
    dec mines
    dec lives_left
    ; TODO: Delay game end after explosion animation finishes.
    bne :+
    lda #KEY_FIRE
    sta last_key
    set_command COMMAND_GAME_LOST
:   jsr check_win
    bne :+
    lda #KEY_FIRE
    sta last_key
    set_command COMMAND_GAME_WON
:   jsr display_lives_left
    ; TODO: trigger explosion
    lda #ICON_SKULL
    bne display
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
    ldx current_field_x
    ldy current_field_y
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

; Convert pointer coordinates to gamefield index.
; Returns:
;   X: index
;   Z: set if pointer outside gamefield.
;   current_field_x: x coordinate of field.
;   current_field_y: y coordinate of field.
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
    sta current_field_y
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
    sta current_field_x
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
    ldx #0
    stx current_x + 1
    stx current_y + 1
current_x:    
    ldx #$00
current_y:
    ldy #$0a
    lda #ICON_EMPTY
    jsr display_field_icon
    ldx current_x + 1
    inx
    stx current_x + 1
    cpx width
    bne current_x
    ldx #$00
    stx current_x + 1
    ldy current_y + 1
    iny
    sty current_y + 1
    cpy height
    bne current_y
    rts
}

; Display icon for field.
; Arguments:
;   A: icon index
;   X: X coordinate
;   Y: Y coordinate
display_field_icon {
    asl a
    asl a
    asl a
    asl a
    sta icon_offset + 1
    lda field_x_offset,x
    clc
    adc field_y_low,y
    sta destination_up + 1
    lda field_y_high,y
    adc #$00
    sta destination_up + 2
    lda destination_up + 1
    clc
    adc #$40
    sta destination_down + 1
    lda destination_up + 2
    adc #$01
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

field_x_offset {
    .repeat xx, 10 {
        .data $20 + xx * $10
    }
}

field_y_low {
    .repeat yy, 10 {
        .data <(game_bitmap + $3c0 + yy * $280):1
    }
}   

field_y_high {
    .repeat yy, 10 {
        .data >(game_bitmap + $3c0 + yy * $280):1
    }
}   

.section reserved

game_mode .reserve 1
lives_left .reserve 1

current_field_x .reserve 1
current_field_y .reserve 1