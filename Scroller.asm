				opt			O+,W-

				jmp			Start

				Incdir		"Include:"
				Include		"exec/memory.i"

				Include		"Sprites.i"
				Include		"Joystick.i"
				Include		"Data.i"


				Include		"Sprites.asm"
				Include		"Ints.asm"
				Include		"Copper.asm"      

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
				move.l		d0,ForeGround+pf_Base
				beq.s		.error1

        ;
        ;will run _main (Supervisor + No OS, Ints, DMA)
        ;
				jsr			Setup

				move.l		$4.w,a6

        ;               
        ;Free Screen Mem
        ;
				move.l		ForeGround+pf_Base,a1
				move.l		#pf2_buffer,d0
				jsr			_LVOFreeMem(a6)

.error1
				move.l		BackGround+pf_Base,a1
				move.l		#pf1_buffer,d0
				jsr			_LVOFreeMem(a6)

.error0:
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
				move.w		#DMAF_SETCLR+DMAF_MASTER+DMAF_RASTER,custom+dmacon

				jsr			LoadCopper
				jsr			LoadInts
				jsr			SetupLevel
				jsr			LoadPalette

				jsr			LoadBGSprites

.MainLoop		bsr			CheckInput
				bsr			ScrollLevel
				bsr			SetScrollOffset		
				bsr			MovePlayer

				jsr			WaitVB

				BUTTON1
				beq.s		.exit
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
start_l_x		equ			32

SetupLevel:
				lea			BackGround,a0
				lea			Level,a1

				move.l		l_Map(a1),a2
				move.l		l_Gfx(a1),a3
				move.l		pf_Base(a0),a4

				move.l		#start_l_x/8,pf_ByteOffset(a0)	;pt offset
				move.w		#start_l_x,l_X(a1)				;level X
				add.l		pf_ByteOffset(a0),a4
				add.l		#start_l_x/blocksize,a2

				move.w		#l_width-fetchx/blocksize-1,d0
				move.w		#7,d6
.vertloop		move.w		#fetchx/blocksize,d7

.horizloop		moveq.l		#0,d1
				move.b		(a2)+,d1
				lsl.w		#2,d1
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

				rts

*********************************************************************
*                                                                   *
*               Move Player		                                    *
*                                                                   *
*********************************************************************
MovePlayer:
				lea			PlayerData,a0
				lea			Level,a1

				move.w		p_X(a0),d0
				addi.w		#xwstart,d0
				sub.w		l_X(a1),d0
				move.w		p_Y(a0),d1
				addi.w		#ywstart,d1
				lea			PlayerSprite,a0
				jsr			MoveSprite

				rts

*********************************************************************
*                                                                   *
*               Do Scolling		                                    *
*                                                                   *
*********************************************************************

LeftScroll		equ			32*3
RightScroll		equ			320-16-64-LeftScroll

ScrollLevel:	lea			PlayerData,a0
				lea			Level,a1

				move.w		l_X(a1),d0
				move.w		p_X(a0),d1
				move.w		p_VelocityX(a0),d2
				sub.w		d0,d1                   ;player rel to level

				cmpi.w		#LeftScroll,d1
				blt			ScrollLeft
				cmpi.w		#RightScroll,d1
				bgt			ScrollRight

				rts

ScrollLeft:		cmpi.w		#blocksize,d0			;dont scroll onto last block
				bgt.s		.scroll
				move.w		#blocksize,l_X(a1)
				rts

.scroll			move.w		d0,d1				;original l_X
				add.w		d2,d0				;new l_X
				sub.w		d0,d1
				move.w		d0,l_X(a1)			;save new value

				move.w		#-4,d2
				move.w		#0,d3

;d0 step d2 , d1 blocks,  drawn at offset d3 (blocks)
;(a0 = player data, a1 = level)

DrawBlocks:		movea.l		BackGround+pf_Base,a2
				move.l		l_Map(a1),a3
				move.l		l_Gfx(a1),a4

