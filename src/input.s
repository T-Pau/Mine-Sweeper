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

.public BUTTON_LEFT = $01
.public BUTTON_RIGHT = $02

; Initialize input handling.
.public init_input {
    lda #$00
    sta last_potx
    sta last_poty
    sta previous_buttons
    sta pointer_x
    sta pointer_x + 1
    sta pointer_y
    sta pointer_min_x
    sta pointer_min_x + 1
    store_word pointer_max_x, 320
    lda #200
    sta pointer_max_y
    rts
}

; Reads mouse and joystick.
; Result:
;   pointer_x: new x position
;   pointer_y: new y position
;   buttons: buttons newly pressed
.public read_input {
    jsr read_mouse
    jsr read_joystick
    jsr constrain_pointer
    jsr update_pointer
    lda previous_buttons
    ldx buttons
    stx previous_buttons
    eor #$03
    and buttons
    sta buttons
    rts
}

; Constrain pointer to min/max values.
constrain_pointer {
    ldx pointer_x + 1
    lda pointer_x
    cpx pointer_min_x + 1
    bcc x_too_small
    lda pointer_x
    cmp pointer_min_x
    bcs check_x_max
x_too_small:
    lda pointer_min_x
    sta pointer_x
    lda pointer_min_x + 1
    sta pointer_x + 1
    jmp check_y
check_x_max:
    cpx pointer_max_x + 1
    bcc check_y
    cmp pointer_max_x
    bcc check_y
    ; x too big
    ldy pointer_max_x + 1
    ldx pointer_max_x
    bne :+
    dey
:   dex
    stx pointer_x
    sty pointer_x + 1

check_y:
    lda pointer_y
    cmp pointer_min_y
    bcs :+
    lda pointer_min_y
    sta pointer_y
    rts
:   cmp pointer_max_y
    bcc :+
    ldx pointer_max_y
    dex
    stx pointer_y 
:   rts
}

read_mouse {
    ldx SID_POT_X
    cpx #$7f
    bne :+
    inx
:   txa
    sec
    sbc last_potx
    and #$7f
    lsr a
    beq read_y
    cmp #$20
    bcc move_right
    ora #$c0
    clc
    adc pointer_x
    sta pointer_x
    bcs end_x
    dec pointer_x + 1
    bpl end_x
    lda #$00
    sta pointer_x
    sta pointer_x + 1
    beq end_x
move_right:
    clc
    adc pointer_x
    sta pointer_x
    bcc end_x
    inc pointer_x + 1
end_x:
    stx last_potx
read_y:
    ldx SID_POT_Y
    cpx #$7f
    bne :+
    inx
:   txa
    sec
    sbc last_poty
    and #$7f
    lsr a
    beq read_buttons
    cmp #$20
    bcc move_up
    ora #$c0
    sec
    eor #$ff
    adc pointer_y
    bcc end_y
    lda #$ff
    bne end_y
move_up:
    sec
    eor #$ff
    adc pointer_y
    bcs end_y
    lda #$00
end_y:
    sta pointer_y
    stx last_poty
read_buttons:
    ldx #0
    lda #$e0
    sta CIA1_DDRB
    lda CIA1_PRB
    lsr
    bcs :+
    inx
    inx
:   and #$08
    bne :+
    inx
:   stx buttons
    rts
}

read_joystick {
    ldx #$e0
    stx CIA1_DDRA
    ldx CIA1_PRA
    txa
    and #$02
    bne down_done
    lda pointer_y
    clc
    adc #$03
    bcc :+
    lda #$ff
:   sta pointer_y
down_done:
    txa
    and #$01
    bne up_done
    lda pointer_y
    sec
    sbc #$03
    bcs :+
    lda #$00
:   sta pointer_y
up_done:
    txa
    and #$04
    bne left_done
    lda pointer_x
    sec
    sbc #$03
    bcs :+
    dec pointer_x + 1
    bpl :+
    lda #0
    sta pointer_x + 1
:   sta pointer_x
left_done:
    txa
    and #$08
    bne right_done
    lda pointer_x
    clc
    adc #$03
    bcc :+
    inc pointer_x + 1
:   sta pointer_x
right_done:
    txa
    ldx #0
    and #$10
    bne :+
    inx
:   lda #$ff
    sta CIA1_DDRA
    lda #$fe
    sta CIA1_PRA
    lda CIA1_PRB
    and #$08
    bne :+
    inx
    inx
:   txa
    ora buttons
    sta buttons
    rts
}

.section reserved

.public pointer_x .reserve 2
.public pointer_y .reserve 1
.public buttons .reserve 1

.public pointer_min_x .reserve 2
.public pointer_max_x .reserve 2
.public pointer_min_y .reserve 1
.public pointer_max_y .reserve 1

last_potx .reserve 1
last_poty .reserve 1
previous_buttons .reserve 1