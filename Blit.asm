		Include		"hardware/blit.i"

A_TO_D			equ		ABC+ANBC+ABNC+ANBNC
A_OR_NB_AND_C	equ		ABC+ANBNC+ANBC+ABNC+NANBC

		STRUCTURE	Blit_Sprite,0
			LONG	bs_Data
			WORD	bs_PrevX
			WORD	bs_PrevY
			WORD	bs_PrevClip
			LABEL	bs_SIZEOF

		STRUCTURE	Blit_Data,0
			LONG	bd_Data
			LONG	bd_Mask
			WORD	bd_ByteWidth
			WORD	bd_Height
			WORD	bd_bltsize
			LONG	bd_SIZEOF

blit_dest_height		equ		pf2_buffery
blit_dest_bytewidth		equ		pf2_bufferx/8-2

*****************************************************************
*																*
*			Blitter Resource									*
*																*
*****************************************************************
*
*
*Struct:
*		- Address of Blitter Draw stack
*			- address current
*			- address buffers
*			- size (no blits)
*			- to be drawn
*			- current frame
*			- can only be swapped when br_stack_draw = 0
*
		STRUCTURE	blitter_resource,0
			APTR	br_stack_base_current		Base to add new blits to
			APTR	br_stack_base0
			APTR	br_stack_base1
			WORD	br_stack_size				Size of stack
			WORD	br_stack_count				Count of new blits
			APTR	br_stack_draw				Address for next draw
			APTR	br_stack_new				Address of last new blit
			LABEL	br_SIZEOF

*****************************************************************
*																*
*			Blitter Pipeline									*
*																*
*****************************************************************
*
*

*****************************************************************
*
*Name:	Blitter_Interrupt
*
*Function:
*		Executes next Blitter operation on stack
*Assumed:
*		a0 = Program Base
*Method:
*		- gets stack control struct
*		- check not/done all in stack
*		- gets next blit reg struct
*		- loads blitter
*		- updates next blit/set done all if req
*
*Structs:
*		blitter registers
*		- copies of data for registers (long)
*		- address of next struct (addr)
*
		STRUCTURE	blitter_registers,0
			LONG	bb_bltcon				H=bltcon0 L=bltcon1
			LONG	bb_bltawm				H=bltafwm L=bltalwm
			LONG	bb_bltcpt
			LONG	bb_bltbpt
			LONG	bb_bltapt
			LONG	bb_bltdpt
			LONG	bb_bltcbmod				H=bltcmod L=bltbmod
			LONG	bb_bltadmod				H=bltamod L=bltdmod
			WORD	bb_bltsize				Starts Blit
			APTR	bb_next
			LABEL	bb_SIZEOF

Blitter_Interrupt:
* a0 = Program Base
* a1 = Blitter resourse
* a2 = Blit
* a6 = custom base
*		
		move.l		p_BlitRes(a0),a1

		move.l		br_stack_draw(a1),a2
		beq			.stack_done

		move.l		#custom,a6
		move.l		(a2)+,bltcon0(a6)				H=bltcon0 L=bltcon1
		move.l		(a2)+,bltafwm(a6)				H=bltafwm L=bltalwm
		move.l		(a2)+,bltcpt(a6)
		move.l		(a2)+,bltbpt(a6)
		move.l		(a2)+,bltapt(a6)
		move.l		(a2)+,bltdpt(a6)
		move.l		(a2)+,bltcmod(a6)				H=bltcmod L=bltbmod
		move.l		(a2)+,bltamod(a6)				H=bltamod L=bltdmod
		move.w		(a2)+,bltsize(a6)				Starts Blit

		move.l		(a2),br_stack_draw(a1)
				
*The queue has been completed/return
.stack_done
		rts
*****************************************************************
*
*Name		Get_SBlit
*
*Function
*			returns address of mem for sblit
*Method
*			-gets blitter resource
*			-compare count
*			-link blits
*			-add bb_sizeof to current addr
*
*Parameters
*			return a1 = addr | fail
Get_SBlit:
* a1 = blitter res
			move.l		p_BlitRes(a0),a1

			move.w		br_stack_size(a1),d7
			sub.w		br_stack_count(a1),d7
			blt			.dont_return

			move.l		br_stack_new(a1),a2
			beq			.top_stack
			move.l		a2,a1
			adda.l		#bb_SIZEOF,a1

.next		move.l		a2,bb_next(a1)
			rts

*top of the stack
.top_stack	move.l		br_stack_base_current(a1),a1
			bra			.next
*no more blits
.dont_return
			move.l		#0,a1
			rts

