
**
**		$Id: Setup.asm 1.1 1998/05/18 07:30:07 phil Exp $
**		$Source: Work:Project/scroller/src/RCS/Setup.asm $
**
**		Setup program for execution
**

		Include 	"Setup.i"
		Include		"setup.dat"
		
		SECTION	Code,CODE
		
		even

*********************************************************************
*
* Initialise with multitasking
*
Setup:
* Setup
		move.l		$4.w,a6
		lea			machine,a5

* Open Graphics library
		lea			GfxName,a1
		moveq.l		#0,d0
		jsr			_LVOOpenLibrary(a6)
		beq			.error0
		move.l		d0,m_GfxBase(a5)

* Remove OS
		lea			_main,a0
		move.l		a0,m_start(a5)
		jsr			NoOS

* Setup
		move.l		$4.w,a6
		lea			machine,a5

* Close Graphics library
		move.l		m_GfxBase(a5),a1
		jsr			_LVOCloseLibrary(a6)

* error in opening GFX Library
.error0
		rts      

*******************************************************************
*
*Name		NoOS
*
*Function
*			Run at an addr with no OS in supervisor mode
*
*Parameters
*			m_start(machine_state)

NoOS:
* Setup
		move.l		$4.w,a6
		lea			machine,a5

* Disable Multitasking
		jsr			_LVOForbid(a6)
		jsr			_LVODisable(a6)

* Remove OS display and save
		move.l		m_GfxBase(a5),a6
		move.l		34(a6),m_OldView(a5)

* Set OS display to NULL
		move.l		#0,a1
		jsr			_LVOLoadView(a6)
		jsr			_LVOWaitTOF(a6)
		jsr			_LVOWaitTOF(a6)


* Switch to supervisor mode
		move.l		$4.w,a6
		lea			.super(pc),a5
		jsr			_LVOSupervisor(a6)

* Resore OS Display
		lea			machine,a5
		move.l		m_GfxBase(a5),a6
		move.l		m_OldView(a5),a1
		jsr			_LVOLoadView(a6)
		move.l		38(a6),custom+cop1lc

		move.l		$4.w,a6

		jsr			_LVOEnable(a6)
		jsr			_LVOPermit(a6)

		rts

*******************************************************************
*
* Section to run in supervisor mode
*
.super
		lea			machine,a5
		movec		VBR,a1
		move.l		a1,m_VBR(a5)
		bra			.save_IVT
.s01	lea			machine,a5
		jsr			_main
		bra			.restore_IVT
.s02	rte

*******************************************************************
*
* Save IVT to the stack
*
.save_IVT
		move.l		#custom,a5
		lea			machine,a6

* save inten & dmacon
		move.w		intenar(a5),-(SP)
		ori.w		#$C000,(SP)
		move.w		dmaconr(a5),-(SP)
		ori.w		#$8200,(SP)

* turn off interupts & dma
		move.w		#$7fff,d0
		move.w		d0,intena(a5)
		move.w		d0,dmacon(a5)

* save interupt vector table
		move.l		m_VBR(a6),a1
		moveq		#$100/4-1,d0
.svt	move.l		(a1)+,-(SP)
		dbra		d0,.svt

		bra			.s01

*******************************************************************
*
* Restore IVT from Stack
*
.restore_IVT
		move.l		#custom,a5
		lea			machine,a6

* turn off interupts & dma
		move.w		#$7FFF,d0
		move.w		d0,intena(a5)
		move.w		d0,dmacon(a5)

* restore interupt vector table
		move.l		m_VBR(a6),a0	
		lea			$100(a0),a0
		moveq		#$100/4-1,d0
.rvt	move.l		(SP)+,-(a0)
		dbra		d0,.rvt

* restore intena & dmacon
		move.w		(SP)+,dmacon(a5)
		move.w		(SP)+,intena(a5)

		bra			.s02
