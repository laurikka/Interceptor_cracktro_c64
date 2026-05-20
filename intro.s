;bugs left:
; - star field top garbage

DEBUG       = 0
MUSIC       = 1

;# memory map #######################
M_music     = $ffe                  ; music
M_screen    = $4000                 ; vic graphics $4000-$7fff
M_sprite1   = M_screen+$2800        ; sprites loaded directly to vic memory
M_font      = M_screen+$3800        ; 512 byte font binary
M_graphics  = $8000                 ; graphics binaries
M_rowoffset = $8e00                 ; 512 byte row offset tables
M_stars     = $9000                 ; 8k star table calculated at init
M_sprite2   = $b000                 ; 8k sprite animation binary

;# constants ########################
C_stars     = 32                    ; number of stars to loop through each frame
C_spriteX   = 170                   ; star sprite center x value
C_spriteY   = 100                   ; star sprite center y value
C_center    = M_screen+64*40+160    ; center of star effect, $4fa0 is center of screen
C_slpos1    = 40*8*7+16             ; shadowlord positions in screen space
C_slpos2    = 40*8*2+112
C_slpos3    = 40*8*7+208
C_slcolor   = $60                   ; shadowlord color fg and bg

;# zero page variables ##############
TEMP        = $4            ; temp and temp+1
TRACEPOS    = $6            ; starfield precomp 16-bit current memorylocation in tracetable
BITPOS      = $8            ; starfield 3-bit value to get bit position for star x position inside byte
STARPOS     = $9            ; starfield 16-bit pointer to star table
POINTPOS    = $b            ; starfield 16-bit position on screen memory holidng current position
TABLEPOS    = $d            ; 16-bit star table pos
SCROLLINDEX = $f            ; 16-bit location in scrolltext
EVENT       = $11           ; memory to jump for next event
FRAMEEVENT  = $13
TETRA1      = $15           ; 16-bit pointer for sprite animation
TETRA2      = $17           ; 16-bit offsetted pointer for second sprite
TETRA3      = $19
COUNTER     = $1b           ; decremented once a frame
TIMER1      = $1c           ; incremented every frame, resetted at 160
TIMER2      = $1d           ; incremented when timer1 reaches 160
WAITRASTER  = $1e           ; location of waitraster routine to jump to
POINTER     = $20           ; 16 values for sprite movement pointers

PREVPOS     = $30           ; starfield 32x previous 16-bit positions to clean up stars
PREV        = $70           ; starfield 32x previous graphics in star position
OFFSET      = $90           ; starfield 32x offset value for each star in star table

SLC_POINTER = $b0           ; 16-bit shadowlords color memory pointer
SLC_POS     = $b2           ; 16-bit shadowlords color screen pos
SLC_FLIP    = $b4           ; shadowlords color variable to run routine twice
SLC_ROUND   = $b5           ; shadowlords color variable for 16 rows
SL_POINTER  = $b6           ; 16-bit pointer to graphics in memory
SL_POS      = $b8           ; 16-bit pointer to screen location
SL_LINE     = $ba
SL_LOOP     = $bb
SLM_POINTER = $bc           ; 16-bit shadowlords mask memory pointer
SLM_POS     = $be
SLM_FLIP    = $c0
SLM_LINE    = $c1
SLM_LOOP    = $c2

FRAMEEVENT2 = $c3

VAR1        = $c5

TETRAPOINT  = $d0           ; 16 values for sprite tetrapos tables

    incdir graphics         ; load graphic assets from here
    cpu 6510                ; identifier for assembler to target c64

;	org $0326               ; autorun address
;	word init               ; pointer to program start

;## global init ############################################################
    org $800                ; program run location
init:
    sei                     ; disable intterrupts
    ldy #0
:
    lda 0,y
    sta restore,y           ; store contents of zeropage for exit
    iny
    bne :-

    lda #%00110110          ; disable basic
    sta $0001

    lda #0                  ; low byte aligns to zero
    sta $d020               ; border color
    sta $d021               ; bg color
    sta $d01c               ; sprite multicolor bits
    sta $d01b               ; sprite priority bits

    ldy #$4
:
    sta 0,y                 ; clear zeropage
    iny
    bne :-

;## clear screen ###########################
    lda #$20                ; clear screen
:
    sta $400,y
    sta $500,y
    sta $600,y
    sta $700,y
    iny
    bne :-
    
;## init music #############################
    if MUSIC=1
    lda #0
    jsr M_music+2           ; init music
    endif

;## clear bitmap memory ####################
    lda #0
    tay
    sta TEMP
    lda #>M_screen          ; bitmap memory high byte
    sta TEMP+1
:
    lda #0
:
    sta (TEMP),y
    iny
    bne :-
    inc TEMP+1
    lda TEMP+1
    cmp #$60
    bne :--
;## set bg colors ##################################
    lda #<bgcolors          ; background color map created in houdini
    sta STARPOS             ; use starpos as a temp memory pointer
    lda #>bgcolors
    sta STARPOS+1
:
    lda (STARPOS),y
    sta (TEMP),y
    iny
    bne :-
    inc STARPOS+1
    inc TEMP+1
    ldx TEMP+1
    cpx #$63
    bne :-
:
    lda (STARPOS),y
    sta (TEMP),y
    iny
    cpy #140
    bne :-

;##  copy random numbers to zeropage ###############
    ldy #C_stars
:
    lda random,y
    sta OFFSET,y
    dey
    bne :-

;## calculate row offset tables #########
    lda #0
    tay
    sta TEMP
    sta TEMP+1
    clc
:
    sta M_rowoffset,y
    lda #0
    adc TEMP+1
    sta TEMP+1
    sta M_rowoffset+256,y   ; store high byte
    lda TEMP
    adc #40
    sta TEMP
    iny
    bne :-

    jsr precalc_stars

;## bg star random fill #######################################
    lda #0          
    tay
    tax
:
    sta STARPOS
    lda #>M_screen
    sta STARPOS+1
    sty TEMP
    jsr starfill
    ldy TEMP
    inx
    iny
    lda OFFSET,y
    cpy #16
    bne :-

    lda #0                  ; low byte aligns to zero
    sta STARPOS

;## text mode colors #########################################
    lda #$bf
    sta TEMP
    lda #$db
    sta TEMP+1              ; last row in text mode

    lda #2                  ; scroller color
    ldy #40
:
    sta (TEMP),y
    dey
    bne :-

;## scroller init ############################################
    lda #<scrolltext
    sta SCROLLINDEX
    lda #>scrolltext
    sta SCROLLINDEX+1

;## events init ##############################################
    lda #<eventlist
    sta EVENT
    lda #>eventlist
    sta EVENT+1

    lda #<frameevent0
    sta FRAMEEVENT
    lda #>frameevent0
    sta FRAMEEVENT+1

    lda #<waitraster
    sta WAITRASTER
    lda #>waitraster
    sta WAITRASTER+1


;## vic init ##################################################
    lda $d016               ; reset vertical scroll
    and #%11111000
    sta $d016

    lda $d011
    and #%00000111
    ora #%00111000          ; 25 rows, screen on, text mode
    sta $d011               ; set screen

    lda #%10000000          ; bitmap memory $0-$1fff, screen memory $2000-23ff
    sta $d018               ; memory setup
    lda #%00001000          ; 40 columns
    sta $d016               ; set screen

    lda #%00000010          ; vic memory bank $4000-$7fff
    sta $dd00

    jmp (EVENT)             ; start eventlist evaluation