.drawloop		move.w		d0,d4
				lsr.w		#2,d4					;vert block no (0-7)
				andi.w		#$0007,d4
				
				moveq.l		#0,d5
				move.w		d0,d5
				lsr.w		#5,d5					;horiz block no
				add.w		d3,d5

				move.w		d4,d6
				mulu.w		#l_width,d6
				add.l		d5,d6					;offset into level map

				moveq.l		#0,d7
				move.b		(a3,d6.l),d7			;gfx number
				lsl.w		#2,d7
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
				
				move.w		#$FF7,$dff180

				rts

r_scroll_limit	equ			l_width*blocksize-fetchx-blocksize

ScrollRight:	cmpi.w		#r_scroll_limit,d0	;dont scroll onto last block
				blt.s       .scroll
				move.w		#r_scroll_limit,l_X(a1)
				rts

.scroll			move.w		d0,d3				;original l_X
				add.w		d2,d0				;new l_X
				move.w		d0,d1
				sub.w		d3,d1
				move.w		d0,l_X(a1)			;save new value

				move.w		#4,d2
				move.w		#10,d3

				bra			DrawBlocks			

*********************************************************************
*                                                                   *
*		Sets the byte offset and scroll value for a pf1				*
*																	*
*                                                                   *
*********************************************************************
SetScrollOffset:		
				movem.l		d0/d2,-(SP)
				
				move.w		Level+l_X,d0
				
				moveq.l		#0,d1
				move.w		d0,d1
				lsr.w		#3,d1				;l_X/8
				moveq.l		#0,d2
				move.w		d1,d2
				divu.w		#pf1_bufferx/8,d1
				mulu.w		#(pf1_bufferx/8)*4,d1
				add.l		d1,d2
				
				move.l		d2,pf_ByteOffset+BackGround
				
				move.w		#15,d1
				moveq.l		#0,d2
				move.b		d0,d2
				and.b		#$0F,d2
				sub.w		d2,d1
				move.w		d1,bplcon+6			;assume no offset for pf2
				
				movem.l		(SP)+,d0/d2
				rts

*********************************************************************
*                                                                   *
*               Checks Input                                        *
*                                                                   *
*********************************************************************
CheckInput:

				lea			PlayerData,a0
				lea			PlayerSprite,a1
				lea			Frames,a2
				move.l		Level+l_Map,a3
                
				moveq.l		#0,d0
				move.b		p_Dir(a0),d0
				lsl.b		#2,d0
				move.l		f_Skid(a2,d0),s_Data(a1)

				JOYTESTN	1,Player_Left,Player_Right,Player_Up,Player_Down,JoyDone

player_accn		equ			2
player_maxv		equ			8               ;must fit into scrolling
friction		equ			1

player_jumpv	equ			-11
gravity			equ			1
player_maxvy	equ			8

LeftEdge		equ			16		;pixels
RightEdge		equ			47

Player_Left:	move.b		#1,p_Dir(a0)

				tst.b		p_Jump(a0)
				bne.s		.Jumping
				
				moveq.l		#0,d0
				move.b		p_Frame(a0),d0
				addi.b		#1,d0
				andi.b		#$F,d0
				move.b		d0,p_Frame(a0)

				andi.b		#$0c,d0
				move.l		f_FramesR(a2,d0),s_Data(a1)

.Jumping		move.w		p_VelocityX(a0),d0
				subi.w		#player_accn,d0
				cmpi.w		#-player_maxv,d0
				bge			.SaveV
				move.w		#-player_maxv,d0
.SaveV			move.w		d0,p_VelocityX(a0)

				bra			UpDown1

Player_Right:	move.b		#0,p_Dir(a0)

				tst.b		p_Jump(a0)
				bne.s		.Jumping

				moveq.l		#0,d0
				move.b		p_Frame(a0),d0
				addi.b		#1,d0
				andi.b		#$F,d0
				move.b		d0,p_Frame(a0)
               
				andi.b		#$0c,d0
				move.l		f_FramesF(a2,d0),s_Data(a1)

.Jumping		move.w		p_VelocityX(a0),d0
				addi.w		#player_accn,d0
				cmpi.w		#player_maxv,d0
				ble.s		.SaveV
				move.w		#player_maxv,d0
