	 SECTION Fast_Data,DATA_F

		include "keytable.i"

;
;		Data Structs
;

	STRUCTURE	Player_Struct,0
		WORD	p_X
		WORD	p_Y
		BYTE	p_Frame         ;0-3 (*4)
		BYTE	p_Dir           ;0 = Forwards, 1 = Backwards
		BYTE	p_Jump
		BYTE	p_Skid
		WORD	p_VelocityX
		WORD	p_VelocityY
		WORD	p_WaitBullet
		WORD	p_NoBullets
		
		LONG	p_Level			;current level (ptr to struct)
		LONG	p_Frameset		;current player Sprite GFX
		LONG	p_Enemies		;Enemy Positions
		LONG	p_Bobs			;current enemy bobs
		LONG	p_Bobs1
		LONG	p_Bobs2
		LONG	p_Bullets		;
		LONG	p_BulletsC		;
		LONG	p_Bullets01
		LONG	p_Bullets02
		
		LONG	p_BlitRes

		LONG	p_BackGround
		LONG	p_ForeGround	;Ptr to current foreground
		WORD	p_DblBuffer		;Double buffer toggle
		
		LABEL	p_SIZEOF

Player_Data:
		dc.w	100
		dc.w	100
		dc.b	0
		dc.b	0
		dc.b	0
		dc.b	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		
		dc.l	Test_Level
		dc.l	Test_Frames
		dc.l	Enemies
		dc.l	Test_BobList1
		dc.l	Test_BobList1
		dc.l	Test_BobList2
		dc.l	Bullets
		dc.l	Bullets01
		dc.l	Bullets01
		dc.l	Bullets02
		
		dc.l	BlitRes

		dc.l	BackGround
		dc.l	ForeGround1
		dc.w	0

size_blit_stack		equ		10

BlitRes:
		dc.l	blit_stack0
		dc.l	blit_stack0
		dc.l	blit_stack1
		dc.w	size_blit_stack
		dc.w	0
		dc.l	0
		dc.l	0
	
	STRUCTURE	Frame_Set,0
		STRUCT	f_FramesF,16
		STRUCT	f_FramesR,16
		STRUCT	f_Skid,8
		STRUCT	f_Stand,8
		STRUCT	f_Jump,8
		LABEL	f_SIZEOF

	even
					 
Test_Frames:
		dc.l	GreyF+GreySize*0,GreyF+GreySize*2,GreyF+GreySize*4,GreyF+GreySize*2
		dc.l	GreyR+GreySize*0,GreyR+GreySize*2,GreyR+GreySize*4,GreyR+GreySize*2
		dc.l	GreyF+GreySize*2,GreyR+GreySize*2
		dc.l	GreyF+GreySize*2,GreyR+GreySize*2
		dc.l	GreyF+GreySize*0,GreyR+GreySize*0

PlayerSprite:
		  dc.l    GreyF
		  dc.l    GreySize
		  dc.b    8
		  dc.b    1
		  dc.b    1
		  dc.b    0
		  dc.w    64

	STRUCTURE	Nme,0
		WORD	en_X
		WORD	en_Y
		LABEL	en_SIZEOF
		
No_Enemies		equ		2

Enemies:
		ds.b	en_SIZEOF*No_Enemies
		
	STRUCTURE	Bullet_,0
		WORD	bt_X
		WORD	bt_Y
		WORD	bt_Block
		BYTE	bt_Dir
		BYTE	bt_Pad0
		LABEL	bt_SIZEOF
		
No_Bullets		equ		4

Bullets:
		ds.b	bt_SIZEOF*No_Bullets
		
blocksize       equ			32
blockshift		equ			5
blockmask		equ			$001F
spriteblocks	equ			2

	STRUCTURE	Level_struct,0
		LONG	l_Map
		LONG	l_Gfx
		WORD	l_X
		WORD	l_X1
		WORD	l_Y
		WORD	l_Width
		WORD	l_Height
		WORD	l_PlayerStartX
		WORD	l_PlayerStartY
		WORD	l_PlayerAccnX
		WORD	l_PlayerMaxVX
		WORD	l_PlayerJumpV
		WORD	l_PlayerGravity
		WORD	l_PlayerMaxVY
		LABEL	l_SIZEOF

Test_Level:
		dc.l	Level_Map
		dc.l	Block_Map
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	30
		dc.w	8
		dc.w	$f*32
		dc.w	0
		dc.w	2				;AccnX
		dc.w	8				;MaxVX
		dc.w	-14				;JumpV
		dc.w	1				;Gravity
		dc.w	8				;MaxVY
;
; 		Level Maps
;
Level_Map:		 ;0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9
		  dc.b		$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81
		  dc.b		$81,$81,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$81,$81 
		  dc.b		$81,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$80,$81,$81 
		  dc.b		$81,$00,$00,$00,$00,$00,$00,$41,$41,$41,$41,$41,$41,$41,$40,$40,$40,$40,$40,$40,$40,$40,$00,$00,$00,$40,$80,$80,$81,$81 
		  dc.b		$81,$00,$00,$40,$01,$40,$40,$40,$02,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$40,$00,$00,$00,$00,$00,$00,$81 
		  dc.b		$81,$40,$40,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$81,$40,$40,$40,$40,$40,$40,$81 
		  dc.b		$81,$80,$80,$40,$40,$40,$40,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$81,$81,$81,$81,$81,$81 
		  dc.b		$81,$80,$80,$80,$80,$80,$80,$80,$40,$40,$40,$40,$40,$00,$00,$00,$00,$00,$40,$40,$40,$40,$40,$00,$00,$00,$00,$00,$81,$81 
		  dc.b		$81,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$40,$40,$40,$40,$40,$81,$81,$80,$81,$81,$40,$40,$40,$40,$40,$40,$81 

