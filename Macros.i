
MULU4_B		MACRO
			lsl.b		#2,\1
			ENDM

MULU4_W		MACRO
			lsl.w		#2,\1
			ENDM

DIVU2_W		MACRO
			lsr.w		#1,\1
			ENDM

DIVS8_W		MACRO
			asr.w		#3,\1
			ENDM

DIVU8_W		MACRO
			lsr.w		#3,\1
			ENDM

CLR_L		MACRO
			moveq.l		#0,\1
			ENDM

CLR_W		MACRO
			moveq.l		#0,\1
			ENDM
	
