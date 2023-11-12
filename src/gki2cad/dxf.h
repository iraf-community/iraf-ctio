# DXF.H -- Definitions for autoCAD DXF file format. These definitions were
# taken from the Apendix C (Drawing Interchabge and File Formats) of the
# autoCAD manual. It is possible to define more, but this is good set for
# almost any program.

define	GRP_START	0		# start of an entity
define	GRP_PRIMARY	1		# primary text value
define	GRP_NAME	2		# name
define	GRP_OTHER1	3		# other textual value
define	GRP_OTHER2	4		# other textual value
define	GRP_HEX		5		# hexadecimal string
define	GRP_LINETYPE	6		# line type
define	GRP_TEXTSTYLE	7		# text style
define	GRP_LAYER	8		# layer name
define	GRP_VARIABLE	9		# variable name


# X coordinate group codes

define	GRP_XCOORD	10		# primary x coordinate
define	GRP_XOTHER1	11		# other x coordinate 1
define	GRP_XOTHER2	12		# other x coordinate 2
define	GRP_XOTHER3	13		# other x coordinate 3
define	GRP_XOTHER4	14		# other x coordinate 4
define	GRP_XOTHER5	15		# other x coordinate 5
define	GRP_XOTHER6	16		# other x coordinate 6
define	GRP_XOTHER7	17		# other x coordinate 7
define	GRP_XOTHER8	18		# other x coordinate 8


# Y coordinate group codes

define	GRP_YCOORD	20		# primary y coordinate
define	GRP_YOTHER1	11		# other y coordinate 1
define	GRP_YOTHER2	12		# other y coordinate 2
define	GRP_YOTHER3	13		# other y coordinate 3
define	GRP_YOTHER4	14		# other y coordinate 4
define	GRP_YOTHER5	15		# other y coordinate 5
define	GRP_YOTHER6	16		# other y coordinate 6
define	GRP_YOTHER7	17		# other y coordinate 7
define	GRP_YOTHER8	18		# other y coordinate 8


# Z coordinate group codes

define	GRP_ZCOORD	30		# primary z coordinate
define	GRP_ZOTHER1	11		# other z coordinate 1
define	GRP_ZOTHER2	12		# other z coordinate 2
define	GRP_ZOTHER3	13		# other z coordinate 3
define	GRP_ZOTHER4	14		# other z coordinate 4
define	GRP_ZOTHER5	15		# other z coordinate 5
define	GRP_ZOTHER6	16		# other z coordinate 6
define	GRP_ZOTHER7	17		# other z coordinate 7
define	GRP_ZOTHER8	18		# other z coordinate 8


# Integer value group codes

define	GRP_INT1	70		# integer value 1
define	GRP_INT2	71		# integer value 2
define	GRP_INT3	72		# integer value 3
define	GRP_INT4	73		# integer value 4
define	GRP_INT5	74		# integer value 5
define	GRP_INT6	75		# integer value 6
define	GRP_INT7	76		# integer value 7
define	GRP_INT8	77		# integer value 8
define	GRP_INT9	78		# integer value 9


# Floating point value codes

define	GRP_FLOAT1	40		# floating point value 1
define	GRP_FLOAT2	41		# floating point value 2
define	GRP_FLOAT3	42		# floating point value 3
define	GRP_FLOAT4	43		# floating point value 4
define	GRP_FLOAT5	44		# floating point value 5
define	GRP_FLOAT6	45		# floating point value 6
define	GRP_FLOAT7	46		# floating point value 7
define	GRP_FLOAT8	47		# floating point value 8
define	GRP_FLOAT9	48		# floating point value 9


# Angle group codes

define	GRP_ANGLE1	50		# angle 1
define	GRP_ANGLE2	51		# angle 2
define	GRP_ANGLE3	52		# angle 3
define	GRP_ANGLE4	53		# angle 4
define	GRP_ANGLE5	54		# angle 5
define	GRP_ANGLE6	55		# angle 6
define	GRP_ANGLE7	56		# angle 7
define	GRP_ANGLE8	57		# angle 8
define	GRP_ANGLE9	58		# angle 9


