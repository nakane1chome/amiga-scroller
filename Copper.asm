sprfetch		equ				3
sprword			equ				64
bplfetch		equ				0
bplword			equ				16
d_fmode         equ             (sprfetch*$0004)+(bplfetch*$0001)

 
;
;       screen defines
;
fetchx				equ			320

pf1_bufferx			equ			fetchx+32*2
pf1_buffery			equ			256+2
pf1_depth			equ			4
pf1_int				equ			1

pf2_bufferx			equ			fetchx+16
pf2_buffery			equ			256+32*2
pf2_depth			equ			4
pf2_int				equ			1

planes				equ			8

pf1_planebuffer		equ			pf1_bufferx*pf1_buffery/8
pf1_buffer			equ			pf1_bufferx*pf1_buffery*pf1_depth/8

pf2_planebuffer		equ			pf2_bufferx*pf2_buffery/8
pf2_buffer			equ			pf2_bufferx*pf2_buffery*pf2_depth/8

mod1				equ			(pf1_bufferx-fetchx)/8+pf1_int*(pf1_bufferx*(pf1_depth-1))/8 ;interleaved
mod2				equ			(pf2_bufferx-fetchx)/8+pf2_int*(pf2_bufferx*(pf2_depth-1))/8

;
;Display Window
;

screenx				equ			fetchx-16
screeny				equ			256

xwstart				equ			128+8
xwstop				equ			(xwstart+screenx)&$FF-16
ywstart				equ			35
ywstop				equ			(ywstart+screeny)&$FF


;
;	pixels/2 - 1 word (before display) ?? (+ - 1 word for scroll range)
;

d_ddfstrt			equ			$0034
d_pfscroll			equ			7
d_ddfstop			equ			d_ddfstrt+(8*((fetchx/16)-1))

;
;Display Control
;

hires				equ			0
shres				equ			0
dpf					equ			1
ham					equ			0
lace				equ			0			;might work

killehb				equ			1
pf2pri				equ			1			;pf2 pri over pf1
pf1p				equ			1			;sprite-playfield priority
pf2p				equ			1			;0-7

brdsprt				equ			0
brdblnk				equ			1
sprtres				equ			1			;lowres=1,hires=2,shres=3
pf2off				equ			4			;2^n

esoff				equ			15			;even & odd sprite colour table offsets
osoff				equ			14

d_bplcon0			equ			(hires*$8000)+((planes&7)*$1000)+((planes>>3)*$0010)+(ham*$0800)+(dpf*$0400)+(shres*$0040)+(lace*$0004)+1
d_bplcon1			equ			0
d_bplcon2			equ			(killehb*$0200)+(pf2pri*$0040)+((pf2p&7)*$0008)+((pf1p&7)*$0001)
d_bplcon3			equ			(brdsprt*$0002)+(brdblnk*$0020)+((sprtres&$3)*$0040)+((pf2off&$7)*$0400)
d_bplcon4			equ			((esoff&$F)*$0010)+((osoff&$F)*$0001)


		  SECTION   Copper_Code,CODE

*********************************************************************
*                                                                   *
*               Load copper register                                *
*                                                                   *
*********************************************************************

LoadCopper:	movem.l		a0/a5,-(SP)

			move.l		#custom,a5

			move.w		#xwstart+$100*ywstart,diwstrt(a5)
			move.w		#xwstop+$100*ywstop,diwstop(a5) 
			move.w		#d_ddfstop,ddfstop(a5) 
			move.w		#d_ddfstrt,ddfstrt(a5) 

			move.w		#d_fmode,fmode(a5)

			move.w		#d_bplcon3,bplcon3(a5)

			jsr			MakeRainbow
			lea			Copper_Rainbow,a0
			move.l		a0,cop2lc(a5)

			lea			Copper_Main,a0
			move.l		a0,cop1lc(a5)
			move.w		#0,copjmp1(a5)
			move.w		#DMAF_SETCLR+DMAF_COPPER,dmacon(a5)
					 
			movem.l		(SP)+,a0/a5
			rts

rainbow_init		equ		$000
rainbow_fin			equ		$77E
rainbow_lines		equ		255			;<256

r_step				equ		16
g_step				equ		16
b_step				equ		16

msb:		ds.b		3
			even