;##########################################################################################################
;# main loop ##############################################################################################
;##########################################################################################################
mainloop:
    if DEBUG=1
    inc $d020               ; border color
    endif

    jsr starfield

    if DEBUG=1
    inc $d020               ; border color
    endif

;# scroller update #################
    lda COUNTER
    and #%00001111          ; check if counter matches
    cmp #%00001111
    bne :+                  ; update scroll row once in 16 frames
    jsr update_scroll
:
;# events to trigger every frame ##########################
    jmp (FRAMEEVENT)
return:    

;# jump to wait for rasterline ######################
;    jsr waitraster
    jmp (WAITRASTER)
return2:
    if DEBUG=1
    inc $d020               ; border color
    endif

    if MUSIC=1
    jsr M_music+8           ; play music
    endif

    if DEBUG=1
    inc $d020
    endif

;# restore graphics behind stars ###
    ldx #0
    ldy #0
:
    lda PREVPOS,x
    sta POINTPOS
    lda PREVPOS+32,x
    sta POINTPOS+1
    lda PREV,x
    sta (POINTPOS),y
    inx
    cpx #C_stars
    bne :-

;# check spacebar for exit #########
    lda $dc01
    cmp #$ef
    beq exit

;# timer updates ###################
    dec COUNTER
    inc TIMER1
    lda TIMER1
    cmp #192
    bne :+
    inc TIMER2
    lda #0
    sta TIMER1
    jmp (EVENT)
:
    jmp mainloop            ; loop back

;##########################################################################################################
;# branch calls from mainloop #############################################################################
;##########################################################################################################
exit:
    ldy #0
:
    lda restore,y
    sta 0,y
    iny
    bne :-

    ldx #$17
    lda #$00
:
    sta $d400,x
    dex
    bpl :-

    cli

    jsr $ff8a           ; RESTOR: Initialize vector table $0314-$0333
    jsr $ff81           ; SCINIT: Initialize VIC++
    jsr $ff84           ; IOINIT: Initialize CIAs++
    jsr $e453           ; Initialize Vectors
    jsr $e3bf           ; Initialize BASIC RAM
;    jsr $e422
    ldx #$fb
    txs

    ldy #0
:
    lda endtext,y
    cmp #$60
    bcc :+
    sbc #$60
:
    sta $400+160,y
    iny
    cpy #120
    bne :--
    rts

;# wait raster ########################
waitraster: 
    if DEBUG=1
    lda #0
    sta $d020               ; border color
    endif
:
    lda $d012               ; wait for raster
    cmp #238
    bne :-

    lda $d011
    and #%00000111
    ora #%00011000          ; 25 rows, screen on, text mode
    sta $d011               ; set screen
    lda #%11001110          ; character memory $3800-$3fff, screen memory $3000-33ff
    sta $d018               ; memory setup

    lda COUNTER             ; get frame counter
    ror                     ; divide by 2 to update every other frame
    and #%00000111          ; leave vertical scroll part
    ora $d016               ; combine with existing
    and #%11110111          ; set 38 characters wide
    sta $d016               ; screen control

:
    lda $d012               ; wait for raster
    cmp #255
    bne :-

    lda $d016               ; reset vertical scroll
    and #%11111000
    sta $d016

    lda $d011
    and #%00000111
    ora #%00111000          ; 25 rows, screen on, text mode
    sta $d011               ; set screen

    lda #%10000000          ; bitmap memory $0-$1fff, screen memory $2000-23ff
    sta $d018               ; memory setup
    lda #%00001000          ; 40 columns
    sta $d016               ; set screen

    jmp return2
;    rts

;# wait raster 2 ######################
waitraster2:
    if DEBUG=1
    lda #0
    sta $d020               ; border color
    endif

:
    lda $d012               ; wait for raster
    cmp #120
    bne :-

    if DEBUG=1
    inc $d020
    endif

    jmp (FRAMEEVENT2)
return3:    
    if DEBUG=1
    dec $d020
    endif

:
    lda $d012               ; wait for raster
    cmp #238
    bne :-

    lda $d011
    and #%00000111
    ora #%00011000          ; 25 rows, screen on, text mode
    sta $d011               ; set screen
    lda #%11001110          ; character memory $3800-$3fff, screen memory $3000-33ff
    sta $d018               ; memory setup

    lda COUNTER             ; get frame counter
    ror                     ; divide by 2 to update every other frame
    and #%00000111          ; leave vertical scroll part
    ora $d016               ; combine with existing
    and #%11110111          ; set 38 characters wide
    sta $d016               ; screen control

:
    lda $d012               ; wait for raster
    cmp #255
    bne :-

    lda $d016               ; reset vertical scroll
    and #%11111000
    sta $d016

    lda $d011
    and #%00000111
    ora #%00111000          ; 25 rows, screen on, text mode
    sta $d011               ; set screen

    lda #%10000000          ; bitmap memory $0-$1fff, screen memory $2000-23ff
    sta $d018               ; memory setup
    lda #%00001000          ; 40 columns
    sta $d016               ; set screen

    jmp return2
;    rts


;##########################################################################################################
;# frame routines called from events ######################################################################
;##########################################################################################################

;# stompcall ############################
stompcall:
    lda TIMER1
    cmp #32
    bcs :+
    and #%00011111
    tay
    lda $d011
    and #%11111000
    ora stomp,y
    sta $d011
:
    rts
;# ease sprite to position, sprite number in y ##############
easein:
    ldx POINTER,y
    beq .end
    dex
    stx POINTER,y
    lda easein_table,x
    clc
    adc $d000,y
    bcs .overflow
    sta $d000,y
.end  
    rts
.overflow           ; prevent sprite wraparound if value overflows
    lda #255
    sta $d000,y
    rts

easein_fast:
    ldy #14
.round
    ldx POINTER,y
    beq .end
    dex
    dex
    stx POINTER,y
    lda easein_table,x
    clc
    adc $d000+1,y
    bcc :+
    lda #255
:
    sta $d001,y
.end
    dey
    dey
    bpl .round
    rts

easein_nochange:
    ldy #14
.round
    ldx POINTER,y
    beq .end
    lda easein_table,x
    clc
    adc $d000+1,y
    bcc :+
    lda #255
:
    sta $d001,y
.end
    dey
    dey
    bpl .round
    rts


easein_x:
    ldy #14
.round
    ldx POINTER,y
    beq :+
    dex
    dex
    stx POINTER,y
:
    lda easein_table,x
    clc
    adc $d000,y
    sta $d000,y
    bcc .end
    lda bitmask2,y
    eor $d010
    sta $d010
.end
    dey
    dey
    bpl .round
    rts

easein_x_nochange:
    ldy #14
.round
    ldx POINTER,y
    lda easein_table,x
    clc
    adc $d000,y
    sta $d000,y
    bcc .end
    lda bitmask2,y
    eor $d010
    sta $d010
.end
    dey
    dey
    bpl .round
    rts

easeout_x:
    lda TIMER1
    cmp #60
    bcs :+
    rts
:
    ldy #14
.round
    ldx POINTER,y
    cpx #253
    bcs :+
    inx
    inx
:
    stx POINTER,y
    lda $d000,y
    sec
    sbc easein_table,x
    sta $d000,y
    bcs :+
    lda bitmask2,y
    eor $d010
    sta $d010
:
    dey
    dey
    bpl .round
    rts

easeout_x_nochange:
    lda TIMER1
    cmp #60
    bcs :+
    rts
:
    ldy #14
.round
    ldx POINTER,y
    lda $d000,y
    sec
    sbc easein_table,x
    bcs :+
    lda #0
