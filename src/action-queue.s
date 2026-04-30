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

; Maintain a queue of actions to be performed at the bottom of the screen.

.section code

; Maximum number of actions in the queue.
BOTTOM_ACTION_QUEUE_SIZE = 4

; Clear the queue of actions to be performed at the bottom of the screen.
.macro clear_bottom_actions {
    ldx #0
    stx bottom_actions_fill
}

; Clear the queue of actions to be performed at the bottom of the screen.
clear_bottom_actions {
    clear_bottom_actions
    rts
}

; Set the next action to be performed at the bottom of the screen, clearing the queue.
; Arguments:
;   addr: address of the action
.macro set_bottom_action addr {
    lda #<addr
    ldy #>addr
    jsr set_bottom_action
}

; Set the next action to be performed at the bottom of the screen, clearing the queue.
; Arguments:
;   A/Y: address of the action
set_bottom_action {
    ldx #2
    stx bottom_actions_fill
    sta bottom_actions
    sty bottom_actions + 1
    rts
}

; Add action to the queue of actions to be performed at the bottom of the screen.
; Arguments:
;   addr: address of the action
.macro add_bottom_action addr {
    lda #<addr
    ldy #>addr
    jsr add_bottom_action
}

; Add action to the queue of actions to be performed at the bottom of the screen
; Arguments:
;   A/Y: address of the action
add_bottom_action {
    ldx bottom_actions_fill
    sta bottom_actions, x
    tya
    sta bottom_actions + 1, x
    inx
    inx
    stx bottom_actions_fill
    rts
}

; Add wait_for_command and action to the action queue.
; Arguments:
;   addr: address of the action
.macro add_bottom_action_after_command addr {
    lda #<addr
    ldy #>addr
    jsr add_bottom_action_after_command
}

; Add wait_for_command and action to the action queue.
; Arguments:
;   A/Y: address of the action
add_bottom_action_after_command {
    ldx bottom_actions_fill
    sta bottom_actions + 2, x
    tya
    sta bottom_actions + 3, x
    lda #<wait_for_command
    sta bottom_actions, x
    lda #>wait_for_command
    sta bottom_actions + 1, x
    inx
    inx
    inx
    inx
    stx bottom_actions_fill
    rts
}

; Activate the next action to be performed at the bottom of the screen
; Preserves: Y
activate_next_bottom_action {
    ldx bottom_actions_fill
    beq done
    dex
    dex
    stx bottom_actions_fill
    beq done
    ldx #0
:   lda bottom_actions + 2, x
    sta bottom_actions, x
    lda bottom_actions + 3, x
    sta bottom_actions + 1, x
    inx
    inx
    cpx bottom_actions_fill
    bne :-
done:
    rts
}

; Call the action at the bottom of the screen, if any.
call_bottom_action {
    lda bottom_actions_fill
    beq :+
    jmp (bottom_actions)
:   rts
}

.section reserved

bottom_actions .reserve BOTTOM_ACTION_QUEUE_SIZE * 2
bottom_actions_fill .reserve 1
