	 SECTION Fast_Data,DATA_F

		include "keytable.i"

;
;		Data Structs
;

	STRUCTURE	Player,0
		WORD	p_X
		WORD	p_Y
		BYTE	p_Frame         ;0-3 (*4)
		BYTE	p_Dir           ;0 = Forwards, 1 = Backwards
		BYTE	p_Jump
		BYTE	p_Pad0
		WORD	p_VelocityX
		WORD	p_VelocityY
		
		WORD	p_Level			;current level (ptr to struct)
		WORD	p_Frameset		;current player Sprite GFX
		
		LABEL	p_SIZEOF

PlayerData:
		dc.w	100
		dc.w	100
		dc.b	0
		dc.b	0
		dc.b	0
		dc.b	0
		dc.w	0
		dc.w	0
	
	STRUCTURE	Frame_Set,0
		STRUCT	f_FramesF,16
		STRUCT	f_FramesR,16
		STRUCT	f_Skid,8
		STRUCT	f_Stand,8
		LABEL	f_SIZEOF

	even
					 
Frames:
		dc.l	OneF,TwoF,ThreeF,TwoF
		dc.l	OneR,TwoR,ThreeR,TwoR
		dc.l	TwoF,TwoR
		dc.l	TwoF,TwoR

PlayerSprite:
		  dc.l    OneF
		  dc.l    8*64*2+8*4
		  dc.b    8
		  dc.b    1
		  dc.b    1
		  dc.b    0
		  dc.w    64

blocksize       equ             32

	STRUCTURE	Level_struct,0
		LONG	l_Map
		LONG	l_Gfx
		WORD	l_X
		WORD	l_Y
		WORD	l_Width
		WORD	l_Height
		LABEL	l_SIZEOF

Level:
		dc.l	Level_Map
		dc.l	Block_Map
		dc.w	32
		dc.w	0
		dc.w	20
		dc.w	8
;
; 		Level Maps
;

Level_Map:
		  dc.b    7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7
		  dc.b    7,0,7,7,7,7,0,0,0,0,0,0,0,0,0,0,0,0,0,7
		  dc.b    7,0,0,0,0,0,7,0,0,0,0,0,7,0,0,0,0,0,0,7
		  dc.b    7,0,0,0,0,0,0,0,7,7,7,7,7,7,7,7,7,0,1,7
		  dc.b    7,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,3,3
		  dc.b    3,3,3,1,1,1,1,1,0,0,0,0,0,0,0,0,1,3,3,3
		  dc.b    3,3,3,3,3,3,3,3,1,1,1,1,1,1,1,1,3,3,3,3
		  dc.b    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3

;lsb-	00			Empty
;	-	01			Ground
;	-	11			Solid

walk		equ			1		;bit defs
support		equ			0
groundheight	equ		3

Block_Map:
		dc.l		Blank			;0000
		dc.l		Grass			;0001
		dc.l		Blank			;0010
		dc.l		Dirt			;0011
		dc.l		Blank			;0100
		dc.l		Blank			;0101
		dc.l		Blank			;0110
		dc.l		Stone			;0111
		dc.l		Blank			;0000
		dc.l		Blank			;0000
		dc.l		Blank			;0000
		dc.l		Blank			;0000
		dc.l		Blank			;0000
		dc.l		Blank			;0000
	
;
;		Block Gfx
;

Blank:		ds.l		32*4
Grass:		incbin		"bin/grass.bin"
Dirt:		incbin		"bin/block1.bin"
Stone:		incbin		"bin/block2.bin"

;
;		Colours
;

spritepal:		incbin  "bin/grey.pal"
BackGroundPal:	incbin	"bin/background.pal"
		  
	SECTION Chip_Data,DATA_C

OneF:		incbin  "bin/1.bin"
TwoF:		incbin  "bin/2.bin"
ThreeF:		incbin  "bin/3.bin"
OneR:		incbin  "bin/1r.bin"
TwoR:		incbin  "bin/2r.bin"
ThreeR:		incbin  "bin/3r.bin"
SpriteNull:	dc.l    0,0,0,0

;5 bgsprites
;64x136

bg_y		equ		128
bg_height	equ		136
bg_size		equ		(8*bg_height)*2+4*8

BGSprites:	incbin	"bin/bgsprites.bin"