:
    sta $d000,y
    dey
    dey
    bpl .round
    rts


easeout_y:
    lda TIMER1
    cmp #60
    bcs :+
    rts
:
    ldy #15
.round
    ldx POINTER,y
    beq .end
    inx
    stx POINTER,y
    lda easein_table,x
    clc
    adc $d000,y
    bcc :+
    lda #255
:
    sta $d000,y
.end
    dey
    dey
    bpl .round
    rts
;# copy 3 tetrasprites from animation binary to vic sprite memory #########################
tetrasprite:
    ldy #63
:
    lda (TETRA1),y
    sta $7040,y
    lda (TETRA2),y
    sta $7080,y
    lda (TETRA3),y
    sta $70c0,y
    dey
    bpl :-
    lda #64
    clc
    adc TETRA1
    sta TETRA1
    bcc :+
    inc TETRA1+1
:
    lda #64
    clc
    adc TETRA2
    sta TETRA2
    bcc :+
    inc TETRA2+1
:
    lda #64
    clc
    adc TETRA3
    sta TETRA3
    bcc :+
    inc TETRA3+1
:
    lda TETRA1+1
    cmp #$d0
    bcc :+
    lda #>M_sprite2
    sta TETRA1+1
    lda #0
    sta TETRA1
:
    lda TETRA2+1
    cmp #$d0
    bcc :+
    lda #>M_sprite2
    sta TETRA2+1
    lda #0
    sta TETRA2
:
    lda TETRA3+1
    cmp #$d0
    bcc :+
    lda #>M_sprite2
    sta TETRA3+1
    lda #0
    sta TETRA3
:
    clc
    ldy TETRAPOINT+14
    lda tetrapos,y
    sta $d00e               ; sprite 7 x pos
    iny
    lda tetrapos,y
    sta $d00f               ; sprite 7 y pos
    iny
    sty TETRAPOINT+14

    ldy TETRAPOINT+12
    lda tetrapos,y
    sta $d00c               ; sprite 6 x pos
    iny
    lda tetrapos,y
    sta $d00d               ; sprite 6 y pos
    iny
    sty TETRAPOINT+12

    ldy TETRAPOINT+10
    lda tetrapos,y
    sta $d00a               ; sprite 5 x pos
    iny
    lda tetrapos,y
    sta $d00b               ; sprite 5 y pos
    iny
    sty TETRAPOINT+10
    rts


tetra0move:
    ldy TETRAPOINT+7
    lda tetrapos,y
    sta $d000               ; sprite x pos
    iny
    lda tetrapos,y
    sta $d001               ; sprite y pos
    iny
    sty TETRAPOINT+7
    rts

tetra0move_top:
    ldy TETRAPOINT+6
    lda tetrapos,y
    sta $d000               ; sprite x pos
    iny
    lda tetrapos,y
    clc
    adc #140
    sta $d001               ; sprite y pos
    iny
    sty TETRAPOINT+6
    rts

singletetra:
    ldy #63
:
    lda (TETRA3),y
    sta $70c0,y
    dey
    bpl :-

    lda #64
    clc
    adc TETRA3
    sta TETRA3
    bcc :+
    inc TETRA3+1
:
    lda TETRA3+1
    cmp #$d0
    bcc :+
    lda #>M_sprite2
    sta TETRA3+1
    lda #0
    sta TETRA3
:
    rts

carousel:
    ldx #0
    clc
:
    ldy TETRAPOINT,x
    lda tetrapos,y
    adc #16
    sta $d000,x
    dey
    lda tetrapos,y
    sta $d000+1,x
    dey
    sty TETRAPOINT,x
    inx
    inx
    cpx #16
    bne :- 
    rts

;# shift sprites 0-x right based on y-reg ###############
shiftx:
:
    tya
    adc $d000,x
    sta $d000,x
    bcc :+
    lda bitmask2,x
    eor $d010
    sta $d010
:    
    dex
    dex
    bpl :-
    rts

;# subtract audiosnippet table from $d000+x #############
sprite_wiggle:
    ldy TIMER1
    lda $d000,x
    sec
    sbc audiosnippet1,y
    sta $d000,x
    rts

;# siny_wiggle, x is odd number############
siny_wiggle:
    ldy COUNTER
:
    clc
    lda sintable,y
    adc $d000,x
    sta $d000,x
    tya
    adc #32
    tay
    inx
    inx
    cpx #17
    bne :-
    rts

siny_fastwiggle:
    lda COUNTER
    asl
    asl
    tay
:
    clc
    lda sintable,y
    adc $d000,x
    sta $d000,x
    tya
    adc #24
    tay
    inx
    inx
    cpx #17
    bne :-
    rts

sin_halfwiggle:
    ldx #0
    clc
    tya
    adc COUNTER
    asl
    asl
    tay
.loop
    lda sintable,y
    bmi :+              ; if minusvalue, skip ahead
    lsr                 ; divide by 2 for positive
    bpl :++
:
    eor #%11111111      ; make negative to positive
    lsr                 ; divide by 2
    eor #%11111111      ; make positive to negative
:
    clc
    adc $d000,x
    sta $d000,x
;    bcc :+
;    lda bitmask2,x
;    eor $d010
;    sta $d010
;:
    tya
    adc #24
    tay
    inx
    inx
    cpx #16
    bne .loop

    ldx #1
    lda COUNTER
    adc #16
    asl
    asl
    tay
.loop2
    lda sintable,y
    bmi :+              ; if minusvalue, skip ahead
    lsr                 ; divide by 2 for positive
    bpl :++
:
    eor #%11111111      ; make negative to positive
    lsr                 ; divide by 2
    eor #%11111111      ; make positive to negative
:
    clc
    adc $d000,x
    sta $d000,x
    bcc :+
    lda bitmask2,x
    eor $d010
    sta $d010
:
    tya
    adc #24
    tay
    inx
    inx
    cpx #17
    bne .loop2

    rts

;# sinx_wiggle ############################
sinx_wiggle:
    lda COUNTER
    adc #128
    tay
:
    clc
    lda sintable,y
    adc $d000,x
    sta $d000,x
    tya
    adc #32
    tay
    inx
    inx
    cpx #16
    bne :-
    rts


;## tetrahedron sprite init ##################################
tetra_init:
    lda #0                  ; data is page aligned
    sta TETRA1
    sta TETRA2
    sta TETRA3
    sta TETRAPOINT+14
    sta $d010

    lda #>M_sprite2         ; sprite animation binary
    sta TETRA1+1
    clc
    adc #11                 ; 44 frame offset (4 sprites per 256 bytes)
    sta TETRA2+1
    adc #10                 ; additional 40 frame offset
    sta TETRA3+1

    lda #84                 ; offset to location table
    sta TETRAPOINT+12
    lda #170
    sta TETRAPOINT+10

    lda #8
    sta $d02c               ; sprite#5 color
    sta $d02d               ; sprite#6 color
    sta $d02e               ; sprite#7 color

    lda #$c1                ; equals $7040
    sta M_screen+$23F8+7    ; store pointer on two locations to make it
    sta M_screen+$33F8+7    ; visible also over the scroller portion
    lda #$c2                ; equals $7080
    sta M_screen+$23F8+6
    sta M_screen+$33F8+6
    lda #$c3                ; equals $70c0
    sta M_screen+$23F8+5
    sta M_screen+$33F8+5
    rts

