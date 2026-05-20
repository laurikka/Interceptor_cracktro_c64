eventlist:
    jmp event0      ; increment event counter
    jmp event1      ; draw middle shadowlord
    jmp event2      ; bring up tetrahedron
    jmp event3      ; second shadowlord and tetra
    jmp event4      ; third tetra
    jmp event5      ; hold tetra animation
    jmp event6      ; stomp and sprite7 wiggle
    jmp event7      ; sprite7 wiggle
    jmp event7_1    ; repeat
    jmp event8      ; sprite7 wiggle and ease out tetras
    jmp event9      ; stomp and scandal appear
    jmp event10     ; stomp and wiggle
    jmp event10     ; stomp and wiggle
    jmp event11     ; stomp and ease out scandal
    jmp event13     ; ease in carousel, siny wiggle, single tetra
    jmp event14     ; siny wiggle
    jmp event14     ; repeat
    jmp event15     ; easeout carousel
    jmp event19     ; ease in tetrascandal siny fastwiggle
    jmp event20     ; hold tetrascandal siny fastwiggle
    jmp event20_1   ; repeat
    jmp event21     ; ease out scandal siny fastwiggle
    jmp event16     ; ease in tetras
    jmp event17     ; hold tetra animation
    jmp event17     ; hold tetra animation
    jmp event18     ; ease out tetras
    jmp event22     ; use sprite multiplex, gunther ease in
    jmp event23     ; gunther ease out
    jmp event24     ; kramer ease in
    jmp event25     ; kramer ease out
    jmp event32     ; henri ease in
    jmp event33     ; henri ease out
    jmp event34     ; laurikka ease in
    jmp event35     ; laurikka ease out

    jmp event26     ; no effect
    jmp event26     
    jmp event27     ; start again without shadowlord redraw
    jmp event27
    jmp event29
    jmp event30
    jmp event31     ; loop to event5

;# eventlist to trigger one time when timer2 gets incremented ##############
event0:
    lda #3
    clc
    adc EVENT
    sta EVENT
    jmp mainloop

event1:
    lda #0
    sta SL_LINE
    sta SL_LOOP
    sta SLM_LINE
    sta SLM_LOOP
    sta SLM_POINTER
    sta SLC_FLIP
    sta SLC_POINTER

    lda #<M_screen+C_slpos2
    sta SLM_POS
    lda #>M_screen+C_slpos2
    sta SLM_POS+1
    lda #>M_graphics+$800   ; high byte of screen memory offset
    sta SLM_POINTER+1

    lda #<M_screen+$2000+(C_slpos2)/8
    sta SLC_POS
    lda #>M_screen+$2000+(C_slpos2)/8
    sta SLC_POS+1
    lda #>M_graphics+$800   ; high byte of screen color
    sta SLC_POINTER+1

    lda #<frameevent1
    sta FRAMEEVENT
    lda #>frameevent1
    sta FRAMEEVENT+1
    jmp event0

event2:
    jsr tetra_init
    lda #%10000000
    sta $d015               ; sprite enable bits
    lda #%11111111
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits

    lda #120
    sta POINTER+15

    lda #<frameevent2
    sta FRAMEEVENT
    lda #>frameevent2
    sta FRAMEEVENT+1
    jmp event0

event3:
    lda #%11000000
    sta $d015               ; sprite enable bits
    lda #120
    sta POINTER+13

    lda #0
    sta SL_LINE
    sta SL_LOOP
    sta SLM_LINE
    sta SLM_LOOP
    sta SLM_POINTER
    sta SLC_FLIP
    sta SLC_POINTER

    lda #<M_screen+C_slpos1
    sta SLM_POS
    lda #>M_screen+C_slpos1
    sta SLM_POS+1
    lda #>M_graphics+$800   ; high byte of screen memory offset
    sta SLM_POINTER+1

    lda #<M_screen+$2000+(C_slpos1)/8
    sta SLC_POS
    lda #>M_screen+$2000+(C_slpos1)/8
    sta SLC_POS+1
    lda #>M_graphics+$800   ; high byte of screen color
    sta SLC_POINTER+1
 
    lda #<frameevent3
    sta FRAMEEVENT
    lda #>frameevent3
    sta FRAMEEVENT+1
    jmp event0

