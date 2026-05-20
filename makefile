all: intro.prg

intro.prg: intro.s events.s scroller.txt ../graphics/font.bin ../graphics/shadowlord.bin ../graphics/shadowlord_color.bin ../graphics/tetrahedron.bin ../graphics/scandal.bin unit5.prg
		vasm6502_oldstyle -Fbin -cbm-prg intro.s -o intro.prg
#		retrodebugger intro.prg
		bash exomizer.sh
		denise intro_c.prg

../graphics/font.bin: ../graphics/tga_to_bin.py ../graphics/font_0.tga
		python3 ../graphics/tga_to_bin.py ../graphics/font_0.tga ../graphics/font.bin

../graphics/shadowlord.bin: ../graphics/tga_to_bin.py ../graphics/shadowlord_0.tga
		python3 ../graphics/tga_to_bin.py ../graphics/shadowlord_0.tga ../graphics/shadowlord.bin

../graphics/shadowlord_color.bin: ../graphics/tga_to_bin_straight.py ../graphics/shadowlord_color_0.tga
		python3 ../graphics/tga_to_bin_straight.py ../graphics/shadowlord_color_0.tga ../graphics/shadowlord_color.bin

../graphics/tetrahedron.bin: ../graphics/spriteconv.py ../graphics/tetrahedron_0.tga
		python3 ../graphics/spriteconv.py ../graphics/tetrahedron_0.tga ../graphics/tetrahedron.bin

../graphics/scandal.bin: ../graphics/spriteconv.py ../graphics/scandal_0.tga
		python3 ../graphics/spriteconv.py ../graphics/scandal_0.tga ../graphics/scandal.bin