exomizer sfx 2048 interceptor.prg -o interceptor.prg -x 'lda $fb eor #$01 sta $fb beq skip lda $fc eor #$06 sta $d020 sta $fb sta $fc skip:'