event4:
    lda #%11100000
    sta $d015               ; sprite enable bits
    lda #120
    sta POINTER+11

    lda #0
    sta SL_LINE
    sta SL_LOOP
    sta SLM_LINE
    sta SLM_LOOP
    sta SLM_POINTER
    sta SLC_FLIP
    sta SLC_POINTER

    lda #>M_graphics+$800   ; high byte of screen memory offset
    sta SLM_POINTER+1
    lda #<M_screen+C_slpos3
    sta SLM_POS
    lda #>M_screen+C_slpos3
    sta SLM_POS+1

    lda #<M_screen+$2000+(C_slpos3)/8
    sta SLC_POS
    lda #>M_screen+$2000+(C_slpos3)/8
    sta SLC_POS+1
    lda #>M_graphics+$800   ; high byte of screen color
    sta SLC_POINTER+1

    lda #<frameevent4
    sta FRAMEEVENT
    lda #>frameevent4
    sta FRAMEEVENT+1
    jmp event0

event5:
    lda #<frameevent5
    sta FRAMEEVENT
    lda #>frameevent5
    sta FRAMEEVENT+1
    jmp event0

event6:
    lda #<frameevent6
    sta FRAMEEVENT
    lda #>frameevent6
    sta FRAMEEVENT+1
    jmp event0

event7:
    lda #<frameevent7
    sta FRAMEEVENT
    lda #>frameevent7
    sta FRAMEEVENT+1
    jmp event0

event7_1:
    lda #<frameevent7_1
    sta FRAMEEVENT
    lda #>frameevent7_1
    sta FRAMEEVENT+1
    jmp event0

event8:
    lda #1                  ; init value to start the ease out
    sta POINTER+11
    sta POINTER+13
    sta POINTER+15
    lda #<frameevent8
    sta FRAMEEVENT
    lda #>frameevent8
    sta FRAMEEVENT+1
    jmp event0

event9:
    jsr scandal_init

    clc
    lda #90
    ldy #0
:
    sta POINTER,y
    adc #10
    iny
    iny
    cpy #16
    bne :-

    lda #<frameevent9
    sta FRAMEEVENT
    lda #>frameevent9
    sta FRAMEEVENT+1
    jmp event0

event10:
    lda #<frameevent10
    sta FRAMEEVENT
    lda #>frameevent10
    sta FRAMEEVENT+1
    jmp event0

event11:
    jsr scandal_init
    lda #1
    sta POINTER+1
    sta POINTER+3
    sta POINTER+5
    sta POINTER+7
    sta POINTER+9
    sta POINTER+11
    sta POINTER+13
    sta POINTER+15
    lda #<frameevent11
    sta FRAMEEVENT
    lda #>frameevent11
    sta FRAMEEVENT+1
    jmp event0

event12:
    lda #<frameevent12
    sta FRAMEEVENT
    lda #>frameevent12
    sta FRAMEEVENT+1
    jmp event0

event13:
    jsr scandal_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    sta $d010               ; extra x-pos
    jsr carousel_init

    ldy #7
    jsr tetra_init_single

    clc
    lda #100
    ldy #0
:
    sta POINTER,y
    adc #10
    iny
    iny
    cpy #16
    bne :-

    lda #<frameevent13
    sta FRAMEEVENT
    lda #>frameevent13
    sta FRAMEEVENT+1
    jmp event0

event14:
    lda #<frameevent14
    sta FRAMEEVENT
    lda #>frameevent14
    sta FRAMEEVENT+1
    jmp event0

