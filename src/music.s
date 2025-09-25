music_init = music
music_play = music + 3

.section data

music .address $1000 .used { ; XLR8: .used shouldn't be needed here
    .binary_file "music.prg" .start 2
}
