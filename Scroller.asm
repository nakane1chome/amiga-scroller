				opt			O+,W-

				jmp			Start

				Incdir		"Include:"
				Include		"exec/memory.i"

				Include		"Sprites.i"
				Include		"Joystick.i"
				Include		"Macros.i"

				Include		"Sprites.asm"
				Include		"Ints.asm"
				Include		"Copper.asm"      
				Include		"Blit.asm"

				Include		"Data.i"

		SECTION	Startup,CODE

Start:
				move.l		$4.w,a6
        ;
        ; Alloc Screen mem
        ;
				move.l		#pf1_buffer,d0
				move.l		#MEMF_CHIP+MEMF_CLEAR,d1
				jsr			_LVOAllocMem(a6)
				move.l		d0,BackGround+pf_Base
				beq.s		.error0

				move.l		#pf2_buffer,d0
				move.l		#MEMF_CHIP+MEMF_CLEAR,d1
				jsr			_LVOAllocMem(a6)
				move.l		d0,ForeGround1+pf_Base
				beq.s		.error1

				move.l		#pf2_buffer,d0
				move.l		#MEMF_CHIP+MEMF_CLEAR,d1
				jsr			_LVOAllocMem(a6)
				move.l		d0,ForeGround2+pf_Base
				beq.s		.error2

        ;
        ;will run _main (Supervisor + No OS, Ints, DMA)
        ;
				jsr			Setup

				move.l		$4.w,a6

        ;               
        ;Free Screen Mem
        ;

				move.l		ForeGround2+pf_Base,a1
				move.l		#pf2_buffer,d0
				jsr			_LVOFreeMem(a6)

.error2
				move.l		ForeGround1+pf_Base,a1
				move.l		#pf2_buffer,d0
				jsr			_LVOFreeMem(a6)

.error1
				move.l		BackGround+pf_Base,a1
				move.l		#pf1_buffer,d0
				jsr			_LVOFreeMem(a6)

.error0
				moveq.l		#0,d0
				rts             


*********************************************************************
*                                                                   *
*               Remove os etc.                                      *
*                                                                   *
*********************************************************************

                even
                include "setup.asm"

*********************************************************************
*                                                                   *
*               Main Program Loop                                   *
*                                                                   *
*********************************************************************

				SECTION Main,CODE

_main:
				move.w		#DMAF_SETCLR+DMAF_MASTER+DMAF_RASTER+DMAF_BLITTER,custom+dmacon

				jsr			LoadPalette
				jsr			LoadCopper
				jsr			LoadInts
				jsr			InitBlitter
				
				lea			Player_Data,a0			;assumed to stay in a0
				jsr			ResetLevel

				lea			Player_Data,a0			;assumed to stay in a0

.MainLoop		bsr			CheckInput
				bsr			PlayerFrames
				bsr			ScrollLevel
				bsr			SetScrollOffset		
				bsr			MovePlayer
				jsr			LoadBGSprites
				jsr			DoBobs
				jsr			MoveBullets
				jsr			MoveEnemies

				jsr			WaitVB
				jsr			SwapBuffers

.pause			move.b		rawkey,d0
				cmp.b		#$40,d0
				beq.s		.pause

				move.b		#0,rawkey
				cmp.b		#$45,d0
				bne			.MainLoop

.exit			move.w		#DMAF_ALL,custom+dmacon
				rts

*********************************************************************
*                                                                   *
*               Setup Level			                                *
*                                                                   *
*********************************************************************

ResetLevel:		;a0 = player data
				move.l		p_Level(a0),a1
				move.w		l_PlayerStartX(a1),d0
				move.w		d0,p_X(a0)
				move.w		l_PlayerStartY(a1),d1
				move.w		d1,p_Y(a0)

				sub.w		#screenx/2,d0
				bgt.s		.y
				moveq.w		#0,d0
.y				sub.w		#screeny/2,d1
				bgt.s		.next
				moveq.w		#0,d1