event15:
    lda #1
    sta POINTER+1
    sta POINTER+3
    sta POINTER+5
    sta POINTER+7
    sta POINTER+9
    sta POINTER+11
    sta POINTER+13
    sta POINTER+15
    lda #<frameevent15
    sta FRAMEEVENT
    lda #>frameevent15
    sta FRAMEEVENT+1
    jmp event0

event16:
    jsr tetra_init
    lda #%11100000
    sta $d015               ; sprite enable bits
    lda #%11100000
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    lda #120
    sta POINTER+11
    lda #130
    sta POINTER+13
    lda #140
    sta POINTER+15
    lda #<frameevent16
    sta FRAMEEVENT
    lda #>frameevent16
    sta FRAMEEVENT+1
    jmp event0

event17:
    lda #<frameevent17
    sta FRAMEEVENT
    lda #>frameevent17
    sta FRAMEEVENT+1
    jmp event0

event18:
    lda #1
    sta POINTER+11
    sta POINTER+13
    sta POINTER+15
    lda #<frameevent18
    sta FRAMEEVENT
    lda #>frameevent18
    sta FRAMEEVENT+1
    jmp event0

event19:
    jsr tetrascandal_init
    ldy #0
    jsr tetra_init_single
    lda #%11111111
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits

    clc
    lda #90
    ldy #0
:
    sta POINTER,y
    adc #10
    iny
    iny
    cpy #16
    bne :-

    lda #<frameevent19
    sta FRAMEEVENT
    lda #>frameevent19
    sta FRAMEEVENT+1
    jmp event0

event20:
    lda #<frameevent20
    sta FRAMEEVENT
    lda #>frameevent20
    sta FRAMEEVENT+1
    jmp event0

event20_1:
    jsr tetrascandal_init
    ldy #0
    jsr tetra_init_single
    lda #%11111111
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits

    lda #<frameevent20_1
    sta FRAMEEVENT
    lda #>frameevent20_1
    sta FRAMEEVENT+1
    jmp event0


event21:
    jsr tetrascandal_init
    ldy #0
    jsr tetra_init_single
    lda #%11111111
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits

    ldy #15
    lda #1
:
    sta POINTER,y
    dey
    dey
    bpl :-

    lda #<frameevent21
    sta FRAMEEVENT
    lda #>frameevent21
    sta FRAMEEVENT+1
    jmp event0

event22:
    clc
    lda #210
    ldy #0
:
    sta POINTER,y
    adc #4
    iny
    iny
    cpy #16
    bne :-

    ldy #0
    jsr tetra_init_single

    lda #<waitraster2
    sta WAITRASTER
    lda #>waitraster2
    sta WAITRASTER+1

    lda #<frameevent22_top
    sta FRAMEEVENT
    lda #>frameevent22_top
    sta FRAMEEVENT+1

    lda #<frameevent22_bottom
    sta FRAMEEVENT2
    lda #>frameevent22_bottom
    sta FRAMEEVENT2+1
    jmp event0

event23:
    lda #1
    sta POINTER
    sta POINTER+2
    sta POINTER+4
    sta POINTER+6
    sta POINTER+8
    sta POINTER+10
    sta POINTER+12
    sta POINTER+14

    lda #<frameevent23_top
    sta FRAMEEVENT
    lda #>frameevent23_top
    sta FRAMEEVENT+1

    lda #<frameevent23_bottom
    sta FRAMEEVENT2
    lda #>frameevent23_bottom
    sta FRAMEEVENT2+1
    jmp event0


event24:
    clc
    lda #210
    ldy #0
:
    sta POINTER,y
    adc #4
    iny
    iny
    cpy #16
    bne :-

    ldy #0
    jsr tetra_init_single

    lda #<waitraster2
    sta WAITRASTER
    lda #>waitraster2
    sta WAITRASTER+1

    lda #<frameevent24_top
    sta FRAMEEVENT
    lda #>frameevent24_top
    sta FRAMEEVENT+1

    lda #<frameevent23_bottom
    sta FRAMEEVENT2
    lda #>frameevent23_bottom
    sta FRAMEEVENT2+1
    jmp event0