*****************************************************************
*
*Name		Push_SBlit
*
*Function
*			update blit resource with new blit
*Method
*			-get blit res
*			-inc count
*			-update address
*Parametrs
*			a1 = blit
Push_SBlit:
* a2 = blitter res
			move.l		p_BlitRes(a0),a2

			addi.w		#1,br_stack_count(a2)

			move.l		a1,br_stack_new(a2)

			rts

*****************************************************************
*
*Name		SBlit_Paste
*
*Function
*			Adds a blitter paste to the blitter stack
*Method
*			-Gets next stack pos
*			-calcs blit
*			-puts on stack
*Assumed
*			-depth = 4
*Parameters
*			d0.w = x
*			d1.w = y
*			a6 = playfield
*			a5 = object
SBlit_Paste:
			bsr			Get_SBlit

			move.w		pf_ByteWidth(a6),d2
			move.l		d2,d3
			mulu.w		d1,d3
			lsl.l		#2,d3				d3 = line addr

			CLR_L		d4
			move.w		d0,d4
			lsr.w		#3,d4				d4 = row addr
			
			add.l		d4,d3
			add.l		pf_Base(a6),d3
			move.l		d3,bltdpt(a1)		d3 = dest addr

			sub.w		bd_ByteWidth(a5),d2
			move.w		d2,bltdmod(a1)

			move.b		d0,d2
			ror.w		#4,d2
			andi.w		#$F000,d2
			ori.w		#A_TO_D+SRCA+DEST,d2
			move.w		d2,bltcon0(a1)
			move.w		#0,bltcon1(a1)

			move.l		bd_Data(a5),bltapt(a1)
			
			move.w		bd_bltsize(a5),bltsize(a1)

			bra			Push_SBlit
			

*****************************************************************
*																*
*			Init Blitter Regs to Assumed Values					*
*																*
*****************************************************************
InitBlitter:
			move.l		#custom,a6

			move.w		#$FFFF,bltafwm(a6)
			move.w		#$FFFF,bltalwm(a6)

			move.w		#0,bltcon1(a6)
			move.w		#0,bltamod(a6)
			move.w		#0,bltbmod(a6)


			rts

*****************************************************************
*																*
*			Move All Active Bobs								*
*																*
*****************************************************************

clipleft	equ			0
cliptop		equ			1
clipright	equ			2
clipbottom	equ			3

DoBobs:		move.l		#custom,a6
			move.l		p_ForeGround(a0),a5

			jsr			Clear_Bullets

			move.l		p_Enemies(a0),a1
			move.l		p_Bobs(a0),a2

			move.l		bs_Data(a2),a4
			move.w		bs_PrevX(a2),d0
			move.w		bs_PrevY(a2),d1
			move.w		bs_PrevClip(a2),d7

			bne			.clearclip
			jsr			CPUClear_NoClip
			bra			.draw
.clearclip	;jsr			CPUClear_Clip
.draw	
			move.b		#0,d7					;register for clip mask

			move.w		en_X(a1),d0				;clip left ?
			bge.s		.no_clipleft
			ori.b		#1<<clipleft,d7
.no_clipleft
			move.w		d0,d2					;clip right ?
			asr.w		#3,d2
			add.w		bd_ByteWidth(a4),d2
			cmpi.w		#blit_dest_bytewidth,d2
			ble.s		.no_clipright
			ori.b		#1<<clipright,d7
.no_clipright
			move.w		en_Y(a1),d1				;clip top ?
			bge.s		.no_cliptop
			ori.b		#1<<cliptop,d7
.no_cliptop
			move.w		d1,d2					;clip bottom ?
			add.w		bd_Height(a4),d2
			cmpi.w		#blit_dest_height,d2
			blt.s		.no_clipbottom
			ori.b		#1<<clipbottom,d7
.no_clipbottom

			move.w		d0,bs_PrevX(a2)
			move.w		d1,bs_PrevY(a2)
			move.w		d7,bs_PrevClip(a2)
			
			beq.s		.noclip
			bsr			BlitPaste_MaskClip
			bra.s		.next
.noclip		bsr			BlitPaste_Mask			
			
.next		
			jsr			Draw_Bullets
		
			rts

*****************************************************************
*																*
*			Draw Bullets										*
*																*
*****************************************************************

Clear_Bullets:
			move.l		p_BulletsC(a0),a2
			
			move.b		#No_Bullets,d7
.loop01		move.l		bs_Data(a2),a4
			move.w		bs_PrevX(a2),d0
			move.w		bs_PrevY(a2),d1

			jsr			CPUClear_NoClip
			lea			bs_SIZEOF(a2),a2
			subi.b		#1,d7
			bne.s		.loop01

			rts
		
Draw_Bullets:
			move.l		p_BulletsC(a0),a2
			move.l		p_Bullets(a0),a1
			move.l		p_Level(a0),a3
			move.b		#No_Bullets,d7