.next
				move.w		d0,l_X(a1)
				move.w		d1,l_Y(a1)

				jsr			SetScrollOffset

				move.l		p_Level(a0),a1
				move.l		l_Map(a1),a2
				move.l		l_Gfx(a1),a3

				move.l		BackGround+pf_Base,a4
				move.l		BackGround+pf_ByteOffset,d3
				and.b		#$FC,d3						;block quantize
				subq.l		#4,d3						;start 1 block left
				add.l		d3,a4
				
				lsr.w		#blockshift,d0
				lea			-1(a2,d0.w),a2			;map start (with shift 1 block left)
				move.w		l_Width(a1),d0
				sub.w		#fetchx/blocksize+1,d0	;map modulus
				move.w		#7,d6
.vertloop		move.w		#fetchx/blocksize,d7

.horizloop		CLR_L		d1
				move.b		(a2)+,d1
				MULU4_W		d1
				move.l		(a3,d1.w),a5
				move.l		a4,a6

				move.w		#blocksize*4-1,d5
.copyloop		move.l		(a5)+,(a6)
				add.l		#pf1_bufferx/8,a6
				dbra.w		d5,.copyloop

				add.l		#blocksize/8,a4
				dbra.w		d7,.horizloop
				
				add.l		d0,a2
				add.l		#blocksize*(pf1_bufferx/8)*4-fetchx/8-blocksize/8,a4
				
				dbra.w		d6,.vertloop

.resetbullets	move.w		#0,p_NoBullets(a0)
				move.w		#0,p_WaitBullet(a0)
				move.l		p_Bullets(a0),a1
				move.b		#No_Bullets,d0
.bloop			move.w		#0,bt_Y(a1)
				lea			bt_SIZEOF(a1),a1
				sub.b		#1,d0
				bne			.bloop

				rts

*********************************************************************
*                                                                   *
*               Swap Buffer		                                    *
*                                                                   *
*********************************************************************
SwapBuffers:	tst.w		p_DblBuffer(a0)
				bne.s		.buf2
				
				lea			ForeGround1,a1
				move.l		a1,p_ForeGround(a0)
				move.l		p_Bobs1(a0),p_Bobs(a0)
				move.l		p_Bullets01(a0),p_BulletsC(a0)
				move.w		#1,p_DblBuffer(a0)
				rts

.buf2			lea			ForeGround2,a1
				move.l		a1,p_ForeGround(a0)
				move.l		p_Bobs2(a0),p_Bobs(a0)
				move.l		p_Bullets02(a0),p_BulletsC(a0)
				move.w		#0,p_DblBuffer(a0)
				rts


*********************************************************************
*                                                                   *
*               Move Player		                                    *
*                                                                   *
*********************************************************************
MovePlayer:		move.l		p_Level(a0),a1

				move.w		p_X(a0),d0
				sub.w		l_X(a1),d0
			
				move.w		p_Y(a0),d1
				sub.w		l_Y(a1),d1

				lea			PlayerSprite,a6
				jsr			MoveSprite

				rts

*********************************************************************
*                                                                   *
*               Move Enemies	                                    *
*                                                                   *
*********************************************************************
MoveEnemies:	move.l		p_Enemies(a0),a1

				move.w		p_X(a0),d0
				lsr.w		#2,d0
				move.w		d0,en_X(a1)
				move.w		p_Y(a0),en_Y(a1)
				
				lea			en_SIZEOF(a1),a1
				move.w		d0,en_X(a1)
				move.w		p_Y(a0),d0
				add.w		#32,d0
				move.w		d0,en_Y(a1)
				
				rts

*********************************************************************
*                                                                   *
*               Move Bullets	                                    *
*                                                                   *
*********************************************************************

wait			equ			10
speed			equ			10
hand_y			equ			44
hand_x			equ			32				; in the middle for forward & reverse

MoveBullets:	move.l		p_Level(a0),a2
				move.l		l_Map(a2),a3

				BUTTON1
				bne			.nofire

				move.w		p_WaitBullet(a0),d0
				beq			.newbullet
				subq.w		#1,d0
				move.w		d0,p_WaitBullet(a0)
				bra			.moveold