MakeRainbow:
			moveq.l		#$0,d0								;red lsb
			moveq.l		#$0,d1								;green lsb
			moveq.l		#$0,d2								;blue lsb

			move.l		#(rainbow_fin&$F00)<<0,d3
			sub.l		#(rainbow_init&$F00)<<0,d3
			divs.w		#rainbow_lines,d3

			move.l		#(rainbow_fin&$0F0)<<4,d4
			sub.l		#(rainbow_init&$0F0)<<4,d4
			divs.w		#rainbow_lines,d4

			move.l		#(rainbow_fin&$00F)<<8,d5
			sub.l		#(rainbow_init&$00F)<<8,d5
			divs.w		#rainbow_lines,d5

			lea			msb,a1
			move.b		#(rainbow_init&$F00)>>4,0(a1)
			move.b		#(rainbow_init&$0F0)>>0,1(a1)
			move.b		#(rainbow_init&$00F)<<4,2(a1)

			lea			Copper_Rainbow,a0
			move.w		#0,d7

			move.w		#color,(a0)+
			move.w		#rainbow_init,(a0)+			;start colour
			move.w		#bplcon3,(a0)+
			move.w		#d_bplcon3+$0200,(a0)+		;set lsb

.loop		moveq.l		#0,d6
			move.b		d7,d6
			add.b		#ywstart,d6
			bcs.s		.half
			bra.s		.dowait
.half		;move.l		#$ffdffffe,(a0)+
.dowait		lsl.w		#8,d6
			move.b		#$07,d6
			move.w		d6,(a0)+
			move.w		#$FFFE,(a0)+				;wait

			moveq.l		#0,d6
.r			add.b		d3,d0
			bcs.s		.rr
			bra.s		.g
.rr			add.b		#r_step,0(a1)
			move.b		#1,d6
.g			add.b		d4,d1
			bcs.s		.gg
			bra.s		.b
.gg			add.b		#g_step,1(a1)
			move.b		#1,d6
.b			add.b		d5,d2
			bcs.s		.bb
			bra.s		.tstmsb
.bb			add.b		#b_step,2(a1)
			move.b		#1,d6

.tstmsb		tst.b		d6
			beq.s		.lsb

.msb		move.w		#bplcon3,(a0)+
			move.w		#d_bplcon3,(a0)+		;select msb

			move.b		0(a1),d6
			lsl.w		#4,d6
			move.b		1(a1),d6
			lsl.w		#4,d6
			move.b		2(a1),d6
			lsr.w		#4,d6
			move.w		#color,(a0)+
			move.w		d6,(a0)+

			move.w		#bplcon3,(a0)+
			move.w		#d_bplcon3+$0200,(a0)+	;select	lsb

.lsb		move.b		d0,d6
			lsl.w		#4,d6
			move.b		d1,d6
			lsl.w		#4,d6
			move.b		d2,d6
			lsr.w		#4,d6
			move.w		#color,(a0)+
			move.w		d6,(a0)+
			
			addq.w		#1,d7
			cmpi.w		#rainbow_lines,d7
			blt			.loop
			
			move.w		#bplcon3,(a0)+
			move.w		#d_bplcon3,(a0)+		;select msb
			move.w		#color,(a0)+
			move.w		#$00F,(a0)+
			move.l		#$FFFFFFFE,(a0)+
			move.l		#$FFFFFFFE,(a0)+
			
			rts
			
		SECTION		Screen_Data,DATA_F

		STRUCTURE	Playfield,0
			LONG	pf_Base
			LONG	pf_NextPlane
			LONG	pf_ByteOffset
			LONG	pf_ByteOffsetY
			WORD	pf_ByteWidth
			LONG	pf_LineHeight
			
BackGround:
		dc.l		0
		dc.l		pf1_bufferx/8
		dc.l		0
		dc.l		0
		dc.w		pf1_bufferx/8
		dc.l		pf1_buffery
		

ForeGround1:
		dc.l		0
		dc.l		pf2_bufferx/8
		dc.l		2
		dc.l		0
		dc.w		pf2_bufferx/8
		dc.l		pf2_buffery

ForeGround2:
		dc.l		0
		dc.l		pf2_bufferx/8
		dc.l		2
		dc.l		0
		dc.w		pf2_bufferx/8
		dc.l		pf2_buffery

		  SECTION Copper_List,DATA_C
 
Copper_Main:
			dc.w		color,$FFF
			dc.w		dmacon,DMAF_RASTER

bplcon:		dc.w		bplcon0,d_bplcon0
			dc.w		bplcon1,d_bplcon1
			dc.w		bplcon2,d_bplcon2
			dc.w		bplcon3,d_bplcon3
			dc.w		bplcon4,d_bplcon4
					 
			dc.w		bpl1mod,mod1
			dc.w		bpl2mod,mod2
					 
			dc.w		dmacon,DMAF_SETCLR+DMAF_RASTER

			dc.w		copjmp2,0
			dc.w		$aaa9,$fffe
;			dc.w		intreq,INTF_SETCLR+INTF_COPER


Copper_Tail:
			dc.w		$ffdf,$fffe
			
			dc.w		bplcon0,1
			dc.w		color,$00F

			dc.w		$ffff,$fffe
			dc.w		$ffff,$fffe             

			even
			
Copper_Rainbow:
			ds.l	((rainbow_lines+1)*2+32+1)*3

