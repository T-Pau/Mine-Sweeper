.section graphics_game

game_bitmap .align $2000 {
    .binary_file "game-bitmap.prg" .start 2
}

game_screen .align $400 {
    .binary_file "game-screen.prg" .start 2
    .data 0, 0, 0, 0, 0, 0, 0, 0
    .data 0, 0, 0, 0, 0, 0, 0, 0
    .data <(pointer_sprite / 64):1
    .data <(pointer_sprite / 64) + 1:1
}

.section data

game_color {
    .binary_file "game-color.prg" .start 2
}