.newbullet		move.w		p_NoBullets(a0),d0
				cmpi.w		#No_Bullets,d0
				beq			.nofire
				addq.w		#1,d0
				move.w		d0,p_NoBullets(a0)
				move.w		#wait,p_WaitBullet(a0)
				
				move.l		p_Bullets(a0),a1
				move.b		#No_Bullets,d7
.loop01			tst.w		bt_Y(a1)
				beq			.addbullet
				lea			bt_SIZEOF(a1),a1
				subi.b		#1,d7
				bne			.loop01

.addbullet		move.b		p_Dir(a0),bt_Dir(a1)
				move.w		p_Y(a0),d0
				add.w		#hand_y,d0
				move.w		d0,bt_Y(a1)
				moveq.l		#0,d1
				move.w		p_X(a0),d1
				add.w		#hand_x,d1
				move.w		d1,d2
				sub.w		l_X(a2),d2
				move.w		d2,bt_X(a1)

				lsr.w		#blockshift,d0
				mulu.w		l_Width(a2),d0
				lsr.w		#blockshift,d1
				add.w		d1,d0
				move.w		d0,bt_Block(a1)
				btst.b		#block,(a3,d0.w)
				beq			.moveold
				move.w		#0,bt_Y(a1)
				sub.w		#1,p_NoBullets(a0)
				bra			.moveold

.nofire			move.w		#0,p_WaitBullet(a0)
				
.moveold		move.b		#No_Bullets,d7
				move.l		p_Bullets(a0),a1
				
.loop02			tst.w		bt_Y(a1)
				beq			.next

				move.w		bt_X(a1),d0
				move.w		d0,d1
				tst.b		bt_Dir(a1)
				beq			.pos
				
				moveq.w		#-1,d6					;d6 = block ptr delta
				sub.w		#speed,d0
				ble			.clearbullet
				bra			.check
.pos				
				moveq.w		#1,d6					;d6 = block ptr delta
				add.w		#speed,d0
				cmp.w		#blit_dest_bytewidth*8,d0
				bge			.clearbullet

.check			move.w		d0,bt_X(a1)
				add.w		l_X(a2),d0
				lsr.w		#blockshift,d0
				add.w		l_X1(a2),d1
				lsr.w		#blockshift,d1
				cmp.w		d1,d0
				beq			.next
				
				move.w		bt_Block(a1),d0
				add.w		d6,d0
				move.w		d0,bt_Block(a1)
				btst.b		#block,(a3,d0.w)
				beq			.next
				
.clearbullet	move.w		#0,bt_Y(a1)
				sub.w		#1,p_NoBullets(a0)

.next			lea			bt_SIZEOF(a1),a1
				subi.b		#1,d7
				bne			.loop02

				rts

*********************************************************************
*                                                                   *
*		Sets the byte offset and scroll value for a pf1				*
*																	*
*                                                                   *
*********************************************************************
SetScrollOffset:move.l		p_Level(a0),a1
				move.l		p_BackGround(a0),a2

				move.w		l_X(a1),d0
				
				CLR_L		d1
				move.w		d0,d1
				lsr.w		#3,d1				;l_X/8
				move.l		d1,pf_ByteOffset(a2)
				
				move.w		#d_pfscroll,d1
				sub.b		d0,d1
				and.b		#$0F,d1
				move.w		d1,bplcon+6			;assume no offset for pf2
				
;				add.w		#1,l_Y(a1)
;				move.w		l_Y(a1),d1
;				and.w		#$00FF,d1			; assumes display of 256 lines
;				mulu.w		pf_ByteWidth(a2),d1
;				lsl.l		#2,d1				; assume depth 4 interleaved
;				move.l		d1,pf_ByteOffsetY(a2)
				
				rts

*********************************************************************
*                                                                   *
*               Do Scolling		                                    *
*                                                                   *
*********************************************************************

LeftScroll		equ			32*3
RightScroll		equ			320-16-64-LeftScroll