event25:
    lda #1
    sta POINTER
    sta POINTER+2
    sta POINTER+4
    sta POINTER+6
    sta POINTER+8
    sta POINTER+10
    sta POINTER+12
    sta POINTER+14

    lda #<frameevent25_top
    sta FRAMEEVENT
    lda #>frameevent25_top
    sta FRAMEEVENT+1

    lda #<frameevent25_bottom
    sta FRAMEEVENT2
    lda #>frameevent25_bottom
    sta FRAMEEVENT2+1
    jmp event0

event32:
    clc
    lda #210
    ldy #0
:
    sta POINTER,y
    adc #4
    iny
    iny
    cpy #16
    bne :-

    ldy #0
    jsr tetra_init_single

    lda #<waitraster2
    sta WAITRASTER
    lda #>waitraster2
    sta WAITRASTER+1

    lda #<frameevent32_top
    sta FRAMEEVENT
    lda #>frameevent32_top
    sta FRAMEEVENT+1

    lda #<frameevent22_bottom
    sta FRAMEEVENT2
    lda #>frameevent22_bottom
    sta FRAMEEVENT2+1
    jmp event0

event33:
    lda #1
    sta POINTER
    sta POINTER+2
    sta POINTER+4
    sta POINTER+6
    sta POINTER+8
    sta POINTER+10
    sta POINTER+12
    sta POINTER+14

    lda #<frameevent33_top
    sta FRAMEEVENT
    lda #>frameevent33_top
    sta FRAMEEVENT+1

    lda #<frameevent23_bottom
    sta FRAMEEVENT2
    lda #>frameevent23_bottom
    sta FRAMEEVENT2+1
    jmp event0


event34:
    clc
    lda #210
    ldy #0
:
    sta POINTER,y
    adc #4
    iny
    iny
    cpy #16
    bne :-

    lda #<waitraster2
    sta WAITRASTER
    lda #>waitraster2
    sta WAITRASTER+1

    lda #<frameevent34_top
    sta FRAMEEVENT
    lda #>frameevent34_top
    sta FRAMEEVENT+1

    lda #<frameevent23_bottom
    sta FRAMEEVENT2
    lda #>frameevent23_bottom
    sta FRAMEEVENT2+1
    jmp event0

event35:
    lda #1
    sta POINTER
    sta POINTER+2
    sta POINTER+4
    sta POINTER+6
    sta POINTER+8
    sta POINTER+10
    sta POINTER+12
    sta POINTER+14

    lda #<frameevent35_top
    sta FRAMEEVENT
    lda #>frameevent35_top
    sta FRAMEEVENT+1

    lda #<frameevent25_bottom
    sta FRAMEEVENT2
    lda #>frameevent25_bottom
    sta FRAMEEVENT2+1
    jmp event0


event26:
    lda #0
    sta $d015               ; sprite enable bits

    lda #<waitraster
    sta WAITRASTER
    lda #>waitraster
    sta WAITRASTER+1

    lda #<frameevent26
    sta FRAMEEVENT
    lda #>frameevent26
    sta FRAMEEVENT+1
    jmp event0

event27:
    jmp event0

event29:
    jsr tetra_init
    lda #%10000000
    sta $d015               ; sprite enable bits
    lda #%11111111
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits

    lda #120
    sta POINTER+15
    sta POINTER+13
    sta POINTER+11

    lda #<frameevent29
    sta FRAMEEVENT
    lda #>frameevent29
    sta FRAMEEVENT+1
    jmp event0

event30:
    lda #%11000000
    sta $d015               ; sprite enable bits
 
    lda #<frameevent30
    sta FRAMEEVENT
    lda #>frameevent30
    sta FRAMEEVENT+1
    jmp event0

event31:
    lda #%11100000
    sta $d015               ; sprite enable bits

    lda #<frameevent31
    sta FRAMEEVENT
    lda #>frameevent31
    sta FRAMEEVENT+1

    lda #<eventlist+12
    sta EVENT
    lda #>eventlist+12
    sta EVENT+1
    jmp event0