.loop02		move.l		bs_Data(a2),a4
			move.w		bt_X(a1),d0
			move.w		d0,bs_PrevX(a2)
			move.w		bt_Y(a1),d1
			move.w		d1,bs_PrevY(a2)

			jsr			BlitWait
			jsr			BlitPaste_Mask
			lea			bs_SIZEOF(a2),a2
			lea			bt_SIZEOF(a1),a1
			subi.b		#1,d7
			bne.s		.loop02
			
			rts

Fast_ScreenClr:
			movem.l	d0-d7/a0-a1,-(sp)
			
			move.l	pf_Base(a5),a0
			move.w	pf_ByteWidth(a5),d0
			move.l	pf_LineHeight(a5),d1

			lsl.w	#2,d1
			mulu.w	d1,d0
			move.l	a0,a1
			add.l	d0,a1

			add.l	#8*4,a0

			moveq.l	#0,d0
			moveq.l	#0,d1
			moveq.l	#0,d2
			moveq.l	#0,d3
			moveq.l	#0,d4
			moveq.l	#0,d5
			moveq.l	#0,d6
			moveq.l	#0,d7
			
.loop		movem.l	d0-d7,-(a1)
			cmp.l	a0,a1
			bgt		.loop

			movem.l	d0-d7,-(a0)

			movem.l	(sp)+,d0-d7/a0-a1
			rts			
			

;d0.w	- x
;d1.w	- y
;a4		- obj
;a5		= pf

CPUClear_Clip:
			rts


;d0.w	- x
;d1.w	- y
;a4		- obj
;a5		= pf

CPUClear_NoClip:	
			CLR_L		d2
			move.w		pf_ByteWidth(a5),d2
			move.l		d2,d3
			mulu.w		d1,d3
			lsl.l		#2,d3			;depth=4 (intleaved mode)
			CLR_L		d4
			move.w		d0,d4
			lsr.w		#3,d4
			add.l		d4,d3
			add.l		pf_Base(a5),d3
			move.l		d3,a3
			
			CLR_L		d3
			move.w		bd_ByteWidth(a4),d3
			andi.b		#$FC,d3
			sub.l		d3,d2
			subq.l		#4,d2
			lsr.w		#2,d3
				
			move.l		#$0,d5
			move.w		bd_Height(a4),d6
			MULU4_W		d6

.vert		move.w		d3,d4
.line		move.l		d5,(a3)+
			dbra.w		d4,.line
			add.l		d2,a3
			dbra.w		d6,.vert
			
			rts

;assumes top&bot or left&right not both clipped
;d0.w 	- x
;d1.w 	- y
;d7.b	- clipbits
;a4 	- src
;a5 	- pf

BlitPaste_MaskClip:

			CLR_L		d2						d2	source offset
			CLR_L		d3						d3	dest offset

			move.w		#0,bltamod(a6)
			move.w		#0,bltbmod(a6)

			move.w		bd_Height(a4),d4		d4.w height
			move.w		bd_ByteWidth(a4),d5
			DIVU2_W		d5						d5 word width

			btst		#cliptop,d7
			beq.s		.no_cliptop

;Clip Top

			move.w		d1,d2					d2 = y
			neg.w		d2						d2 = -y
			MULU4_W		d2						depth = 4
			mulu.w		bd_ByteWidth(a4),d2		d2.l y byte offset into source

			move.w		d1,d4					d4 = y
			add.w		bd_Height(a4),d4		d4 = Clipped Height
			ble			.allclipped

			bra.s		.edges

.no_cliptop
			move.w		d1,d3					d3 = y
			MULU4_W		d3						depth = 4
			mulu.w		pf_ByteWidth(a5),d3		d3.l y byte offset into dest

			btst		#clipbottom,d7
			beq.s		.edges

;Clip Bottom

			move.w		d1,d4					d4=y
			subi.w		#blit_dest_height,d4	d4=-height
			neg.w		d4						d4=height
			ble			.allclipped

;Clip Edges

.edges		btst		#clipleft,d7
			beq.s		.no_clipleft

;Clip Left

			CLR_L		d5
			move.w		bd_ByteWidth(a4),d5
			move.w		d0,d6					d5=x
			DIVS8_W		d6
			bclr		#0,d6
			add.w		d6,d5					d5.w bytewidth source
			ble			.allclipped

			neg.w		d6
			move.w		d6,bltamod(a6)			set source a mod
			move.w		d6,bltbmod(a6)			set source b mod (mask)
			add.l		d6,d2					d2.l source byteoffset

			DIVU2_W		d5						d5.w wordwidth source

			bra			.loadblitter