.SaveV			move.w		d0,p_VelocityX(a0)

				bra			UpDown1

Player_Up:      tst.b		p_Jump(a0)
				bne			JoyDone

				move.b		#1,p_Jump(a0)
				move.w		#player_jumpv,p_VelocityY(a0)
				bra			JoyDone
Player_Down:
               ;addi.w      #1,p_Y(a0)

JoyDone:
Move_Player:	move.w		p_X(a0),d1
				move.w		p_Y(a0),d2

				move.w		p_VelocityX(a0),d0
				beq.s		.noVX
				tst.w		d0
				blt.s		.inc
				subq.w		#friction,d0
				bra.s		.MoveX
.inc			addq.w      #friction,d0
.MoveX			tst.w		d0
				beq			.noVX

				move.w		d2,d3
				lsr.w		#5,d3
				addq.w		#2,d3				;+ sprite height
				mulu.w		#l_width,d3			;offset into map

				moveq.l		#0,d4
				move.w		d0,d4
				blt.s		.TestLeft
				add.w		#RightEdge,d4		;test right for block
				move.w		#-RightEdge-1,d7
				bra.s		.there
.TestLeft		add.w		#LeftEdge,d4		;test left for block
				move.w		#31-LeftEdge+1,d7
.there			add.w		d1,d4
				move.w		d4,d6
				lsr.w		#5,d4
				add.l		d3,d4

				btst.b		#walk,(a3,d4.l)
				beq.s		.Save_MoveX

				andi.w		#$FFE0,d6
				add.w		d7,d6
				move.w		d6,d1
				
.noVX			move.w		#0,d0
				
				moveq.l		#0,d7
				move.b		p_Dir(a0),d7
				lsl.w		#2,d7
				move.l		f_Stand(a2,d7.w),s_Data(a1)

.Save_MoveX		add.w		d0,d1
				move.w		d1,p_X(a0)
				move.w		d0,p_VelocityX(a0)

.MoveY			move.w		#0,d3
				tst.b		p_Jump(a0)
				beq.s		.TestGround					;not jumping
				
				move.w		p_VelocityY(a0),d3			;do gravity
				addi.w		#gravity,d3
				cmpi.w		#player_maxvy,d3
				ble.s		.TestGround
				move.w		#player_maxvy,d3

.TestGround		move.w		d3,p_VelocityY(a0)

				tst.w		d3
				blt			.passthruL

				move.w		d2,d4
				lsr.w		#5,d4
				move.w		d2,d5
				add.w		d3,d5
				lsr.w		#5,d5
				
				cmp.w		d4,d5
				bne.s		.changeblocks

.lastblock		addq.w		#2,d4						;
				mulu.w		#l_width,d4

				moveq.l		#0,d5
				move.w		d1,d5
				move.l		d5,d6
				add.w		#LeftEdge,d5
				add.w		#RightEdge,d6
				lsr.w		#5,d5
				lsr.w		#5,d6
				cmp.w		d5,d6
				beq.s		.onefoot
				
				add.l		d4,d6
				move.b		(a3,d6.l),d7
				btst		#support,d7
				beq.s		.passthruR
				btst		#walk,d7
				bne			.NoFall_Block
				
				move.w		d2,d6
				add.w		d3,d6
				andi.w		#$001F,d6
				cmpi.w		#31-groundheight,d6
				bge.s		.NoFall_Ground

.passthruR
.onefoot
				add.l		d4,d5
				move.b		(a3,d5.l),d7
				btst		#support,d7
				beq.s		.passthruL
				btst		#walk,d7
				bne.s		.NoFall_Block
				
				move.w		d2,d5
				add.w		d3,d5
				andi.w		#$001F,d5
				cmpi.w		#31-groundheight,d5
				bge.s		.NoFall_Ground
				bra.s		.passthruL
				