tetra_init_single:          ; y is sprite pointer
    lda #$c3                ; equals $70c0
    sta M_screen+$23F8,y
    sta M_screen+$33F8,y

    lda #0                  ; data is page aligned
    sta TETRA3
    lda #>M_sprite2         ; sprite animation binary
    sta TETRA3+1
    rts

;# init scandal sprites ###################################
scandal_init:
    lda #%11111111
    sta $d015               ; sprite enable bits

    lda #2
    ldy #7
:
    sta $d027,y             ; sprite color
    dey
    bpl :-

    lda #$a0
    sta M_screen+$23F8
    sta M_screen+$33F8
    lda #$a0+1
    sta M_screen+$23F8+1
    sta M_screen+$33F8+1
    lda #$a0+2
    sta M_screen+$23F8+2
    sta M_screen+$33F8+2
    lda #$a0+3
    sta M_screen+$23F8+3
    sta M_screen+$33F8+3
    lda #$a0+4
    sta M_screen+$23F8+4
    sta M_screen+$33F8+4
    lda #$a0+2
    sta M_screen+$23F8+5
    sta M_screen+$33F8+5
    lda #$a0+5
    sta M_screen+$23F8+6
    sta M_screen+$33F8+6
    lda #$a0+6
    sta M_screen+$23F8+7
    sta M_screen+$33F8+7

    lda #190                ; sprite y-pos
    ldy #15
:
    sta $d000,y
    dey
    dey
    bpl :-

    lda #74                 ; sprite x-pos
    ldy #0
:
    sta $d000,y
    clc
    adc #28
    iny
    iny
    cpy #16
    bne :-

    lda #%10000000
    sta $d010
    rts

gunther_init:
    lda #$a0+7
    sta M_screen+$23F8+1
    sta M_screen+$33F8+1
    lda #$a0+8
    sta M_screen+$23F8+2
    sta M_screen+$33F8+2
    lda #$a0+3
    sta M_screen+$23F8+3
    sta M_screen+$33F8+3
    lda #$a0+9
    sta M_screen+$23F8+4
    sta M_screen+$33F8+4
    lda #$a0+10
    sta M_screen+$23F8+5
    sta M_screen+$33F8+5
    lda #$a0+11
    sta M_screen+$23F8+6
    sta M_screen+$33F8+6
    lda #$a0+12
    sta M_screen+$23F8+7
    sta M_screen+$33F8+7

    lda #90                ; sprite y-pos
    ldy #15
:
    sta $d000,y
    dey
    dey
    bpl :-

    lda #120                 ; sprite x-pos
    ldy #0
:
    sta $d000,y
    clc
    adc #14
    iny
    iny
    cpy #16
    bne :-

    lda #%00000000
    sta $d010

    rts

kramer_init:
    lda #$a0+13
    sta M_screen+$23F8+1
    sta M_screen+$33F8+1
    lda #$a0+12
    sta M_screen+$23F8+2
    sta M_screen+$33F8+2
    lda #$a0+14
    sta M_screen+$23F8+3
    sta M_screen+$33F8+3
    lda #$a0+15
    sta M_screen+$23F8+4
    sta M_screen+$33F8+4
    lda #$a0+11
    sta M_screen+$23F8+5
    sta M_screen+$33F8+5
    lda #$a0+12
    sta M_screen+$23F8+6
    sta M_screen+$33F8+6

    lda #90                ; sprite y-pos
    ldy #15
:
    sta $d000,y
    dey
    dey
    bpl :-

    lda #120                 ; sprite x-pos
    ldy #0
:
    sta $d000,y
    clc
    adc #14
    iny
    iny
    cpy #16
    bne :-

    lda #%00000000
    sta $d010

    lda #%01111111
    sta $d015               ; sprite enable bits

    rts

henri_init:
    lda #$a0+10
    sta M_screen+$23F8+1
    sta M_screen+$33F8+1
    lda #$a0+11
    sta M_screen+$23F8+2
    sta M_screen+$33F8+2
    lda #$a0+3
    sta M_screen+$23F8+3
    sta M_screen+$33F8+3
    lda #$a0+12
    sta M_screen+$23F8+4
    sta M_screen+$33F8+4
    lda #$a0+17
    sta M_screen+$23F8+5
    sta M_screen+$33F8+5

    lda #90                ; sprite y-pos
    ldy #15
:
    sta $d000,y
    dey
    dey
    bpl :-

    lda #120                 ; sprite x-pos
    ldy #0
:
    sta $d000,y
    clc
    adc #14
    iny
    iny
    cpy #16
    bne :-

    lda #%00000000
    sta $d010

    lda #%00111111
    sta $d015               ; sprite enable bits

    rts

laurikka_init:
    lda #$a0+5
    sta M_screen+$23F8
    sta M_screen+$33F8
    lda #$a0+2
    sta M_screen+$23F8+1
    sta M_screen+$33F8+1
    lda #$a0+16
    sta M_screen+$23F8+2
    sta M_screen+$33F8+2
    lda #$a0+12
    sta M_screen+$23F8+3
    sta M_screen+$33F8+3
    lda #$a0+17
    sta M_screen+$23F8+4
    sta M_screen+$33F8+4
    lda #$a0+13
    sta M_screen+$23F8+5
    sta M_screen+$33F8+5
    lda #$a0+13
    sta M_screen+$23F8+6
    sta M_screen+$33F8+6
    lda #$a0+2
    sta M_screen+$23F8+7
    sta M_screen+$33F8+7

    lda #90                ; sprite y-pos
    ldy #15
:
    sta $d000,y
    dey
    dey
    bpl :-

    lda #120                 ; sprite x-pos
    ldy #0
:
    sta $d000,y
    clc
    adc #14
    iny
    iny
    cpy #18
    bne :-

    lda #%00000000
    sta $d010

    lda #%11111111
    sta $d015               ; sprite enable bits

    lda #2
    ldy #7
:
    sta $d027,y             ; sprite color
    dey
    bpl :-
    
    rts



;# init scandal sprites ###################################
tetrascandal_init:
    lda #%11111111
    sta $d015               ; sprite enable bits

    lda #2
    ldy #7
:
    sta $d027,y             ; sprite color
    dey
    bne :-
    
    lda #8
    sta $d027               ; sprite 0 color

    lda #$c3                ; equals $70c0
    sta M_screen+$23F8,y
    sta M_screen+$33F8,y

    lda #$a0
    sta M_screen+$23F8+1
    sta M_screen+$33F8+1
    lda #$a0+1
    sta M_screen+$23F8+2
    sta M_screen+$33F8+2
    lda #$a0+2
    sta M_screen+$23F8+3
    sta M_screen+$33F8+3
    lda #$a0+3
    sta M_screen+$23F8+4
    sta M_screen+$33F8+4
    lda #$a0+4
    sta M_screen+$23F8+5
    sta M_screen+$33F8+5
    lda #$a0+2
    sta M_screen+$23F8+6
    sta M_screen+$33F8+6
    lda #$a0+5
    sta M_screen+$23F8+7
    sta M_screen+$33F8+7

    lda #190                ; sprite y-pos
    ldy #15
:
    sta $d000,y
    dey
    dey
    bpl :-

    lda #80                 ; sprite x-pos
    ldy #0
:
    sta $d002,y
    clc
    adc #28
    iny
    iny
    cpy #14
    bne :-

    rts

carousel_init:
    clc
    lda #0
    ldy #0
:
    sta TETRAPOINT,y
    adc #32
    iny
    iny
    cpy #16
    bne :-
    rts

;# refresh scandal y-pos ##################################
sprite_ypos:
    ldy #15
