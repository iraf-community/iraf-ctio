# CAD.H -- Definitions for the CAD interface procedures. These definitions
# are provided to make the programs more readable, but they have no direct
# equivalence with DXF codes. These definitions start at 1000 to avoid any
# confusion with the DXF codes.


# Layer names

define	LAYER_DATA	"DATALAYER"	# data layer
define	LAYER_TEXT	"TEXTLAYER"	# text


# Section codes

define	SEC_HEADER	1000		# header section
define	SEC_TABLES	1001		# tables section
define	SEC_BLOCKS	1002		# blocks section
define	SEC_ENTITIES	1003		# entities section
