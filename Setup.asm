*********************************************************************************
*																				*
*	Setup.asm																	*
*																				*
*********************************************************************************

		incdir		"include:"
		include		"hardware/custom.i"
		include		"hardware/intbits.i"
		include		"hardware/dmabits.i"
		include		"LVOS.i"

custom			equ			$dff000

	SECTION		Setup,CODE_F

Setup:
		move.l   $4.w,a6

	;
	;Open gfxlib
	;
		lea      GfxName,a1
		moveq.l  #0,d0
		jsr      _LVOOpenLibrary(a6)
		beq      .error0
		move.l   d0,GfxBase

		jsr      NoOS

	;
	;Close gfxlib
	;
		move.l   $4.w,a6
		move.l   GfxBase,a1
		jsr      _LVOCloseLibrary(a6)
.error0
		rts      

*******************************************************************

NoOS:
		move.l   $4.w,a6

		jsr      _LVOForbid(a6)
		jsr      _LVODisable(a6)

	;
	;save screen
	;
		move.l   GfxBase,a6
		move.l   34(a6),OldView

		move.l   #0,a1
		jsr      _LVOLoadView(a6)
		jsr      _LVOWaitTOF(a6)
		jsr      _LVOWaitTOF(a6)

	;
	;run in supervisor mode
	;
		move.l   $4.w,a6
		lea      Super(pc),a5
		jsr      _LVOSupervisor(a6)

	;
	;restore screen
	;
		move.l   GfxBase,a6
		move.l   OldView,a1
		jsr      _LVOLoadView(a6)
		move.l   38(a6),custom+cop1lc

		move.l   $4.w,a6

		jsr      _LVOEnable(a6)
		jsr      _LVOPermit(a6)

		rts

*********************************************************************************
*																				*
*	Supervisor Mode																*
*																				*
*********************************************************************************
Super:
		lea			CPU_Data,a6
		movec		VBR,a0
		move.l		a0,cd_VBR(a6)
		bra			Save_IVT
s01:	jsr			_main
		bra			Restore_IVT
s02:	rte

*********************************************************************************
*																				*
*	Save IVT to Stack															*
*																				*
*********************************************************************************

Save_IVT:
		move.l		#custom,a5
		move.l		CPU_Data,a6

	;
	;save inten & dmacon
	;
		move.w		intenar(a5),-(SP)
		ori.w		#$C000,(SP)
		move.w		dmaconr(a5),-(SP)
		ori.w		#$8200,(SP)

	;
	;turn off interupts & dma
	;
		move.w		#$7fff,d0
		move.w		d0,intena(a5)
		move.w		d0,dmacon(a5)

	;
	;save interupt vector table
	;
		move.l		cd_VBR(a6),a0
		moveq		#$100/4-1,d0
.svt	move.l		(a0)+,-(SP)
		dbra		d0,.svt

		bra			s01

*********************************************************************************
*																				*
*	Restore IVT from Stack														*
*																				*
*********************************************************************************

Restore_IVT:
		move.l		#custom,a5
		move.l		CPU_Data,a6

	;
	;turn off interupts & dma
	;
		move.w		#$7FFF,d0
		move.w		d0,intena(a5)
		move.w		d0,dmacon(a5)

	;
	;restore interupt vector table
	;
		move.l		cd_VBR(a6),a0	
		lea			$100(a0),a0
		moveq		#$100/4-1,d0
.rvt	move.l		(SP)+,-(a0)
		dbra		d0,.rvt

	;
	;restore intena & dmacon
	;
		move.w		(SP)+,dmacon(a5)
		move.w		(SP)+,intena(a5)

		bra			s02

*********************************************************************************
*																				*
*	Data																		*
*																				*
*********************************************************************************

	SECTION		Setup_BSS,BSS_F

	STRUCTURE CPU_DATA,0
		LONG		cd_VBR
		LABEL		cd_SIZEOF

CPU_Data:
		ds.b     cd_SIZEOF
		
GfxBase:	ds.l  1
OldView:	ds.l  1

	SECTION		Setup_Data,DATA_F

GfxName:	dc.b  "graphics.library",0
		
