CLRSCR = $e544
IRQ_END = $ea31


.section zero_page

source_ptr .reserve 2
destination_ptr .reserve 2
tmp .reserve 1

.section code

.public start {
    lda #COLOR_BLACK
    sta VIC_BORDER_COLOR
    sta VIC_BACKGROUND_COLOR
    jsr music_init
    lda #0
    sta current_command
    sta do_reveal_zeros
    sta last_key
    sta current_key
    jsr setup_menu
    jsr menu_marquee_faded_out
    jsr init_irq
    jmp command_loop
}

TEXT_SCREEN_START = SCREEN_RAM + 11 * 40
TEXT_SCREEN_LINES = 14

TEXT_COLOR_START = COLOR_RAM + 11 * 40

; Copy 2x2 page to screen
; Arguments:
;   A/Y: page address
copy_2x2_screen {
    sta source + 1
    sty source + 2
    ldx #<TEXT_SCREEN_START
    ldy #>TEXT_SCREEN_START
    stx destination_lu + 1
    sty destination_lu + 2
    stx destination_ur + 1
    sty destination_ur + 2
    ldx #<(TEXT_SCREEN_START + 40)
    ldy #>(TEXT_SCREEN_START + 40)
    stx destination_dl + 1
    sty destination_dl + 2
    stx destination_dr + 1
    sty destination_dr + 2
    lda #TEXT_SCREEN_LINES / 2
    sta line_count + 1

line_loop:
    ldx #$00
    ldy #$00
source:
    lda $1000,x
destination_lu:
    sta $0400,y
    ora #$80
destination_dl:
    sta $0428,y
    iny
    ora #$40
destination_dr:
    sta $0428,y
    and #$7f
destination_ur:
    sta $0400,y
    iny
    inx
    cpx #$14
    bne source
    lda source + 1
    clc
    adc #$14
    sta source + 1
    bcc :+
    inc source + 2
    clc
:   lda destination_lu + 1
    adc #$50
    sta destination_lu + 1
    sta destination_ur + 1
    bcc :+
    inc destination_lu + 2
    inc destination_ur + 2
    clc
:   lda destination_dl + 1
    adc #$50
    sta destination_dl + 1
    sta destination_dr + 1
    bcc :+
    inc destination_dl + 2
    inc destination_dr + 2
:   dec line_count + 1
line_count:
    lda #$00
    bne line_loop
    rts
}

setup_menu {
    set_vic_bank $0000
    set_vic_text_mode
    lda #0
    sta VIC_SPRITE_ENABLE
    ldx #COLOR_BLACK
    stx VIC_BORDER_COLOR
    stx VIC_BACKGROUND_COLOR
    ldx #COLOR_BROWN
    stx VIC_BACKGROUND_COLOR_1
    ldx #COLOR_ORANGE
    stx VIC_BACKGROUND_COLOR_2
    lda #COLOR_BLACK | 8
    ldx #220
:   sta COLOR_RAM - 1,x
    sta COLOR_RAM + 219,x
    dex
    bne :-
    lda #COLOR_BLACK
    ldx #140
:   sta COLOR_RAM + 11 * 40 -1,x
    sta COLOR_RAM + 11 * 40 + 139,x
    sta COLOR_RAM + 11 * 40 + 279,x
    sta COLOR_RAM + 11 * 40 + 419,x
    dex
    bne :-
    rl_expand SCREEN_RAM, screen_menu
    jsr show_marquee
    set_irq_table irq_menu_table
    lda #0
    sta menu_fade_index
    rts
}

show_marquee {
    lda #VIC_VIDEO_ADDRESS(SCREEN_RAM, charset_2x2)
    sta text_charset
    set_keyhandler_table keyhandler_table_marquee
    ldx #0
    stx menu_marquee_current_page
    rts
}

; Set fade colors
; Arguments:
;   X: start index
; Preserves: X
fade {
    ldy #0
:   lda fade_colors + 12,x
    sta TEXT_COLOR_START + 6 * 40,y
    sta TEXT_COLOR_START + 7 * 40,y
    lda fade_colors + 10,x
    sta TEXT_COLOR_START + 5 * 40,y
    sta TEXT_COLOR_START + 8 * 40,y
    lda fade_colors + 8,x
    sta TEXT_COLOR_START + 4 * 40,y
    sta TEXT_COLOR_START + 9 * 40,y
    lda fade_colors + 6,x
    sta TEXT_COLOR_START + 3 * 40,y
    sta TEXT_COLOR_START + 10 * 40,y
    lda fade_colors + 4,x
    sta TEXT_COLOR_START + 2 * 40,y
    sta TEXT_COLOR_START + 11 * 40,y
    lda fade_colors + 2,x
    sta TEXT_COLOR_START + 1 * 40,y
    sta TEXT_COLOR_START + 12 * 40,y
    lda fade_colors,x
    sta TEXT_COLOR_START,y
    sta TEXT_COLOR_START + 13 * 40,y
    inx
    iny
    cpy #20
    bne :-
:   dex
    lda fade_colors + 12,x
    sta TEXT_COLOR_START + 6 * 40,y
    sta TEXT_COLOR_START + 7 * 40,y
    lda fade_colors + 10,x
    sta TEXT_COLOR_START + 5 * 40,y
    sta TEXT_COLOR_START + 8 * 40,y
    lda fade_colors + 8,x
    sta TEXT_COLOR_START + 4 * 40,y
    sta TEXT_COLOR_START + 9 * 40,y
    lda fade_colors + 6,x
    sta TEXT_COLOR_START + 3 * 40,y
    sta TEXT_COLOR_START + 10 * 40,y
    lda fade_colors + 4,x
    sta TEXT_COLOR_START + 2 * 40,y
    sta TEXT_COLOR_START + 11 * 40,y
    lda fade_colors + 2,x
    sta TEXT_COLOR_START + 1 * 40,y
    sta TEXT_COLOR_START + 12 * 40,y
    lda fade_colors,x
    sta TEXT_COLOR_START,y
    sta TEXT_COLOR_START + 13 * 40,y
    iny
    cpy #$28
    bne :-
    rts
}

.section data

fade_colors {
    .repeat 32 {
        .data COLOR_BLACK
    }
    .data COLOR_BROWN, COLOR_BROWN
    .data COLOR_ORANGE, COLOR_ORANGE
    .data COLOR_LIGHT_RED, COLOR_LIGHT_RED
    .repeat 32 {
        .data COLOR_GREY_3
    }
}