:
    sta $d000,y
    dey
    dey
    bpl :-
    rts

scandal_xpos:
    lda #74                 ; sprite x-pos
    ldy #0
:
    sta $d000,y
    clc
    adc #28
    iny
    iny
    cpy #16
    bne :-

    lda #%10000000
    sta $d010
    rts


;## music resides at $1000, leave gap in code for it here #################################################
    if MUSIC=1
    org M_music
    incbin unit5.prg
    endif

;# events list ########################
    align 8
    include events.s



;##########################################################################################################
;# more subroutines that don't fit before music ###########################################################
;##########################################################################################################

;# starfield #################################
starfield:
    ldx #C_stars-1
    lda #>M_stars           ; high byte of screen memory offset
    sta STARPOS+1
:
    lda OFFSET,x
    and #%11111100
    tay
    lda (STARPOS),y
    sta POINTPOS
    lda OFFSET,x
    iny
    lda (STARPOS),y
    sta POINTPOS+1
    iny
    lda (STARPOS),y
    sta BITPOS
    ldy #0
    lda (POINTPOS),y
    sta PREV,x
    lda POINTPOS
    sta PREVPOS,x
    lda POINTPOS+1
    sta PREVPOS+32,x
    lda BITPOS
    ora (POINTPOS),y
    sta (POINTPOS),y
    inc STARPOS+1
    lda #4
    clc
    adc OFFSET,x
    sta OFFSET,x
    dex
    bpl :-
    rts

;##########################################################################################################
update_scroll:
    ldy #40
.loop
    lda (SCROLLINDEX),y
    beq .reset
    cmp #$60
    bcc :+
    sbc #$60
:
    sta M_screen+$3000+40*24,y
    dey
    bpl .loop
    inc SCROLLINDEX
    bne :+
    inc SCROLLINDEX+1
:
    rts
.reset
    lda #<scrolltext
    sta SCROLLINDEX
    lda #>scrolltext
    sta SCROLLINDEX+1
    rts

;##########################################################################################################
shadowlords_colorline:
    ldy #0
    ldx SLC_ROUND
    inx
    stx SLC_ROUND
    cpx #16
    bne .loop
    beq .end
.loop
    lda (SLC_POINTER),y
    rol
    pha
    bcc :+
    lda #C_slcolor
    sta (SLC_POS),y
:
    iny
    pla
    rol
    pha
    bcc :+
    lda #C_slcolor
    sta (SLC_POS),y
:
    cpy #7
    bne :--
    pla
    clc
    lda #8
    adc SLC_POS
    sta SLC_POS
    bcc :+
    inc SLC_POS+1
:
    ldy #0
    inc SLC_POINTER
    inc SLC_FLIP
    lda SLC_FLIP
    cmp #1
    beq .loop
    clc
    lda #24
    adc SLC_POS
    sta SLC_POS
    bcc :+
    inc SLC_POS+1
:
    lda #0
    sta SLC_FLIP
.end
    rts

;##########################################################################################################
shadowlords_maskline:
    ldx SLM_LINE
    cpx #16
    beq .end
    ldy #0
    sty SLM_FLIP
.loop
    lda (SLM_POINTER),y
    rol
    pha
    bcc :+
    jsr .fill
:
    clc
    lda #8
    adc SLM_POS
    sta SLM_POS
    bcc :+
    inc SLM_POS+1
:    
    iny
    pla
    rol
    pha
    bcc :+
    jsr .fill
:
    clc
    lda #8
    adc SLM_POS
    sta SLM_POS
    bcc :+
    inc SLM_POS+1
:    
    cpy #7
    bne :---
    pla
    ldy #0
    inc SLM_POINTER
    inc SLM_FLIP
    lda SLM_FLIP
    cmp #1
    beq .loop
    clc
    lda #192
    adc SLM_POS
    sta SLM_POS
    bcc :+
    inc SLM_POS+1
:
    inx
    stx SLM_LINE
.end
    rts

.fill
    sty SLM_LOOP
    ldy #7
    lda #0
:
    sta (SLM_POS),y
    dey
    bpl :-
    ldy SLM_LOOP
    rts

;##########################################################################################################
shadowlords_drawline:
    lda #0                  ; low byte of screen memory offset
    sta SL_POINTER
    lda #>M_graphics        ; high byte of screen memory offset
    sta SL_POINTER+1
    ldy SL_LINE
    cpy #96
    beq .end
    ldx #0
.loop
    lda (SL_POINTER),y
    ora (SL_POS),y
    sta (SL_POS),y
    clc
    lda #160
    adc SL_POS
    sta SL_POS
    bcc :+
    inc SL_POS+1
:
    clc
    lda #160
    adc SL_POS
    sta SL_POS
    bcc :+
    inc SL_POS+1
:
    lda #128
    clc
    adc SL_POINTER
    sta SL_POINTER
    bcc :+
    inc SL_POINTER+1
:
    inx
    cpx #16
    bne .loop
    iny
    sty SL_LINE

.end
    rts

;##########################################################################################################
;# precalc routines #######################################################################################
;##########################################################################################################
precalc_stars:
    lda #>M_stars           ; high byte of screen memory offset
    sta STARPOS+1
    lda #0
    tay
    tax
    sta STARPOS
    sta TABLEPOS
    sta TABLEPOS+1

;## -Y +X ###########
    jsr .reset_trace
:
    lda #<C_center          ; location for star effect center
    sta POINTPOS
    lda #>C_center
    sta POINTPOS+1
    lda (TRACEPOS),y
    jsr minusY
    iny
    lda (TRACEPOS),y
    jsr plusX
    jsr .store
    bne :-
    jsr .inc_high
    bne :-
;## +X -Y ###########
    jsr .reset_trace
:
    lda #<C_center          ; location for star effect center
    sta POINTPOS
    lda #>C_center
    sta POINTPOS+1
    lda (TRACEPOS),y
    jsr plusX
    iny
    lda (TRACEPOS),y
    jsr minusY
    jsr .store
    bne :-
    jsr .inc_high
    bne :-
;## +X +Y ###########
    jsr .reset_trace
:
    lda #<C_center          ; location for star effect center
    sta POINTPOS
    lda #>C_center
    sta POINTPOS+1
    lda (TRACEPOS),y
    jsr plusX
    iny
    lda (TRACEPOS),y
    jsr plusY
    jsr .store
    bne :-
    jsr .inc_high
    bne :-
;## +Y +X ###########
    jsr .reset_trace
:
    lda #<C_center          ; location for star effect center
    sta POINTPOS
    lda #>C_center
    sta POINTPOS+1
    lda (TRACEPOS),y
    jsr plusY
    iny
    lda (TRACEPOS),y
    jsr plusX
    jsr .store
    bne :-
    jsr .inc_high
    bne :-
;## +Y -X ###########
    jsr .reset_trace
:
    lda #<C_center          ; location for star effect center
    sta POINTPOS
    lda #>C_center
    sta POINTPOS+1
    lda (TRACEPOS),y
    jsr plusY
    iny
    lda (TRACEPOS),y
    jsr minusX
    jsr .store
    bne :-
    jsr .inc_high
    bne :-
;## -X +Y ###########
    jsr .reset_trace
:
    lda #<C_center          ; location for star effect center
    sta POINTPOS
    lda #>C_center
    sta POINTPOS+1
    lda (TRACEPOS),y
    jsr minusX
    iny
    lda (TRACEPOS),y
    jsr plusY
    jsr .store
    bne :-
    jsr .inc_high
    bne :-