;msb-	00			Empty
;	-	01			Ground
;	-	10			Solid

;bit #'s
block		equ			7		;128-191
ground		equ			6		;64-127

groundheight	equ		3

;0-63, blank

Block_Map:
		dc.l		Blank			;00
		dc.l		Dirt_Left		;01
		dc.l		Dirt_Mid		;02
		dc.l		Blank			;03
		dc.l		Blank			;04
		dc.l		Blank			;05
		dc.l		Blank			;06
		dc.l		Blank			;07
		dc.l		Blank			;08
		dc.l		Blank			;09
		dc.l		Blank			;0a
		dc.l		Blank			;0b
		dc.l		Blank			;0c
		dc.l		Blank			;0d
		dc.l		Blank			;0e
		dc.l		Blank			;0f

		ds.l		(64-16)

;64-127	Ground

		dc.l		Grass_Mid		;40
		dc.l		Grass_Left		;41
		dc.l		Blank			;42
		dc.l		Blank			;43
		dc.l		Blank			;44
		dc.l		Blank			;45
		dc.l		Blank			;46
		dc.l		Blank			;47
		dc.l		Blank			;48
		dc.l		Blank			;49
		dc.l		Blank			;4a
		dc.l		Blank			;4b
		dc.l		Blank			;4c
		dc.l		Blank			;4d
		dc.l		Blank			;4e
		dc.l		Blank			;4f

		ds.l		(64-16)

;128-191	Blocks

		dc.l		Dirt			;80
		dc.l		Stone			;81
		dc.l		Blank			;82
		dc.l		Blank			;83
		dc.l		Blank			;84
		dc.l		Blank			;85
		dc.l		Blank			;86
		dc.l		Blank			;87
		dc.l		Blank			;88
		dc.l		Blank			;89
		dc.l		Blank			;8a
		dc.l		Blank			;8b
		dc.l		Blank			;8c
		dc.l		Blank			;8d
		dc.l		Blank			;8e
		dc.l		Blank			;8f
	
;
;		Block Gfx
;
Blank:		ds.l		32*4
Grass:		incbin		"bin/grass.bin"
Dirt:		incbin		"bin/block1.bin"
Stone:		incbin		"bin/block2.bin"

Grass_Left:	incbin		"bin/grass_left.bin"
Grass_Mid:	incbin		"bin/grass_mid.bin"
Dirt_Left:	incbin		"bin/dirt_left.bin"
Dirt_Mid:	incbin		"bin/dirt_mid.bin"

Test_BobList1:
			dc.l		BltTest
			dc.w		0
			dc.w		0
			dc.w		0
			
			dc.l		BulletBob
			dc.w		0
			dc.w		0
			dc.w		0

Test_BobList2:
			dc.l		BltTest
			dc.w		0
			dc.w		0
			dc.w		0
			
			dc.l		BulletBob		;BltTest
			dc.w		0
			dc.w		0
			dc.w		0

Bullets01:
			dc.l		BulletBob
			dc.w		0
			dc.w		0
			dc.w		0
			
			dc.l		BulletBob
			dc.w		0
			dc.w		0
			dc.w		0

			dc.l		BulletBob		;BltTest
			dc.w		0
			dc.w		0
			dc.w		0
			
			dc.l		BulletBob		;BltTest
			dc.w		0
			dc.w		0
			dc.w		0

Bullets02:
			dc.l		BulletBob
			dc.w		0
			dc.w		0
			dc.w		0
			
			dc.l		BulletBob
			dc.w		0
			dc.w		0
			dc.w		0

			dc.l		BulletBob		;BltTest
			dc.w		0
			dc.w		0
			dc.w		0
			
			dc.l		BulletBob		;BltTest
			dc.w		0
			dc.w		0
			dc.w		0

;
;		Blitter objs
;
BltTest:	dc.l		Fruit
			dc.l		Fruit_Mask
			dc.w		10
			dc.w		32
			dc.w		((32*4)<<6)+5

BulletBob:
			dc.l		Bullet
			dc.l		Bullet_Mask
			dc.w		6
			dc.w		16
			dc.w		((16*4)<<6)+3
			

;
;		Colours
;
SpritesPal:		incbin  "bin/Sprites.pal"
BackGroundPal:	incbin	"bin/background.pal"
ForeGroundPal:	incbin	"bin/foreground.pal"
		  
	SECTION Chip_Data,DATA_C

Fruit:		incbin	"bin/fruit.bin"
Fruit_Mask:	incbin	"bin/fruit_mask.bin"
Bullet:		incbin	"bin/bullet.bin"
Bullet_Mask:incbin	"bin/bullet_mask.bin"

GreySize	equ		8*64*2+8*4
GreyF:		incbin  "bin/GreyF.bin"
GreyR:		incbin  "bin/GreyR.bin"

SpriteNull:	dc.l    0,0,0,0

;6 bgsprites

bg_y		equ		128
bg_height	equ		176
bg_size		equ		(8*bg_height)*2+4*8

BGSprites:
			incbin	"bin/bgsprites.bin"


	SECTION	bss,BSS_F

blit_stack0:
	ds.b	bb_SIZEOF*size_blit_stack
blit_stack1:
	ds.b	bb_SIZEOF*size_blit_stack
