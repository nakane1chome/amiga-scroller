
*
*	Fetch Modes
*
sprfetch		equ				0
sprword			equ				16
bplfetch		equ				0
bplword			equ				16

*
*	Screen Size & Buffer
*
fetchx				equ			640

pf1_bufferx			equ			fetchx
pf1_buffery			equ			256
pf1_depth			equ			1
pf1_int				equ			1

pf2_bufferx			equ			0
pf2_buffery			equ			0
pf2_depth			equ			0
pf2_int				equ			0

planes				equ			1

pf1_planebuffer		equ			pf1_bufferx*pf1_buffery/8
pf1_buffer			equ			pf1_bufferx*pf1_buffery*pf1_depth/8

pf2_planebuffer		equ			pf2_bufferx*pf2_buffery/8
pf2_buffer			equ			pf2_bufferx*pf2_buffery*pf2_depth/8

*
*	Display Window
*
screenx				equ			fetchx
screeny				equ			256


d_pfscroll			equ			7

*
*Display Control
*
hires				equ			1
shres				equ			0
dpf					equ			0
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

d_bpl1mod			equ			(pf1_bufferx-fetchx)/8+pf1_int*(pf1_bufferx*(pf1_depth-1))/8 ;interleaved
d_bpl2mod			equ			(pf2_bufferx-fetchx)/8+pf2_int*(pf2_bufferx*(pf2_depth-1))/8

xwstart				equ			128+8
xwstop				equ			(xwstart+screenx/(1+hires))&$FF-16
ywstart				equ			35
ywstop				equ			(ywstart+screeny)&$FF

d_diwstrt			equ			xwstart+$100*ywstart
d_diwstop			equ			xwstop+$100*ywstop
*	pixels/2 - 1 word (before display) ?? (+ - 1 word for scroll range)
d_ddfstrt			equ			$0034+4*hires
d_ddfstop			equ			d_ddfstrt+(8*((fetchx/16)-1))*(1-hires)+(4*((fetchx/16)-2))*hires

d_fmode         equ             (sprfetch*$0004)+(bplfetch*$0001)

	STRUCT	VMODE,0
		WORD	vm_HResolution
		WORD	vm_bplcon0
		WORD	vm_bplcon1
		WORD	vm_bplcon2
		WORD	vm_bplcon3
		WORD	vm_bplcon4
		WORD	vm_fmode
		LABEL	vm_SIZEOF
		
H_320		equ			0
H_640		equ			1
h_1280		equ			2
		