.changeblocks	addq.w		#2,d4
				mulu.w		#l_width,d4
				
				moveq.l		#0,d6
				move.w		d1,d6
				move.l		d6,d7
				add.w		#LeftEdge,d6
				add.w		#RightEdge,d7
				lsr.w		#5,d6
				lsr.w		#5,d7
				add.l		d4,d6
				add.l		d4,d7
				
				tst.w		d3
				blt.s		.up
				
				btst.b		#support,(a3,d6.l)
				bne.s		.NoFall_Ground
				btst.b		#support,(a3,d7.l)
				bne.s		.NoFall_Ground

.up				add.w		d3,d2
				move.w		d5,d4
				move.w		#0,d3
				bra			.lastblock

.passthruL		add.w		d3,d2
				move.w		d2,p_Y(a0)
				move.b		#1,p_Jump(a0)
				rts

.NoFall_Ground	andi.w		#$FFE0,d2
				addi.w		#31-groundheight,d2
				move.w		d2,p_Y(a0)
				move.b		#0,p_Jump(a0)
				
				move.w		#$0FF,$dff180

				rts

.NoFall_Block	andi.w		#$FFE0,d2
				subq.w		#1,d2
				move.w		d2,p_Y(a0)
				move.b		#0,p_Jump(a0)

				move.w		#$F00,$dff180

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

      			move.w  #INTF_VERTB+INTF_COPER+INTF_BLIT,intena(a6)		;turn off first

				lea			VBlank,a0
				move.l		a0,$6C.w				;load new vector
				move.w		#$2000,SR				;turn all ints on

      			move.w		#INTF_SETCLR+INTF_INTEN+INTF_VERTB+INTF_COPER,intena(a6)
      			move.w		#INTF_VERTB+INTF_COPER,intreq(a6)
 
				movem.l		(sp)+,a0/d0/d1
				rts

*********************************************************************
*                                                                   *
*               Loads the Colours			                        *
*                                                                   *
*********************************************************************
LoadPalette:
               move.l      #custom+color+16*2,a0
               lea         spritepal,a1
               move.w      #16,d0
.lploop           move.w      (a1)+,(a0)+
               dbra.w      d0,.lploop

               move.l      #custom+color,a0
               lea         BackGroundPal,a1
               move.w      #16,d0
.lploop2		move.w		(a1)+,(a0)+
               dbra.w      d0,.lploop2

				move.w		#0,custom+color+20*2
				move.w		#$444,custom+color+21*2
				move.w		#0,custom+color+22*2
				move.w		#0,custom+color+23*2

				move.w		#0,custom+color+24*2
				move.w		#$444,custom+color+25*2
				move.w		#0,custom+color+26*2
				move.w		#0,custom+color+27*2

				move.w		#0,custom+color+28*2
				move.w		#$444,custom+color+29*2
				move.w		#0,custom+color+30*2
				move.w		#0,custom+color+31*2
                
               rts


*********************************************************************
*                                                                   *
*               Loads BG Sprites			                        *
*                                                                   *
*********************************************************************
LoadBGSprites:
			lea			BGSprites,a0
			
			move.w		#((bg_y&$FF)<<8),d0
			move.w		#(((bg_y+bg_height)&$FF)<<8)+((bg_y&$100)>>6)+((bg_y+bg_height)&$100)>>7),d1
			
			move.w		d0,d2
			move.b		#64,d2				;0+128/2
			move.w		d2,(a0)
			move.w		d1,8(a0)
			
			add.l		#bg_size,a0
			
			move.w		d0,d2
			move.b		#64+32,d2
			move.w		d2,(a0)
			move.w		d1,8(a0)

			add.l		#bg_size,a0
			
			move.w		d0,d2
			move.b		#64+32*2,d2
			move.w		d2,(a0)
			move.w		d1,8(a0)

			add.l		#bg_size,a0
			
			move.w		d0,d2
			move.b		#64+32*3,d2
			move.w		d2,(a0)
			move.w		d1,8(a0)

			add.l		#bg_size,a0
			
			move.w		d0,d2
			move.b		#64+32*4,d2
			move.w		d2,(a0)
			move.w		d1,8(a0)

			rts