;## -X -Y ###########
    jsr .reset_trace
:
    lda #<C_center          ; location for star effect center
    sta POINTPOS
    lda #>C_center
    sta POINTPOS+1
    lda (TRACEPOS),y
    jsr minusX
    iny
    lda (TRACEPOS),y
    jsr minusY
    jsr .store
    bne :-
    jsr .inc_high
    bne :-
;## -Y -X ###########
    jsr .reset_trace
:
    lda #<C_center          ; location for star effect center
    sta POINTPOS
    lda #>C_center
    sta POINTPOS+1
    lda (TRACEPOS),y
    jsr minusY
    iny
    lda (TRACEPOS),y
    jsr minusX
    jsr .store
    bne :-
    jsr .inc_high
    bne :-
    rts
.store
    sty TABLEPOS
    ldy TABLEPOS+1
    lda POINTPOS
    sta (STARPOS),y
    lda POINTPOS+1
    cmp #$60
    bcc :+
    lda #$3e                ; store offscreen stars above the screen area
    bcs :++
:
    cmp #>M_screen
    bcs :+
    lda #$3e                ; store offscreen stars above the screen area
:
    iny
    sta (STARPOS),y
    lda BITPOS
    iny
    sta (STARPOS),y
    iny
    iny
    bne :+
    inc STARPOS+1
:
    sty TABLEPOS+1
    ldy TABLEPOS
    iny
    rts
.reset_trace
    lda #0                ; page aligned low byte
    sta TRACEPOS
    lda #>starpaths       ; high byte of screen memory offset
    sta TRACEPOS+1
    lda #0
    sta TEMP
    sta TABLEPOS
    sta TABLEPOS+1
    rts
.inc_high
    inc TRACEPOS+1
    inc TEMP
    lda TEMP
    cmp #2
    rts
;##########################################################################################################
zeropos:
    lda #>M_screen
    sta POINTPOS+1
    rts
plusX:
    beq zeropos
    pha
    and #%11111000          ; mask out last 3 bits that define the bit position
    clc
    adc POINTPOS
    sta POINTPOS
    lda #0
    adc POINTPOS+1
    sta POINTPOS+1
    pla
    and #%00000111
    tax
    lda bitmask,x
    sta BITPOS
    rts
plusY:
    beq zeropos
    pha                     ; store unmasked y-value
    and #%00000111          ; mask out last 3 bits that define the row in character space
    clc
    adc POINTPOS            ; add to existing pointpos
    sta POINTPOS
    pla                     ; get unmasked y-value
    and #%11111000          ; leave 5 high bits that define character line offset
    tax
    lda M_rowoffset,x       ; table lookup, low byte
    adc POINTPOS
    sta POINTPOS
    lda M_rowoffset+256,x   ; table lookup, high byte
    adc POINTPOS+1
    sta POINTPOS+1
    rts
minusX:
    beq zeropos
    sta BITPOS              ; store for BITPOS operation in put point
    and #%11111000          ; mask out last 3 bits that define the bit position
    sta TEMP+1
    lda POINTPOS
    sec
    sbc TEMP+1
    sta POINTPOS
    lda POINTPOS+1
    sbc #0
    sta POINTPOS+1

    lda #7
    sec
    sbc BITPOS
    sta BITPOS
    and #%00000111
    tax
    lda bitmask,x
    sta BITPOS
    rts
minusY:
    beq zeropos
    tax
    and #%00000111          ; mask out last 3 bits that define the row in character space
    sec
    sbc #7
    sta TEMP+1
    lda POINTPOS
    sec
    sbc TEMP+1
    sta POINTPOS
    txa
    and #%11111000          ; leave 5 high bits that define character line offset
    tax
    lda M_rowoffset,x       ; table lookup, low byte
    sta TEMP+1
    lda POINTPOS
    sec
    sbc TEMP+1
    sta POINTPOS
    lda POINTPOS+1
    sbc #0
    sta POINTPOS+1
    lda M_rowoffset+256,x   ; table lookup, high byte
    sta TEMP+1
    lda POINTPOS+1
    sec
    sbc TEMP+1
    sta POINTPOS+1
    rts
;##########################################################################################################
starfill:
:
    lda OFFSET+16,x
    stx TEMP+1
    tay                     ; store for bitmask
;    and #%11111000          ; take out the bitmask portion
    adc STARPOS
    sta STARPOS
    bcc :+
    clc
    inc STARPOS+1
    lda STARPOS+1
    cmp #$5d
    beq .end
:
    tya
    and #%00000111
    tay
    lda bitmask,y
    ldy #0
    sta (STARPOS),y
    inx
    cpx #32
    bne :--
    ldx #0
    beq :--
.end
    ldx TEMP+1
    rts
  

;##########################################################################################################
bitmask:
    byte %10000000,%01000000,%00100000,%00010000,%00001000,%00000100,%00000010,%00000001,0,0
bitmask2:
    byte %00000001,0,%00000010,0,%00000100,0,%00001000,0,%00010000,0,%00100000,0,%01000000,0,%10000000,0
random:
    byte 85, 253, 107, 71, 192, 228, 14, 234, 236, 225, 159, 66, 214, 116, 92, 239, 70, 106, 20, 183, 221, 152, 245, 214, 91, 242, 22, 95, 29, 246, 190, 241
stomp:
    byte 6,7,5,3,1,2,3,4,5,6,5,4,3,3,4,4,5,5,5,4,4,4,3,2,3,4,3,2,3,4,3,3

scrolltext:
    blk 50,$20                  ; 50 spaces before the scroller
    incbin scroller.txt
    blk 40,$20                  ; 40 spaces after
    byte 0                      ; zero resets the scroller

endtext:                        ; shown at exit
    ascii "          thanks for watching           "
    ascii "       interceptor cracktro remix       "
    ascii "           by laurikka 2026             "

    align 8
restore:                        ; store existing zeropages here for exit
    blk 256
    align 8