# Extrusion component group codes

define	GRP_XEXTR	210		# x component
define	GRP_YEXTR	220		# y component
define	GRP_ZEXTR	230		# z component


# Other group codes

define	GRP_ELEVATION	38		# entity's elevation
define	GRP_THICKNESS	39		# entity's thickness
define	GRP_REPEATED	49		# repeated value
define	GRP_COLOR	62		# color number
define	GRP_FOLLOW	66		# entities follow flag
define	GRP_COMMENT	999		# comment


# Section identifiers

define	SEC_SECTION_ID	"SECTION"	# start section
define	SEC_ENDSEC_ID	"ENDSEC"	# end section
define	SEC_HEADER_ID	"HEADER"	# header section
define	SEC_TABLES_ID	"TABLES"	# tables section
define	SEC_BLOCKS_ID	"BLOCKS"	# blocks section
define	SEC_ENTITIES_ID	"ENTITIES"	# entities section
define	SEC_EOF_ID	"EOF"		# end of file section


# Tables section identifiers

define	TBL_LTYPE_ID	"LTYPE"		# line type
define	TBL_LAYER_ID	"LAYER"		# layer
define	TBL_STYLE_ID	"STYLE"		# text style
define	TBL_VIEW_ID	"VIEW"		#
define	TBL_UCS_ID	"UCS"		# user coordinate system
define	TBL_VPORT_ID	"VPORT"		# viewport
define	TBL_DWGMGR_ID	"DWGMGR"	# future use
define	TBL_ENTAB_ID	"ENDTAB"	# end of table


# Text style generation flags

define	STY_BACKWARDS	2		# text is backwards
define	STY_UPDOWN	4		# text is upside down


# Block section identifiers

define	BLK_BLOCK_ID	"BLOCK"		# start of block
define	BLK_ENDBLK_ID	"ENDBLK"	# end of block


# Entities section identifiers

define	ENT_LINE_ID	"LINE"		# line
define	ENT_POINT_ID	"POINT"		# point
define	ENT_CIRCLE_ID	"CIRCLE"	# circle
define	ENT_ARC_ID	"ARC"		# arc
define	ENT_TRACE_ID	"TRACE"		# trace
define	ENT_SOLID_ID	"SOLID"		# solid
define	ENT_TEXT_ID	"TEXT"		# text
define	ENT_SHAPE_ID	"SHAPE"		# shape
define	ENT_INSERT_ID	"INSERT"	# ?
define	ENT_ATTDEF_ID	"ATTDEF"	# attribute definition
define	ENT_ATTRIB_ID	"ATTRIB"	# attribute
define	ENT_POLYLINE_ID	"POLYLINE"	# polyline
define	ENT_VERTEX_ID	"VERTEX"	# polyline vertex
define	ENT_SEQEND_ID	"SEQEND"	# end of sequence
define	ENT_3DLINE_ID	"3DLINE"	# 3-dimensional line
define	ENT_3DFACE_ID	"3DFACE"	# 3-dimensional face
define	ENT_DIMENSION_ID "DIMENSION"	# dimension


# Polyline codes

define	POL_VERTFLAG	1		# vertices flag value
define	POL_CLOSED	1		# close polygon
define	POL_CURVEFIT	2		# curve-fit vertices added
define	POL_SPLINE	4		# spline-fit vertices added
define	POL_3D		8		# 3-dimension polyline
define	POL_3DMESH	16		# 3-dimensional mesh
define	POL_CLSEDMESH	32		# mesh closed


# Polyline mesh codes

define	POL_MESH_NOSM	0		# no smooth surface fitted
define	POL_MESH_QUAD	5		# quadratic B-spline surface
define	POL_MESH_CUBIC	6		# cubic B-spline surface
define	POL_MESH_BEZIER	8		# Bezier surface
