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

game_map_original_bitmap = game_map_small_bitmap
game_map_original_screen = game_map_small_screen
game_map_original_color = game_map_small_color


ICON_FLAG = 9
ICON_SKULL = 10
ICON_EMPTY = 11
ICON_LEFT = 12

FIELD_ICON_ROW_SIZE = .sizeof(field_icons_square) / 6
field_icons_square_mask = field_icons_square + FIELD_ICON_ROW_SIZE * 3

DIGIT_EMPTY = $0a
DIGIT_MINUS = $0b

DIGITS_RIGHT_OFFSET = .sizeof(digits) / 2 / 8

SPRITE_POINTER(addr) = (addr & $3fff) / 64

.section graphics_game

game_bitmap .align $2000 .reserve 8000
game_screen .align $400 .reserve $400
game_pointer_sprite .align $40 .reserve $80
explosion_sprite .align $40 .reserve $40 * ORIGINAL_EXPLOSION_FRAMES ; MODERN_EXPLOSION_LAYERS

EXPLOSION_SPRITE_POINTER = SPRITE_POINTER(explosion_sprite)