ScrollLevel:	move.l		p_Level(a0),a1

				move.w		l_X(a1),d0
				move.w		d0,l_X1(a1)				; save old level X
				move.w		p_X(a0),d1
				sub.w		d0,d1                   ;player rel to level

				move.w		p_VelocityX(a0),d2
				blt.s		.left
				tst.w		d2
				bgt.s		.right
				rts

.left			cmpi.w		#LeftScroll,d1
				blt			ScrollLeft
				rts

.right			cmpi.w		#RightScroll,d1
				bgt			ScrollRight
				rts

ScrollRight:	move.w		l_Width(a1),d7
				mulu.w		#blocksize,d7
				subi.w		#fetchx,d7

				move.w		d0,d3				;original l_X
				add.w		d2,d0				;new l_X

				cmp.w		d7,d0				;dont scroll onto last block
				blt.s       .scroll
				move.w		d7,d0

.scroll			move.w		d0,l_X(a1)			;save new value

				move.w		d0,d1
				sub.w		d3,d1
				move.w		#4,d2
				move.w		#10,d3

				bra			DrawBlocks			

ScrollLeft:		move.w		d0,d1				;original l_X
				add.w		d2,d0				;new l_X

				cmpi.w		#blocksize,d0		;dont scroll onto last block
				bgt.s		.scroll
				move.w		#blocksize,d0

.scroll			move.w		d0,l_X(a1)			;save new value

				sub.w		d0,d1
				move.w		#-4,d2
				move.w		#-1,d3

;d0 step d2 , d1 blocks,  drawn at offset d3 (blocks)
;(a0 = player data, a1 = level)

DrawBlocks:		move.l		BackGround+pf_Base,a2
				move.l		l_Map(a1),a3
				move.l		l_Gfx(a1),a4

				lsr.w		#2,d1

.drawloop		move.w		d0,d4
				lsr.w		#2,d4					;vert block no (0-7)
				andi.w		#$0007,d4

				CLR_L		d5
				move.w		d0,d5
				lsr.w		#blockshift,d5			;horiz block no
				add.w		d3,d5

				move.w		d4,d6
				mulu.w		l_Width(a1),d6
				add.l		d5,d6					;offset into level map

				CLR_L		d7
				move.b		(a3,d6.l),d7			;gfx number
				MULU4_W		d7
				move.l		(a4,d7.w),a5

				lsl.w		#2,d5
				mulu.w		#pf1_bufferx*pf1_depth*blocksize/8,d4
				move.l		a2,a6
				add.l		d5,a6
				add.l		d4,a6

				move.b		#blocksize*4,d7
.copyloop		move.l		(a5)+,(a6)
				add.l		#pf1_bufferx/8,a6
				subi.b		#1,d7
				bne.s		.copyloop

				add.w		d2,d0
				dbra		d1,.drawloop
				
				rts

*********************************************************************
*                                                                   *
*               Checks Input                                        *
*                                                                   *
*********************************************************************
CheckInput:		lea			Player_Data,a0
				lea			PlayerSprite,a1
				move.l		p_Frameset(a0),a2
				move.l		p_Level(a0),a3
				move.l		l_Map(a3),a4

				JOYTESTN	1,Player_Left,Player_Right,Player_Up,Player_Down,JoyDone
				;Dont Change d1 !

friction		equ			1

TopEdge			equ			16
HeadX			equ			24+4
BottomEdge
LeftEdge		equ			16		;pixels
RightEdge		equ			47
TopLeftEdge		equ			20		;pixels
TopRightEdge	equ			40


left			equ			1
right			equ			0

Player_Left:	move.b		#left,p_Dir(a0)
				move.b		#0,p_Skid(a0)
				
				move.w		p_VelocityX(a0),d0
				sub.w		l_PlayerAccnX(a3),d0
				move.w		l_PlayerMaxVX(a3),d7
				neg.w		d7
				cmp.w		d7,d0
				bge			.SaveV
				move.w		d7,d0
.SaveV			move.w		d0,p_VelocityX(a0)

				bra			UpDown1