;##########################################################################################################
;# Frame events
;##########################################################################################################
frameevent0:
    jmp return
frameevent1:
    jsr shadowlords_colorline
    lda TIMER1
    cmp #16
    bcc :+
    jsr shadowlords_maskline
:
    lda TIMER1
    cmp #32
    bcc :+
    lda #<M_screen+C_slpos2
    sta SL_POS
    lda #>M_screen+C_slpos2
    sta SL_POS+1
    jsr shadowlords_drawline
:
    jmp return

frameevent2:
    jsr tetrasprite                  ; copy tetra animation frames to vic
    ldy #15
    jsr easein
    jmp return

frameevent3:
    jsr tetrasprite                  ; copy tetra animation frames to vic
    ldy #13
    jsr easein

    jsr shadowlords_colorline
    lda TIMER1
    cmp #16
    bcc :+
    jsr shadowlords_maskline
:
    lda TIMER1
    cmp #32
    bcc :+
    lda #<M_screen+C_slpos1
    sta SL_POS
    lda #>M_screen+C_slpos1
    sta SL_POS+1
    jsr shadowlords_drawline
:
    jmp return

frameevent4:
    jsr tetrasprite                  ; copy tetra animation frames to vic
    ldy #11
    jsr easein
    jsr shadowlords_colorline
    lda TIMER1
    cmp #16
    bcc :+
    jsr shadowlords_maskline
:
    lda TIMER1
    cmp #32
    bcc :+
    lda #<M_screen+C_slpos3
    sta SL_POS
    lda #>M_screen+C_slpos3
    sta SL_POS+1
    jsr shadowlords_drawline
:
    jmp return

frameevent5:
    jsr tetrasprite                 ; copy tetra animation frames to vic
    jmp return

frameevent6:
    jsr stompcall
    jsr tetrasprite                 ; copy tetra animation frames to vic
    ldx #15
    jsr sprite_wiggle
    jmp return

frameevent7:
    jsr tetrasprite                 ; copy tetra animation frames to vic
    ldx #15
    jsr sprite_wiggle
    ldx #13
    jsr sprite_wiggle
    jmp return

frameevent7_1:
    jsr tetrasprite                 ; copy tetra animation frames to vic
    ldx #15
    jsr sprite_wiggle
    ldx #13
    jsr sprite_wiggle
    ldx #11
    jsr sprite_wiggle
    jmp return

frameevent8:
    jsr tetrasprite                 ; copy tetra animation frames to vic
    jsr easeout_y
    lda TIMER1
    cmp #120
    bcs :+
    ldx #15
    jsr sprite_wiggle
    ldx #13
    jsr sprite_wiggle
    ldx #11
    jsr sprite_wiggle
:
    jmp return

frameevent9:
    jsr stompcall
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    jsr easein_fast
    jmp return

frameevent10:
    jsr stompcall
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    ldx #15
    jsr sprite_wiggle
    jmp return

frameevent11:
    jsr stompcall
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    ldx #15
    jsr sprite_wiggle
    jsr easeout_y
    jmp return

frameevent12:
    jmp return

frameevent13:
    jsr carousel
    jsr singletetra
    jsr easein_fast
    ldx #1
    jsr siny_wiggle
    jmp return

frameevent14:
    jsr carousel
    jsr singletetra
    ldx #1
    jsr siny_wiggle
    jmp return

frameevent15:
    jsr carousel
    jsr singletetra
    ldx #1
    jsr siny_wiggle
    jsr easeout_y
    jmp return

frameevent16:
    jsr tetrasprite                 ; copy tetra animation frames to vic
    ldx #10
    jsr sinx_wiggle
    ldx #11
    jsr siny_wiggle
    ldy #11
    jsr easein
    ldy #13
    jsr easein
    ldy #15
    jsr easein
    jmp return

