	SECTION  Sprite_Code,CODE

*********************************************************************
*                                                                   *
*               Moves Sprites                                       *
*                 d0.w = x,                                         *
*                 d1.w = y,                                         *
*                 a6.l = sprite.                                    *
*                                                                   *
*********************************************************************

x			equr		d0
y			equr		d1
sprite		equr		a6

MoveSprite:                             
			movem.l		d2-d5/a1,-(SP)
			
			addi.w		#xwstart,x
			addi.w		#ywstart,y

			move.b		#0,d4			;d4=temp for msb VSTART/VSTOP lsb HSTART

			move.w		y,d2			;d2=sprpos
			lsl.w		#8,d2			;VSTART
			roxl.b		d4				;msb of VSTART

			move.w		y,d3			;d3=sprctl
			add.w		s_Height(sprite),d3
			lsl.w		#8,d3			;VSTOP
			roxl.b		d4				;msb of VSTOP

			lsr.w		d0
			roxl.b		d4				;lsl of HSTART
			move.b		d0,d2			;HSTART

			move.b		d4,d3
			move.b		s_AttachDepth(sprite),d4
			beq.s		.SavePos
			ori.b		#$80,d3			;attach bit

.SavePos	move.l		s_Data(sprite),a1
			moveq.l		#0,d0
			move.b		s_FetchWidth(sprite),d0
			move.b		d0,d5
			lsl.b		#2,d5           ;d5=sprite width/2

			moveq.l		#0,d1
			move.b		s_SpriteWidth(sprite),d1
			move.l		s_DataSize(sprite),d6

			move.w		#DMAF_SPRITE,custom+dmacon

.Plane1		move.w		d2,(a1)
			move.w		d3,(a1,d0.w)

			add.l		d6,a1

			tst.b		d4
			beq.s		.NextSprite

.Plane3		move.w		d2,(a1)
			move.w		d3,(a1,d0.w)

			add.l		d6,a1

.NextSprite	add.b		d5,d2

			subi.b		#1,d1
			bne.s		.Plane1

			move.w		#DMAF_SETCLR+DMAF_SPRITE,custom+dmacon

			movem.l		(SP)+,d2-d5/a1
			rts

