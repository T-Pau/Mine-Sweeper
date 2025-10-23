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

.section graphics_game

game_bitmap .align $2000 {
    .binary_file "game-bitmap.prg" .start 2
}

game_screen .align $400 {
    .binary_file "game-screen.prg" .start 2
    .data 0, 0, 0, 0, 0, 0, 0, 0
    .data 0, 0, 0, 0, 0, 0, 0, 0
    sprite_pointer pointer_sprite
    sprite_pointer pointer_sprite, 1
    .data 0, 0, 0, 0, 0, 0
}

.section data

ICON_EMPTY = 9
ICON_FLAG = 10
ICON_SKULL = 11

field_icons {
    .data $ff,  $ff,  $f4,  $df,  $cf,  $cf,  $df,  $ff,  $fe,  $ff,  $7e,  $df,  $ce,  $cf,  $de,  $ff ; 0
    .data $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $fe,  $ff,  $fe,  $df,  $ce,  $cf,  $de,  $ff ; 1
    .data $ff,  $ff,  $f4,  $ff,  $ff,  $ff,  $ff,  $f4,  $fe,  $ff,  $7e,  $df,  $ce,  $cf,  $de,  $7f ; 2
    .data $ff,  $ff,  $f4,  $ff,  $ff,  $ff,  $ff,  $f4,  $fe,  $ff,  $7e,  $df,  $ce,  $cf,  $de,  $7f ; 3
    .data $ff,  $ff,  $ff,  $df,  $cf,  $cf,  $df,  $f4,  $fe,  $ff,  $fe,  $df,  $ce,  $cf,  $de,  $7f ; 4
    .data $ff,  $ff,  $f4,  $df,  $cf,  $cf,  $df,  $f4,  $fe,  $ff,  $7e,  $ff,  $fe,  $ff,  $fe,  $7f ; 5
    .data $ff,  $ff,  $f4,  $df,  $cf,  $cf,  $df,  $f4,  $fe,  $ff,  $7e,  $ff,  $fe,  $ff,  $fe,  $7f ; 6
    .data $ff,  $ff,  $f4,  $ff,  $ff,  $ff,  $ff,  $ff,  $fe,  $ff,  $7e,  $df,  $ce,  $cf,  $de,  $ff ; 7
    .data $ff,  $ff,  $f4,  $df,  $cf,  $cf,  $df,  $f4,  $fe,  $ff,  $7e,  $df,  $ce,  $cf,  $de,  $7f ; 8
    .data $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $fe,  $ff,  $fe,  $ff,  $fe,  $ff,  $fe,  $ff ; empty
    .data $ff,  $fe,  $fd,  $fd,  $f4,  $e0,  $d2,  $c6,  $7e,  $7f,  $be,  $ff,  $7e,  $2f,  $1e,  $0f ; flag
    .data $06,  $0b,  $1f,  $1b,  $12,  $12,  $08,  $06,  $42,  $43,  $92,  $53,  $12,  $13,  $42,  $43 ; skull

    .data $df,  $cf,  $cf,  $df,  $f4,  $ff,  $ff,  $bb,  $de,  $cf,  $ce,  $df,  $7e,  $ff,  $fe,  $bb ; 0
    .data $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $bb,  $de,  $cf,  $ce,  $df,  $fe,  $ff,  $fe,  $bb ; 1
    .data $df,  $cf,  $cf,  $df,  $f4,  $ff,  $ff,  $bb,  $fe,  $ff,  $fe,  $ff,  $7e,  $ff,  $fe,  $bb ; 2
    .data $ff,  $ff,  $ff,  $ff,  $f4,  $ff,  $ff,  $bb,  $de,  $cf,  $ce,  $df,  $7e,  $ff,  $fe,  $bb ; 3
    .data $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $bb,  $de,  $cf,  $ce,  $df,  $fe,  $ff,  $fe,  $bb ; 4
    .data $ff,  $ff,  $ff,  $ff,  $f4,  $ff,  $ff,  $bb,  $de,  $cf,  $ce,  $df,  $7e,  $ff,  $fe,  $bb ; 5
    .data $df,  $cf,  $cf,  $df,  $f4,  $ff,  $ff,  $bb,  $de,  $cf,  $ce,  $df,  $7e,  $ff,  $fe,  $bb ; 6
    .data $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $bb,  $de,  $cf,  $ce,  $df,  $fe,  $ff,  $fe,  $bb ; 7
    .data $df,  $cf,  $cf,  $df,  $f4,  $ff,  $ff,  $bb,  $de,  $cf,  $ce,  $df,  $7e,  $ff,  $fe,  $bb ; 8
    .data $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $bb,  $fe,  $ff,  $fe,  $ff,  $fe,  $ff,  $fe,  $bb ; empty
    .data $c8,  $c8,  $c0,  $d0,  $e0,  $f4,  $ff,  $bb,  $0e,  $0f,  $0e,  $1f,  $2e,  $7f,  $fe,  $bb ; flag
    .data $00,  $ce,  $60,  $04,  $01,  $d4,  $50,  $bb,  $02,  $4f,  $16,  $43,  $02,  $5f,  $16,  $bb ; skull
}

DIGIT_EMPTY = $0a

digits_left {
    .data $00, $74, $dc, $cc, $cc, $dc, $74, $00
    .data $00, $30, $30, $30, $30, $30, $30, $00
    .data $00, $74, $cc, $1c, $74, $d0, $fc, $00
    .data $00, $f4, $1c, $3c, $0c, $dc, $74, $00
    .data $00, $1c, $7c, $cc, $fc, $0c, $0c, $00
    .data $00, $fc, $c0, $f4, $1c, $1c, $f4, $00
    .data $00, $7c, $c0, $f4, $cc, $cc, $74, $00
    .data $00, $f4, $0c, $0c, $0c, $0c, $0c, $00
    .data $00, $74, $cc, $74, $cc, $cc, $74, $00
    .data $00, $74, $cc, $cc, $7c, $cc, $74, $00
    .data $00, $00, $00, $00, $00, $00, $00, $00
}

digits_right {
    .data $00, $1d, $37, $33, $33, $37, $1d, $00
    .data $00, $0c, $0c, $0c, $0c, $0c, $0c, $00
    .data $00, $1d, $33, $07, $1d, $34, $3f, $00
    .data $00, $3d, $07, $0f, $03, $37, $1d, $00
    .data $00, $07, $1f, $33, $3f, $03, $03, $00
    .data $00, $3f, $30, $3d, $07, $07, $3d, $00
    .data $00, $1f, $30, $3d, $33, $33, $1d, $00
    .data $00, $3d, $03, $03, $03, $03, $03, $00
    .data $00, $1d, $33, $1d, $33, $33, $1d, $00
    .data $00, $1d, $33, $33, $1f, $33, $1d, $00
    .data $00, $00, $00, $00, $00, $00, $00, $00
}

game_color {
    .binary_file "game-color.prg" .start 2
}