starpaths:
    byte 23, 8, 24, 8, 24, 8, 24, 8, 25, 8, 25, 9, 26, 9, 26, 9, 26, 9, 27, 9, 27, 9, 28, 9, 28, 10, 29, 10, 29, 10, 30, 10, 30, 10, 31, 11, 31, 11, 32, 11, 32, 11, 33, 11, 34, 12, 34, 12, 35, 12, 36, 12, 36, 13, 37, 13, 38, 13, 39, 13, 40, 14, 41, 14, 42, 14, 43, 15, 44, 15, 45, 16, 46, 16, 47, 16, 49, 17, 50, 17, 52, 18, 53, 19, 55, 19, 57, 20, 59, 20, 61, 21, 63, 22, 65, 23, 68, 24, 70, 25, 73, 26, 77, 27, 80, 28, 84, 29, 88, 31, 93, 33, 98, 34, 104, 36, 110, 39, 118, 41, 126, 44, 136, 48, 147, 52, 0, 0, 30, 18, 31, 18, 31, 18, 32, 18, 32, 19, 33, 19, 33, 19, 34, 19, 34, 20, 35, 20, 35, 20, 36, 21, 36, 21, 37, 21, 38, 22, 38, 22, 39, 23, 40, 23, 40, 23, 41, 24, 42, 24, 43, 25, 43, 25, 44, 26, 45, 26, 46, 27, 47, 27, 48, 28, 49, 29, 50, 29, 51, 30, 53, 31, 54, 31, 55, 32, 57, 33, 58, 34, 60, 35, 61, 36, 63, 37, 65, 38, 67, 39, 69, 40, 71, 41, 73, 43, 76, 44, 78, 46, 81, 47, 84, 49, 87, 51, 91, 53, 95, 55, 99, 58, 103, 60, 108, 63, 114, 66, 120, 70, 126, 74, 134, 78, 142, 83, 152, 89, 0, 0, 0, 0, 0, 0, 0, 0, 13, 12, 13, 12, 13, 12, 14, 12, 14, 13, 14, 13, 14, 13, 14, 13, 15, 13, 15, 14, 15, 14, 15, 14, 16, 14, 16, 15, 16, 15, 16, 15, 17, 15, 17, 16, 17, 16, 18, 16, 18, 17, 18, 17, 19, 17, 19, 18, 19, 18, 20, 18, 20, 19, 21, 19, 21, 20, 22, 20, 22, 20, 23, 21, 23, 21, 24, 22, 24, 23, 25, 23, 26, 24, 27, 24, 27, 25, 28, 26, 29, 27, 30, 27, 31, 28, 32, 29, 33, 30, 34, 31, 35, 32, 37, 34, 38, 35, 39, 36, 41, 38, 43, 40, 45, 41, 47, 43, 49, 46, 52, 48, 55, 51, 58, 54, 62, 57, 66, 61, 71, 65, 76, 70, 83, 76, 90, 83, 34, 7, 35, 8, 35, 8, 36, 8, 36, 8, 37, 8, 37, 8, 38, 8, 38, 8, 39, 9, 40, 9, 40, 9, 41, 9, 42, 9, 42, 9, 43, 10, 44, 10, 45, 10, 45, 10, 46, 10, 47, 10, 48, 11, 49, 11, 50, 11, 51, 11, 52, 12, 53, 12, 54, 12, 55, 12, 57, 13, 58, 13, 59, 13, 61, 14, 62, 14, 64, 14, 65, 15, 67, 15, 69, 15, 71, 16, 73, 16, 75, 17, 77, 17, 80, 18, 82, 19, 85, 19, 88, 20, 91, 21, 95, 21, 98, 22, 102, 23, 107, 24, 111, 25, 116, 26, 122, 28, 128, 29, 135, 31, 142, 32, 151, 34, 160, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    align 8
bgcolors:
    byte 192, 192, 176, 176, 176, 176, 176, 176, 176, 240, 176, 176, 176, 16, 240, 240, 240, 192, 176, 240, 240, 192, 192, 240, 240, 240, 240, 240, 192, 240, 240, 240, 240, 240, 192, 240, 16, 16, 192, 176, 192, 176, 192, 192, 176, 176, 176, 176, 192, 192, 192, 176, 192, 240, 192, 240, 192, 240, 16, 240, 192, 240, 240, 240, 240, 16, 192, 240, 16, 240, 240, 192, 176, 176, 16, 240, 192, 240, 192, 176, 16, 192, 176, 192, 240, 240, 176, 192, 240, 176, 240, 240, 240, 192, 16, 16, 16, 16, 16, 192, 240, 16, 16, 240, 16, 16, 240, 240, 16, 240, 240, 192, 176, 192, 16, 192, 192, 176, 176, 176, 240, 176, 176, 176, 176, 192, 240, 240, 240, 192, 176, 240, 240, 240, 16, 16, 16, 240, 16, 240, 240, 192, 192, 192, 240, 16, 16, 16, 16, 16, 16, 192, 176, 16, 240, 240, 192, 192, 192, 176, 240, 176, 176, 176, 176, 192, 240, 240, 192, 176, 240, 16, 16, 16, 240, 16, 240, 16, 240, 240, 240, 192, 176, 176, 192, 240, 240, 16, 240, 240, 16, 16, 16, 240, 240, 16, 240, 192, 16, 240, 240, 192, 192, 192, 176, 240, 240, 16, 192, 176, 192, 240, 240, 240, 240, 16, 16, 16, 240, 16, 192, 192, 192, 176, 192, 240, 240, 192, 192, 240, 240, 16, 240, 192, 240, 240, 192, 192, 16, 240, 16, 176, 176, 192, 16, 16, 240, 192, 240, 240, 240, 16, 16, 240, 192, 16, 16, 240, 240, 240, 176, 192, 240, 240, 240, 16, 240, 240, 240, 240, 240, 192, 192, 240, 192, 192, 176, 240, 16, 240, 240, 192, 176, 240, 240, 240, 240, 192, 192, 240, 240, 240, 240, 16, 240, 240, 240, 240, 176, 192, 240, 240, 240, 16, 240, 16, 240, 240, 192, 176, 240, 192, 176, 176, 176, 176, 176, 240, 240, 16, 16, 240, 240, 240, 240, 16, 240, 192, 240, 192, 176, 176, 16, 192, 240, 16, 240, 192, 176, 240, 176, 176, 240, 16, 16, 192, 16, 240, 240, 240, 240, 176, 176, 176, 192, 192, 240, 240, 176, 192, 240, 16, 16, 240, 240, 240, 16, 240, 240, 192, 176, 176, 240, 16, 240, 240, 192, 176, 176, 176, 176, 176, 176, 240, 16, 16, 16, 240, 240, 192, 16, 192, 240, 192, 192, 192, 240, 240, 176, 176, 240, 16, 16, 16, 16, 240, 240, 192, 192, 176, 176, 176, 240, 240, 192, 240, 192, 176, 176, 176, 192, 176, 176, 16, 240, 240, 16, 240, 192, 16, 240, 192, 240, 16, 240, 192, 192, 192, 176, 176, 192, 192, 240, 16, 192, 176, 192, 192, 192, 240, 192, 176, 240, 192, 192, 240, 192, 176, 176, 176, 176, 192, 192, 240, 240, 240, 16, 240, 240, 240, 240, 192, 16, 16, 240, 176, 176, 176, 192, 176, 176, 176, 176, 240, 176, 176, 176, 16, 192, 176, 240, 16, 240, 192, 240, 240, 176, 176, 176, 176, 240, 176, 176, 176, 240, 240, 16, 240, 240, 176, 176, 176, 240, 16, 192, 176, 176, 176, 192, 176, 240, 176, 176, 176, 176, 176, 176, 16, 240, 192, 16, 240, 240, 240, 240, 192, 192, 176, 176, 192, 176, 176, 176, 176, 176, 240, 240, 240, 240, 240, 192, 240, 16, 16, 240, 16, 240, 240, 240, 176, 240, 176, 176, 176, 176, 176, 176, 192, 240, 240, 192, 240, 240, 240, 240, 240, 240, 240, 192, 192, 176, 176, 176, 176, 176, 176, 192, 240, 16, 240, 16, 16, 176, 240, 240, 192, 176, 176, 240, 176, 192, 240, 176, 176, 176, 176, 176, 176, 192, 240, 240, 16, 16, 16, 16, 16, 16, 192, 176, 240, 240, 176, 176, 176, 176, 176, 192, 240, 16, 192, 176, 16, 176, 176, 192, 192, 176, 192, 240, 176, 176, 176, 176, 176, 176, 176, 176, 176, 240, 16, 240, 240, 240, 16, 16, 16, 240, 176, 176, 192, 240, 176, 176, 176, 176, 176, 240, 240, 240, 176, 192, 192, 192, 176, 176, 192, 240, 240, 240, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 192, 240, 192, 240, 240, 16, 16, 176, 176, 192, 192, 176, 176, 176, 176, 176, 176, 240, 240, 176, 176, 16, 240, 192, 176, 176, 192, 240, 240, 192, 240, 176, 176, 16, 240, 176, 176, 176, 192, 176, 176, 16, 192, 192, 240, 240, 240, 176, 176, 176, 240, 176, 176, 176, 176, 192, 240, 240, 240, 192, 176, 240, 16, 240, 192, 192, 240, 240, 192, 192, 176, 240, 176, 176, 176, 16, 240, 240, 240, 192, 192, 192, 240, 192, 240, 192, 240, 192, 176, 176, 176, 192, 192, 240, 240, 176, 176, 192, 16, 240, 192, 192, 240, 16, 16, 16, 240, 176, 176, 176, 176, 192, 176, 176, 176, 176, 240, 16, 16, 16, 240, 240, 16, 240, 240, 176, 240, 240, 176, 176, 176, 192, 240, 240, 192, 176, 192, 240, 16, 16, 16, 240, 240, 240, 192, 176, 176, 176, 176, 176, 176, 240, 176, 176, 176, 240, 240, 16, 16, 240, 16, 192, 240, 176, 176, 176, 176, 192, 176, 176, 176, 240, 240, 192, 192, 192, 240, 240, 240, 240, 240, 16, 240, 192, 192, 192, 240, 176, 176, 176, 192, 240, 240, 192, 192, 176, 192, 16, 16, 240, 240, 240, 240, 176, 176, 176, 176, 192, 176, 176, 240, 16, 240, 16, 16, 16, 240, 192, 240, 192, 240, 240, 192, 176, 176, 192, 16, 240, 192, 240, 240, 192, 192, 192, 176, 176, 240, 240, 240, 240, 240, 16, 192, 192, 176, 176, 176, 192, 176, 176, 192, 240, 16, 16, 16, 240, 16, 240, 176, 176, 176, 240, 176, 176, 176, 192, 16, 240, 192, 16, 192, 176, 192, 240, 192, 240, 192, 192, 176, 240, 16, 16, 240, 192, 176, 240, 192, 176, 176, 176, 176, 240, 16, 240, 240, 176, 176, 240, 16, 192, 192, 240, 192, 176, 192, 192, 16, 176, 176, 176, 192
    align 8
