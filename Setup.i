
**
**		$Id: Setup.i 1.1 1998/05/18 07:31:32 phil Exp $
**		$Source: Work:Project/scroller/src/RCS/Setup.i $
**
**		Setup defaults for whole program
**

*********************************************************************
*
* Default includes
*
		incdir		"include:"
		include		"hardware/custom.i"
		include		"hardware/intbits.i"
		include		"hardware/dmabits.i"
		include		"LVOS.i"

*********************************************************************
*
* Default equates
*
custom			equ			$dff000

*********************************************************************
*
* Machine state
*
		STRUCTURE 		machine_state,0
			LONG		m_start
			LONG		m_GfxBase
			LONG		m_OldView
			LONG		m_VBR
			LABEL		cd_SIZEOF
