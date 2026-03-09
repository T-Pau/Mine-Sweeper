; Random number generator by Brad Smith
; https://github.com/bbbradsmith/prng_6502

;
; 6502 LFSR PRNG - 16-bit
; Brad Smith, 2019
; http://rainwarrior.ca
;

; A 16-bit Galois LFSR

; Possible feedback values that generate a full 65535 step sequence:
; $2D = %00101101
; $39 = %00111001
; $3F = %00111111
; $53 = %01010011
; $BD = %10111101
; $D7 = %11010111

; $39 is chosen for its compact bit pattern

.section zero_page

seed .reserve 2

.section code

; overlapped version, computes all 8 iterations in an overlapping fashion
; 69 cycles
; 35 bytes
; Returns:
;   A: random number
; Preserves: X

random {
	lda seed+1
	tay ; store copy of high byte
	; compute seed+1 ($39>>1 = %11100)
	lsr ; shift to consume zeroes on left...
	lsr
	lsr
	sta seed+1 ; now recreate the remaining bits in reverse order... %111
	lsr
	eor seed+1
	lsr
	eor seed+1
	eor seed+0 ; recombine with original low byte
	sta seed+1
	; compute seed+0 ($39 = %111001)
	tya ; original high byte
	sta seed+0
	asl
	eor seed+0
	asl
	eor seed+0
	asl
	asl
	asl
	eor seed+0
	sta seed+0
	rts
}

seed_random {
    lda CIA1_TOD_SECONDS
    asl
    eor CIA1_TOD_SUB_SECOND
    sta seed
    lda CIA1_TIMER_A
    sta seed+1
    rts
}