.no_clipleft
			CLR_L		d6
			move.w		d0,d6
			DIVU8_W		d6
			bclr		#0,d6
			add.l		d6,d3

			btst		#clipright,d7
			beq			.loadblitter

			sub.w		#blit_dest_bytewidth,d6
			bge			.allclipped

			neg.w		d6						d6.w = source bytewidth
			addq.w		#2,d6

			move.w		bd_ByteWidth(a4),d5
			sub.w		d6,d5

			move.w		d5,bltamod(a6)			;set source a mod
			move.w		d5,bltbmod(a6)			;set source b mod (mask)

			move.w		d6,d5
			DIVU2_W		d5						;d5.w source wordwidth

.loadblitter
			move.l		bd_Data(a4),d6
			add.l		d2,d6
			move.l		d6,bltapt(a6)			;a source (object)
			add.l		bd_Mask(a4),d2
			move.l		d2,bltbpt(a6)			;b source (mask)

			add.l		pf_Base(a5),d3
			move.l		d3,bltcpt(a6)			;c source (background)
			move.l		d3,bltdpt(a6)			;dest

			move.w		pf_ByteWidth(a5),d6
			sub.w		d5,d6
			sub.w		d5,d6
			move.w		d6,bltcmod(a6)			;c mod
			move.w		d6,bltdmod(a6)			;dest mod

			move.b		d0,d6
			andi.w		#$000F,d6				;A & B shift
			move.w		#$FFFF,d3
			lsl.w		d6,d3
			move.w		d3,bltalwm(a6)
			move.w		#$FFFF,bltafwm(a6)

			ror.w		#4,d6
			move.w		d6,bltcon1(a6)
			ori.w		#A_OR_NB_AND_C+SRCA+SRCB+SRCC+DEST,d6
			move.w		d6,bltcon0(a6)

			ror.w		#16-6-2,d4				(height*4)<<6
			and.b		#$C0,d4
			and.b		#$3F,d5
			or.b		d5,d4
			move.w		d4,bltsize(a6)			size & start blit

.allclipped
			rts


;d0.w 	- x
;d1.w 	- y
;a4 	- src
;a5 	- pf

BlitPaste_Mask:
			move.w		pf_ByteWidth(a5),d2

			move.w		#0,bltamod(a6)
			move.w		#0,bltbmod(a6)
			move.w		#$FFFF,bltafwm(a6)
			move.w		#$FFFF,bltalwm(a6)

			move.w		d2,d3
			mulu.w		d1,d3
			lsl.l		#2,d3				;depth=4 (intleaved mode)
			CLR_L		d4
			move.w		d0,d4
			DIVU8_W		d4
			add.l		d4,d3
			add.l		pf_Base(a5),d3
			move.l		d3,bltdpt(a6)		;dest d
			move.l		d3,bltcpt(a6)		;src c

			sub.w		bd_ByteWidth(a4),d2
			move.w		d2,bltdmod(a6)		;d mod
			move.w		d2,bltcmod(a6)		;c mod

			move.b		d0,d2
			ror.w		#4,d2
			andi.w		#$F000,d2
			move.w		d2,bltcon1(a6)
			ori.w		#A_OR_NB_AND_C+SRCA+SRCB+SRCC+DEST,d2
			move.w		d2,bltcon0(a6)

			move.l		bd_Data(a4),bltapt(a6)
			move.l		bd_Mask(a4),bltbpt(a6)
			
			move.w		bd_bltsize(a4),bltsize(a6)

			rts

BlitPaste_NoMask:
			move.l		#custom,a6

			CLR_L		d2
			move.l		pf_ByteWidth(a5),d2

			move.l		d2,d3
			mulu.w		d1,d3
			lsl.l		#2,d3			;depth=4 (intleaved mode)
			CLR_L		d4
			move.w		d0,d4
			lsr.w		#3,d4
			add.l		d4,d3
			add.l		pf_Base(a5),d3
			move.l		d3,bltdpt(a6)

			sub.w		bd_ByteWidth(a4),d2
			move.w		d2,bltdmod(a6)

			move.b		d0,d2
			ror.w		#4,d2
			andi.w		#$F000,d2
			ori.w		#A_TO_D+SRCA+DEST,d2
			move.w		d2,bltcon0(a6)
			move.w		#0,bltcon1(a6)

			move.l		bd_Data(a4),bltapt(a6)
			
			move.w		bd_bltsize(a4),bltsize(a6)

			rts

BlitWait:
			move.w		d0,-(SP)
			move.l		#custom,a6
			
.busy		move.w		dmaconr(a6),d0
			andi.w		#$4000,d0
			bne.s		.busy
			
			move.w		(SP)+,d0
			rts