Player_Right:	move.b		#right,p_Dir(a0)
				move.b		#0,p_Skid(a0)

				move.w		p_VelocityX(a0),d0
				add.w		l_PlayerAccnX(a3),d0
				move.w		l_PlayerMaxVX(a3),d7
				cmp.w		d7,d0
				ble.s		.SaveV
				move.w		d7,d0
.SaveV			move.w		d0,p_VelocityX(a0)

				bra			UpDown1

Player_Up:      tst.b		p_Jump(a0)
				bne			JoyDone

				move.b		#1,p_Jump(a0)
				move.w		l_PlayerJumpV(a3),p_VelocityY(a0)

				bra			JoyDone
Player_Down:
JoyDone:
Move_Player:	move.w		p_X(a0),d1
				move.w		p_Y(a0),d2

				move.w		p_VelocityX(a0),d0
				beq			.noVX

				tst.w		d0
				blt.s		.inc
				subq.w		#friction,d0
				bra.s		.MoveX
.inc			addq.w      #friction,d0
.MoveX			tst.w		d0
				beq			.noVX

				move.w		d2,d3
				lsr.w		#blockshift,d3
				addq.w		#spriteblocks,d3	;+ sprite height
				mulu.w		l_Width(a3),d3		;offset into map feet

				CLR_L		d4
				move.w		d0,d4
				blt.s		.TestLeft
				add.w		#RightEdge,d4		;test right for block
				move.w		#-RightEdge-1,d7
				bra.s		.there
.TestLeft		add.w		#LeftEdge,d4		;test left for block
				move.w		#blocksize-LeftEdge,d7
.there			add.w		d1,d4
				move.w		d4,d6
				lsr.w		#blockshift,d4
				add.l		d3,d4

				btst.b		#block,(a4,d4.l)
				bne			.stopX			;feet blocked

				CLR_L		d3
				move.w		l_Width(a3),d3
				sub.l		d3,d4
				btst.b		#block,(a4,d4.l)
				bne			.stopX			;mid blocked

				move.w		d2,d3
				add.w		#TopEdge,d3			;top edge
				lsr.w		#blockshift,d3
				mulu.w		l_Width(a3),d3		;offset into map head

				CLR_L		d4
				move.w		d0,d4
				blt.s		.TestTopLeft
				add.w		#TopRightEdge,d4		;test right for block
				move.w		#-TopRightEdge-1,d7
				bra.s		.topthere
.TestTopLeft	add.w		#TopLeftEdge,d4		;test left for block
				move.w		#blocksize-TopLeftEdge,d7
.topthere		add.w		d1,d4
				move.w		d4,d6
				lsr.w		#blockshift,d4
				add.l		d3,d4

				btst.b		#block,(a4,d4.l)
				beq			.Save_MoveX			;head not blocked

.stopX			andi.w		#~blockmask,d6
				add.w		d7,d6
				move.w		d6,d1
				
.noVX			move.w		#0,d0
				
				CLR_W		d7
				move.b		p_Dir(a0),d7
				MULU4_B		d7
				move.l		f_Stand(a2,d7.w),s_Data(a1)

.Save_MoveX		add.w		d0,d1
				move.w		d1,p_X(a0)
				move.w		d0,p_VelocityX(a0)

.MoveY			move.w		#0,d3
				tst.b		p_Jump(a0)
				beq.s		.TestGround					;not jumping
;
;		Jumping
;
				move.w		p_VelocityY(a0),d3			;do gravity

				add.w		l_PlayerGravity(a3),d3
				move.w		l_PlayerMaxVY(a3),d7
				cmp.w		d7,d3
				ble.s		.TestGround
				move.w		d7,d3

.TestGround		move.w		d3,p_VelocityY(a0)

				tst.w		d3
				blt			.Y_Up					;player going up
;
;	player going down or standing
;
				move.w		d2,d4
				lsr.w		#blockshift,d4				;y block init
				move.w		d2,d5
				add.w		d3,d5
				lsr.w		#blockshift,d5				;y block fin
				
				cmp.w		d4,d5
				bne.s		.changeblocks

