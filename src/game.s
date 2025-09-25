GAME_ORIGINAL = 0
GAME_NEW = 1
GAME_HEX = 2

.section code

start_game {
    rts
}

start_game_original {
    lda #GAME_ORIGINAL
    sta game_mode
    jmp start_game
}

start_game_new {
    lda #GAME_NEW
    sta game_mode
    jmp start_game
}

start_game_hex {
    lda #GAME_HEX
    sta game_mode
    jmp start_game
}

.section reserved

game_mode .reserve 1