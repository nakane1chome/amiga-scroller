	include	"exec/types.i"

	STRUCTURE Sprite,0
		APTR	s_Data
		LONG	s_DataSize
		BYTE	s_FetchWidth		;2,4,8				-	fmode
		BYTE	s_SpriteWidth		;1,2,3,4,5,6,7,8	-	sprites used for width
		BYTE	s_AttachDepth		;0,1				-	attach bit
		BYTE	s_pad0
		WORD	s_Height
		LABEL	s_SIZEOF

