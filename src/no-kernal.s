END_OF_IRQ = end_of_irq

.macro disable_kernal {
    lda #$35
    sta $01
}

.macro enable_kernal {
    lda #$37
    sta $01
}

.section code

end_of_irq {
    pla
    tay
    pla
    tax
    pla
    rti
}

start_of_irq {
    pha
    txa
    pha
    tya
    pha
    tsx
    lda $0104,x
    and #$10
    beq :+
    ; jmp ($0316) ; TODO: doesn't work with kernal disabled
    jmp end_of_irq
:   jmp ($0314)
}

nmi_proxy {
    ; TODO: do properly
    rti
}

reset_proxy {
    sei
    lda #$37
    sta $01
    jmp ($fffc)
}

cpu_vectors {
    .data nmi_proxy ; NMI
    .data reset_proxy ; reset
    .data start_of_irq ; IRQ
}

init_no_kernal {
    sei
    disable_kernal

    ldx #5
:   lda cpu_vectors,x
    sta $fffa,x
    dex
    bpl :-
    cli

    rts
}