.lastblock		addq.w		#spriteblocks,d4			;
				mulu.w		l_Width(a3),d4

				CLR_L		d5
				move.w		d1,d5
				move.l		d5,d6
				add.w		#LeftEdge,d5
				add.w		#RightEdge,d6
				lsr.w		#blockshift,d5				;left foot block
				lsr.w		#blockshift,d6				;right foot block
				cmp.w		d5,d6
				beq.s		.onefoot
				
				add.l		d4,d6
				move.b		(a4,d6.l),d7
				btst		#ground,d7
				beq.s		.passthruR
				btst		#block,d7
				bne			.NoFall_Block
				
				move.w		d2,d6
				add.w		d3,d6
				andi.w		#blockmask,d6
				cmpi.w		#blocksize-1-groundheight,d6
				bge.s		.NoFall_Ground

.passthruR
.onefoot
				add.l		d4,d5
				move.b		(a4,d5.l),d7
				btst		#ground,d7
				beq.s		.passthruL
				btst		#block,d7
				bne.s		.NoFall_Block
				
				move.w		d2,d5
				add.w		d3,d5
				andi.w		#blockmask,d5
				cmpi.w		#blocksize-1-groundheight,d5
				bge.s		.NoFall_Ground
				bra.s		.passthruL
				
.changeblocks	addq.w		#spriteblocks,d4
				mulu.w		l_Width(a3),d4
				
				moveq.l		#0,d6
				move.w		d1,d6
				move.l		d6,d7
				add.w		#LeftEdge,d6
				add.w		#RightEdge,d7
				lsr.w		#blockshift,d6				;left foot
				lsr.w		#blockshift,d7				;right foot
				add.l		d4,d6
				add.l		d4,d7
								
				btst.b		#ground,(a4,d6.l)			;left foot
				bne.s		.NoFall_Ground
				btst.b		#ground,(a4,d7.l)			;right foot
				bne.s		.NoFall_Ground

				add.w		d3,d2						;check next block
				move.w		d5,d4
				move.w		#0,d3
				bra			.lastblock

.passthruL		add.w		d3,d2
				move.w		d2,p_Y(a0)
				move.b		#1,p_Jump(a0)
				rts

.NoFall_Ground	andi.w		#~blockmask,d2
				addi.w		#blocksize-1-groundheight,d2
				move.w		d2,p_Y(a0)
				move.b		#0,p_Jump(a0)
				rts

.NoFall_Block	andi.w		#~blockmask,d2
				subq.w		#1,d2
				move.w		d2,p_Y(a0)
				move.b		#0,p_Jump(a0)
				rts

.Y_Up			move.w		p_Y(a0),d0				;d1 p_X(a0), d3 p_VelocityY(a0)
				add.w		d3,d0

				move.w		d0,d2
				add.w		#TopEdge,d2
				lsr.w		#blockshift,d2
				mulu		l_Width(a3),d2
				moveq.l		#0,d4
				move.w		d1,d4
				add.w		#HeadX,d4
				lsr			#blockshift,d4
				add.l		d4,d2
				
				move.b		(a4,d2.l),d4
				btst		#block,d4
				beq			.up_SaveY
				
				move.w		#0,d3
				move.w		d0,d2
				and.b		#$E0,d2
				add.w		#blocksize-TopEdge,d2
				move.w		d2,d0

.up_SaveY		move.w		d3,p_VelocityY(a0)
				move.w		d0,p_Y(a0)
				rts
*********************************************************************
*                                                                   *
*				Do Player Frames									*
*                                                                   *
*********************************************************************
PlayerFrames:
			lea			PlayerSprite,a1
			move.l		p_Frameset(a0),a2
			
			CLR_L		d0
			move.b		p_Dir(a0),d0
			move.b		d0,d1
			
			MULU4_B		d0
			lsl.b		#4,d1
			
			tst.b		p_Jump(a0)
			bne.s		.Jump
			tst.b		p_Skid(a0)
			bne.s		.Skid
			tst.w		p_VelocityX(a0)
			beq.s		.Stand
			
			move.b		#1,p_Skid(a0)

			move.b		p_Frame(a0),d2
			addi.b		#1,d2
			andi.b		#$0F,d2
			move.b		d2,p_Frame(a0)

			andi.b		#$0C,d2
			add.b		d1,d2
			move.l		f_FramesF(a2,d2.w),s_Data(a1)
			rts