tetrapos:                       ; x and y sequential coords for sprite location
    byte 120, 193, 121, 192, 121, 192, 122, 192, 123, 191, 124, 191, 124, 191, 125, 191, 126, 190, 127, 190, 128, 190, 129, 190, 130, 189, 131, 189, 133, 189, 134, 189, 135, 189, 136, 188, 138, 188, 139, 188, 140, 188, 142, 188, 143, 188, 144, 188, 146, 187, 147, 187, 149, 187, 150, 187, 152, 187, 153, 187, 155, 187, 156, 187, 158, 187, 159, 187, 160, 187, 162, 187, 163, 187, 165, 187, 166, 187, 168, 187, 169, 187, 171, 188, 172, 188, 173, 188, 175, 188, 176, 188, 177, 188, 179, 188, 180, 189, 181, 189, 182, 189, 184, 189, 185, 189, 186, 190, 187, 190, 188, 190, 189, 190, 190, 191, 191, 191, 191, 191, 192, 191, 193, 192, 194, 192, 194, 192, 195, 193, 195, 193, 195, 193, 195, 194, 196, 194, 196, 194, 196, 195, 195, 195, 195, 196, 195, 196, 194, 196, 194, 197, 193, 197, 192, 197, 191, 198, 190, 198, 189, 199, 188, 199, 186, 199, 185, 200, 183, 200, 181, 200, 180, 200, 178, 201, 176, 201, 174, 201, 171, 201, 169, 201, 167, 202, 165, 202, 162, 202, 160, 202, 158, 202, 155, 202, 153, 202, 150, 202, 148, 202, 146, 201, 144, 201, 141, 201, 139, 201, 137, 201, 135, 200, 134, 200, 132, 200, 130, 200, 129, 199, 127, 199, 126, 199, 125, 198, 124, 198, 123, 197, 122, 197, 121, 197, 121, 196, 120, 196, 120, 196, 120, 195, 119, 195, 119, 194, 119, 194, 120, 194, 120, 193, 120, 193
    align 8
audiosnippet1:                  ; 160 values to match 2 bars of music
    byte 0, 2, 17, 15, 13, 12, 10, 9, 8, 7, 6, 5, 4, 4, 4, 4, 3, 3, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 10, 9, 8, 7, 6, 5, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 4, 11, 10, 9, 8, 7, 6, 5, 5, 4, 4, 4, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 8, 16, 15, 13, 12, 10, 9, 8, 7, 6, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 10, 9, 7, 7, 6, 5, 5, 4, 4, 4, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 7, 11, 10, 8, 7, 6, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    align 8
easein_table:                   ; 256 values that rise smoothly from 0 to 255
    byte 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9, 9, 9, 10, 10, 11, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 18, 18, 19, 19, 20, 21, 21, 22, 22, 23, 24, 24, 25, 26, 26, 27, 28, 28, 29, 30, 31, 31, 32, 33, 34, 34, 35, 36, 37, 38, 38, 39, 40, 41, 42, 43, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 79, 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 93, 94, 95, 96, 97, 99, 100, 101, 102, 104, 105, 106, 107, 109, 110, 111, 113, 114, 115, 116, 118, 119, 120, 122, 123, 124, 126, 127, 128, 130, 131, 133, 134, 135, 137, 138, 139, 141, 142, 144, 145, 146, 148, 149, 151, 152, 154, 155, 156, 158, 159, 161, 162, 164, 165, 167, 168, 170, 171, 173, 174, 176, 177, 178, 180, 181, 183, 184, 186, 187, 189, 191, 192, 194, 195, 197, 198, 200, 201, 203, 204, 206, 207, 209, 210, 212, 213, 215, 217, 218, 220, 221, 223, 224, 226, 227, 229, 231, 232, 234, 235, 237, 238, 240, 241, 243, 245, 246, 248, 249, 251, 252, 254, 255
    align 8
sintable:                       ; 256 page aligned sin values from -15 to 15
    byte 0, 0, 0, 1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 14, 14, 14, 14, 14, 14, 13, 13, 13, 13, 13, 12, 12, 12, 12, 11, 11, 11, 10, 10, 10, 10, 9, 9, 9, 8, 8, 8, 7, 7, 7, 6, 6, 5, 5, 5, 4, 4, 4, 3, 3, 2, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, -1, -1, -2, -2, -2, -3, -3, -4, -4, -4, -5, -5, -5, -6, -6, -7, -7, -7, -8, -8, -8, -9, -9, -9, -10, -10, -10, -10, -11, -11, -11, -12, -12, -12, -12, -13, -13, -13, -13, -13, -14, -14, -14, -14, -14, -14, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -15, -14, -14, -14, -14, -14, -14, -13, -13, -13, -13, -13, -12, -12, -12, -12, -11, -11, -11, -11, -10, -10, -10, -9, -9, -9, -8, -8, -8, -7, -7, -7, -6, -6, -6, -5, -5, -5, -4, -4, -3, -3, -3, -2, -2, -1, -1, -1, 0, 0, 0

    org M_sprite1               ; location in vic memory
    incbin scandal.bin          ; 7 sprites, 448 bytes

    org M_font                  ; location in vic memory
    incbin font.bin             ; 512 byte font

    org M_graphics
    incbin shadowlord.bin       ; 2048 byte graphics
    incbin shadowlord_color.bin ; 32 byte color and mask shape

    org M_sprite2
    incbin tetrahedron.bin
