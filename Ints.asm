		SECTION Interupt_BSS,BSS_F
		
VBlank_Set:			ds.b		1
rawkey:				ds.b		1

		SECTION Interupt_Code,CODE_F

*********************************************************************
*                                                                   *
*               Loads Interupt Vector                               *
*                 a0.l - Code                                       *
*                 d0.w - Interupt Level                             *
*                 d1.w - Int req/ena Mask                           *
*                                                                   *
*                                                                   *
*********************************************************************
		  
LoadVector:
					movem.l     d2/a1/a6,-(sp)
					move.l      #custom,a6

					andi.w      #~INTF_SETCLR,d1
					move.w      d1,intena(a6)           ;Disable Interupts
					move.w      #$2700,SR

					move.l      #$60,a1
					moveq.l		#0,d2
					move.w      d0,d2
					lsl.w       #2,d2
					adda.l      d2,a1
					move.l      a0,(a1)                 ;Load Vector

					move.w      #$2000,SR               ;CPU Ints on

					move.w      d1,intreq(a6)
					ori.w       #INTF_SETCLR,d1         ;Set setclr bit
					move.w      d1,intena(a6)           ;Enable Int

					movem.l     (sp)+,d2/a1/a6
					rts

*********************************************************************
*                                                                   *
*               Interupt handler for Kbd                            *
*                                                                   *
*********************************************************************

KB:			movem.l		d0-d7/a0-a6,-(sp)

			move.l		#custom,a6
			move.l		#$bfe000,a5

			move.w		#INTF_PORTS,intreq(a6)

			move.b		$c01(a5),d0			;scan code
			not.b		d0
			ror.b		d0					;rawkey code
			cmpi.b		#$FF,d0
			beq.s		.NoKey				;not keypress
			move.b		d0,rawkey

.NoKey		move.b		#0,$c01(a5)
			ori.b		#$40,$e01(a5)		;send 0 to keyboard

			move.b		$d01(a5),d1			;turn irq off
			ori.b		#$80,d1				;set/clr bit
			move.b		d1,$d01(a5)			;reset interupts

			move.w		#INTF_PORTS,intreq(a6)
			move.b		#0,$e01(a5)			;keyboard sp input

			movem.l		(sp)+,d0-d7/a0-a6
			rte

*********************************************************************
*                                                                   *
*               Waits For Vertical Blank                            *
*                                                                   *
*********************************************************************

WaitVB:		move.l		d0,-(sp)
.waitloop	move.b		VBlank_Set,d0
			beq.s		.waitloop
			move.b		#0,VBlank_Set

			move.l		(sp)+,d0
			rts

*********************************************************************
*                                                                   *
*               Interupt handler for VBlank                         *
*                                                                   *
*********************************************************************

VBlank:		movem.l     d0-d7/a0-a6,-(sp)
			move.l      #custom,a6

			move.w		intreqr(a6),d0
			
			move.w      #INTF_VERTB+INTF_COPER+INTF_BLIT,intreq(a6)
			
			btst		#INTB_VERTB,d0
			bne.s		.vblank
			btst		#INTB_BLIT,d0
			bne			.end
			btst		#INTB_COPER,d0
			bne			.copper
			bra			.end

.vblank		move.b		#1,VBlank_Set

			move.w		#DMAF_SPRITE+DMAF_RASTER,dmacon(a6)

			lea			PlayerSprite,a0
			moveq.l		#0,d0
			bsr			LoadSprite

			lea			BGSprites,a0			;Load the other spritept regs
			move.l		a0,d0					;with ptr to null sprite
			move.l		#custom+sprpt,a0

			move.l		d0,2*4(a0)
			add.l		#bg_size,d0
			move.l		d0,3*4(a0)
			add.l		#bg_size,d0
			move.l		d0,4*4(a0)
			add.l		#bg_size,d0
			move.l		d0,5*4(a0)
			add.l		#bg_size,d0
			move.l		d0,6*4(a0)
			add.l		#bg_size,d0
			move.l		d0,7*4(a0)

			move.l		Player_Data+p_BackGround,a0
			move.l		pf_ByteOffset(a0),d0
			add.l		pf_ByteOffsetY(a0),d0
			bsr			LoadBGBP
			bsr			LoadFGBP
			
			move.w      #DMAF_SETCLR+DMAF_RASTER+DMAF_SPRITE,dmacon(a6)

.end		movem.l     (sp)+,d0-d7/a0-a6
			rte

.copper
			move.l		Player_Data+p_BackGround,a0
			move.l		pf_ByteOffset(a0),d0
			bsr			LoadBGBP

			bra			.end
			
*********************************************************************
*                                                                   *
*       Loads the sprpt directly at VBlank                          *
*       a0=sprite, d0.l=sprite num 0-7                              *
*                                                                   *
*********************************************************************

LoadSprite:	movem.l		d1-d2/a1,-(sp)

			move.l		#custom+sprpt,a1
			add.l		d0,d0
			add.l		d0,d0
			adda.l		d0,a1

			move.b		s_SpriteWidth(a0),d0
			tst.b		s_AttachDepth(a0)
			beq.s		.ls0
			add.b		d0,d0

.ls0		move.l		s_DataSize(a0),d1
			move.l		s_Data(a0),d2
		  
.ls1		move.l		d2,(a1)+
			add.l		d1,d2
					 
			subi.b		#1,d0
			bne.s		.ls1

			movem.l		(sp)+,d1-d2/a1
			rts

*********************************************************************
*																	*
*		Load Bitplanes															*
*																	*
*********************************************************************
*
*d0 = offset	a0=Background
*
LoadBGBP:
*			move.l		Player_Data+p_BackGround,a0
			move.l		pf_Base(a0),a1
*			add.l		pf_ByteOffset(a0),a1
			add.l		d0,a1
			move.l		pf_NextPlane(a0),d0

			move.l		a1,bplpt+$00(a6)		;even planes
			add.l		d0,a1
			move.l		a1,bplpt+$08(a6)
			add.l		d0,a1
			move.l		a1,bplpt+$10(a6)
			add.l		d0,a1
			move.l		a1,bplpt+$18(a6)

			rts

LoadFGBP:
			move.l		Player_Data+p_ForeGround,a0
			move.l		pf_Base(a0),a1
			add.l		pf_ByteOffset(a0),a1
			move.l		pf_NextPlane(a0),d0

			move.l		a1,bplpt+$04(a6)		;odd planes
			add.l		d0,a1
			move.l		a1,bplpt+$0c(a6)
			add.l		d0,a1
			move.l		a1,bplpt+$14(a6)
			add.l		d0,a1
			move.l		a1,bplpt+$1c(a6)

			rts