.Stand		move.l		f_Stand(a2,d0.w),s_Data(a1)
			rts

.Skid		move.l		f_Skid(a2,d0.w),s_Data(a1)
			rts
			
.Jump		move.l		f_Jump(a2,d0.w),s_Data(a1)
			rts
				
*********************************************************************
*                                                                   *
*               Loads the Interupt Vectors                          *
*                                                                   *
*********************************************************************
LoadInts:		movem.l		a0/d0/d1,-(sp)
				move.l		#custom,a6

				move.w		#INTF_PORTS,intena(a6)

				lea			KB,a0
				move.l		a0,$68.w
				move.w		#$2000,SR

      			move.w		#INTF_SETCLR+INTF_PORTS,intena(a6)
      			move.w		#INTF_PORTS,intreq(a6)

 				move.b		#%01111111,$bfed01		;ciaa - icr : no interupts
				move.b		#%10001000,$bfed01		;ciaa - icr : keyboard serial int
				move.b		#%00000000,$bfee01		;ciaa - cra : keyboard serial - input

      			move.w  	#INTF_VERTB+INTF_COPER+INTF_BLIT,intena(a6)		;turn off first

				lea			VBlank,a0
				move.l		a0,$6C.w				;load new vector
				move.w		#$2000,SR				;turn all ints on

      			move.w		#INTF_SETCLR+INTF_INTEN+INTF_VERTB+INTF_COPER,intena(a6)
*      			move.w		#INTF_VERTB+INTF_COPER,intreq(a6)
 
				movem.l		(sp)+,a0/d0/d1
				rts

*********************************************************************
*                                                                   *
*               Loads the Colours			                        *
*                                                                   *
*********************************************************************
LoadPalette:
			move.l		#custom,a6

			move.w		#d_bplcon3,bplcon3(a6)
			lea      	color(a6),a0
			lea         BackGroundPal,a1
			move.w      #16,d0
.bg			move.w		(a1)+,(a0)+
			dbra.w      d0,.bg

			move.w		#d_bplcon3,bplcon3(a6)
			lea      	color+32(a6),a0
			lea         ForeGroundPal,a1
			move.w      #16,d0
.fg			move.w		(a1)+,(a0)+
			dbra.w      d0,.fg

			move.w		#d_bplcon3+(7*$2000),bplcon3(a6)
			lea			color(a6),a0
			lea			SpritesPal,a1
			move.w		#32,d0
.spr		move.w		(a1)+,(a0)+
			dbra.w		d0,.spr
			move.w		#d_bplcon3,bplcon3(a6)

            rts


*********************************************************************
*                                                                   *
*               Loads BG Sprites			                        *
*                                                                   *
*********************************************************************
LoadBGSprites:
			move.l		p_Level(a0),a1
			CLR_W		d0
			sub.w		l_X(a1),d0
			ext.l		d0
			lea			BGSprites,a2

			move.w		#((bg_y&$FF)<<8),d1
			move.w		#((bg_y+bg_height)&$FF)<<8+((bg_y&$100)>>6)+((bg_y+bg_height)&$100)>>7,d2

			asr.l		#2,d0				;1/4 scrolling
			add.l		#xwstart,d0

			move.b		#6,d3
.loop		move.w		d1,d5
			move.l		d0,d4
.mod00		cmpi.w		#xwstart-64,d4
			bgt.s		.mod01
			add.w		#384,d4
			bra.s		.mod00
.mod01		asr.w		d4
			move.b		d4,d5

			move.w		d2,d6
			move.b		d0,d4
			andi.b		#$01,d4
			or.b		d4,d6

			move.w		d5,(a2)
			move.w		d6,8(a2)

			add.l		#bg_size,a2
			add.l		#64,d0

			subi.b		#1,d3
			bne.s		.loop

			rts