frameevent17:
    jsr tetrasprite                 ; copy tetra animation frames to vic
    ldx #10
    jsr sinx_wiggle
    ldx #11
    jsr siny_wiggle
    jmp return

frameevent18:
    jsr tetrasprite                 ; copy tetra animation frames to vic
    ldx #10
    jsr sinx_wiggle
    ldx #11
    jsr siny_wiggle
    jsr easeout_y
    jmp return

frameevent19:
    jsr stompcall
    jsr singletetra
    jsr tetra0move
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    jsr easein_fast
    jmp return

frameevent20:
    jsr stompcall
    jsr singletetra
    jsr tetra0move
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    ldx #1
    jsr siny_fastwiggle
    jmp return

frameevent20_1:
    jsr stompcall
    jsr tetrascandal_init
    jsr singletetra
    jsr tetra0move
    ldx #1
    jsr siny_fastwiggle
    ldy #16
    jsr sin_halfwiggle
    jmp return


frameevent21:
    jsr stompcall
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    jsr singletetra
    jsr tetra0move
    ldx #1
    jsr siny_fastwiggle
    jsr easeout_y
    jmp return

frameevent22_top:
    jsr gunther_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    jsr tetra0move_top
    ldy #0
    jsr sin_halfwiggle
    jsr easein_x_nochange
    jmp return

frameevent32_top:
    jsr henri_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    jsr tetra0move_top
    ldy #0
    jsr sin_halfwiggle
    jsr easein_x_nochange
    jmp return


frameevent22_bottom:
    jsr tetrascandal_init
    lda #%11111111
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    jsr scandal_xpos
    jsr singletetra
    jsr tetra0move
    ldx #1
    jsr siny_fastwiggle
    jsr easein_x     ; re-use pointer values from top-routine
    jmp return3

frameevent23_top:
    jsr gunther_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    jsr tetra0move_top
    ldy #0
    jsr sin_halfwiggle
    jsr easeout_x
    jmp return

frameevent33_top:
    jsr henri_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    jsr tetra0move_top
    ldy #0
    jsr sin_halfwiggle
    jsr easeout_x
    jmp return

frameevent23_bottom:
    jsr tetrascandal_init
    lda #%11111111
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    jsr scandal_xpos
    jsr singletetra
    jsr tetra0move
    ldx #1
    jsr siny_fastwiggle
    jmp return3

frameevent24_top:
    jsr kramer_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    jsr tetra0move_top
    ldy #0
    jsr sin_halfwiggle
    jsr easein_x
    jmp return

frameevent34_top:
    jsr laurikka_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    ldy #0
    jsr sin_halfwiggle
    jsr easein_x
    jmp return

frameevent25_top:
    jsr kramer_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    jsr stompcall
    jsr tetra0move_top
    ldy #0
    jsr sin_halfwiggle
    jsr easeout_x_nochange
    jmp return

frameevent35_top:
    jsr laurikka_init
    lda #0
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    ldy #0
    jsr sin_halfwiggle
    jsr easeout_x_nochange
    jmp return

frameevent25_bottom:
    jsr tetrascandal_init
    lda #%11111111
    sta $d017               ; sprite double height bits
    sta $d01d               ; sprite double widths bits
    lda #190                        ; sprite y-pos
    jsr sprite_ypos
    jsr scandal_xpos
    jsr singletetra
    jsr tetra0move
    ldx #1
    jsr siny_fastwiggle
    jsr easeout_x     ; re-use pointer values from top-routine
    jmp return3

frameevent26:
    jmp return

frameevent29:
    jsr tetrasprite                  ; copy tetra animation frames to vic
    ldy #15
    jsr easein
    jmp return

frameevent30:
    jsr tetrasprite                  ; copy tetra animation frames to vic
    ldy #13
    jsr easein
    jmp return

frameevent31:
    jsr tetrasprite                  ; copy tetra animation frames to vic
    ldy #11
    jsr easein
    jmp return
