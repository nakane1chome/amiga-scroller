;
; Test joystick dirns !
; add "bra UpDown(Port)" after Left & Right Code.
;  

JOYTESTN	MACRO	Port (0|1), Left, Right, Up, Down, None
JoyTest\1:
		move.w		joy\1dat+custom,d0
		move.w		d0,d1
		lsr.w		#1,d1
		eor.w		d0,d1
		
		btst 		#1,d0
		bne			\3					;right
		
		btst		#9,d0
		bne			\2					;left 
UpDown\1:
		btst		#0,d1
		bne			\5					;down
		
		btst		#8,d1
		bne			\4					;up
		
		bra			\6
	ENDM
	
BUTTON1		MACRO
		move.b		$bfe001,d0
		andi.b		#$80,d0
			ENDM
