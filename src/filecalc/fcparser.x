
include	<ctype.h>
include	<lexnum.h>
include	"lexer.h"
include	"parser.h"

# Parser stack and structure lengths
define	YYMAXDEPTH	128
define	YYOPLEN		LEN_LEX

# Redefine the name of the parser
define	yyparse		fc_parser

define	F_ACOS		257
define	F_ASIN		258
define	F_ATAN		259
define	F_ATAN2		260
define	F_COS		261
define	F_SIN		262
define	F_TAN		263
define	F_EXP		264
define	F_LOG		265
define	F_LOG10		266
define	F_SQRT		267
define	F_ABS		268
define	F_INT		269
define	F_MAX		270
define	F_MIN		271
define	F_AVG		272
define	F_MEDIAN		273
define	F_MODE		274
define	F_SIGMA		275
define	F_STR		276
define	COLUMN		277
define	FILE		278
define	INUMBER		279
define	RNUMBER		280
define	DNUMBER		281
define	STRING		282
define	PLUS		283
define	MINUS		284
define	STAR		285
define	SLASH		286
define	EXPON		287
define	CONCAT		288
define	LPAR		289
define	RPAR		290
define	COMMA		291
define	SEMICOLON		292
define	EOLINE		293
define	UPLUS		294
define	UMINUS		295
define	yyclearin	yychar = -1
define	yyerrok		yyerrflag = 0
define	YYMOVE		call amovi (Memi[$1], Memi[$2], YYOPLEN)
define	YYERRCODE	256

# line 241 "fcparser.y"

define	YYNPROD		48
define	YYLAST		134
# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

# Parser for yacc output, translated to the IRAF SPP language.  The contents
# of this file form the bulk of the source of the parser produced by Yacc.
# Yacc recognizes several macros in the yaccpar input source and replaces
# them as follows:
#	A	user suppled "global" definitions and declarations
# 	B	parser tables
# 	C	user supplied actions (reductions)
# The remainder of the yaccpar code is not changed.

define	yystack_	10		# statement labels for gotos
define	yynewstate_	20
define	yydefault_	30
define	yyerrlab_	40
define	yyabort_	50

define	YYFLAG		(-1000)		# defs used in user actions
define	YYERROR		goto yyerrlab_
define	YYACCEPT	return (OK)
define	YYABORT		return (ERR)


# YYPARSE -- Parse the input stream, returning OK if the source is
# syntactically acceptable (i.e., if compilation is successful),
# otherwise ERR.  The parameters YYMAXDEPTH and YYOPLEN must be
# supplied by the caller in the %{ ... %} section of the Yacc source.
# The token value stack is a dynamically allocated array of operand
# structures, with the length and makeup of the operand structure being
# application dependent.

int procedure yyparse (fd, yydebug, yylex)

int	fd			# stream to be parsed
bool	yydebug			# print debugging information?
int	yylex()			# user-supplied lexical input function
extern	yylex()

short	yys[YYMAXDEPTH]		# parser stack -- stacks tokens
pointer	yyv			# pointer to token value stack
pointer	yyval			# value returned by action
pointer	yylval			# value of token
int	yyps			# token stack pointer
pointer	yypv			# value stack pointer
int	yychar			# current input token number
int	yyerrflag		# error recovery flag
int	yynerrs			# number of errors

short	yyj, yym		# internal variables
pointer	yysp, yypvt
short	yystate, yyn
int	yyxi, i
errchk	salloc, yylex



int	nargs			# number of arguments in function call

short	yyexca[6]
data	(yyexca(i),i=  1,  6)	/  -1,   1,   0,  -1,  -2,   0/
short	yyact[134]
data	(yyact(i),i=  1,  8)	/  19,  20,  21,  22,  23,  24,  25,  26/
data	(yyact(i),i=  9, 16)	/  27,  28,  29,  30,  31,  33,  32,  34/
data	(yyact(i),i= 17, 24)	/  35,  36,  37,  38,  18,   7,  14,  15/
data	(yyact(i),i= 25, 32)	/  16,  17,  10,  11,   8,  65,  48,  44/
data	(yyact(i),i= 33, 40)	/  13,  40,  41,  42,  43,  44,  45,  64/
data	(yyact(i),i= 41, 48)	/  50,  66,  40,  41,  42,  43,  44,  45/
data	(yyact(i),i= 49, 56)	/  60,  59,  40,  41,  42,  43,  44,  45/
data	(yyact(i),i= 57, 64)	/  40,  41,  42,  43,  44,  42,  43,  44/
data	(yyact(i),i= 65, 72)	/   3,   6,  61,  62,   2,  57,  12,   5/
data	(yyact(i),i= 73, 80)	/   4,   9,   1,   0,   0,  39,  46,  47/
data	(yyact(i),i= 81, 88)	/   0,  49,   0,   0,   0,   0,   0,   0/
data	(yyact(i),i= 89, 96)	/   0,   0,   0,   0,   0,   0,   0,   0/
data	(yyact(i),i= 97,104)	/   0,   0,   0,   0,   0,   0,   0,   0/
data	(yyact(i),i=105,112)	/   0,   0,   0,   0,  51,  52,  53,  54/
data	(yyact(i),i=113,120)	/  55,  56,  58,   0,   0,   0,   0,   0/
data	(yyact(i),i=121,128)	/   0,   0,   0,  63,   0,   0,   0,   0/
data	(yyact(i),i=129,134)	/   0,   0,   0,   0,  63,  67/
short	yypact[68]
data	(yypact(i),i=  1,  8)	/-192,-1000,-272,-1000,-264,-257,-1000,-1000/
data	(yypact(i),i=  9, 16)	/-1000,-233,-257,-257,-259,-257,-1000,-1000/
data	(yypact(i),i= 17, 24)	/-1000,-1000,-239,-1000,-1000,-1000,-1000,-1000/
data	(yypact(i),i= 25, 32)	/-1000,-1000,-1000,-1000,-1000,-1000,-1000,-1000/
data	(yypact(i),i= 33, 40)	/-1000,-1000,-1000,-1000,-1000,-1000,-1000,-1000/
data	(yypact(i),i= 41, 48)	/-257,-257,-257,-257,-257,-257,-1000,-1000/
data	(yypact(i),i= 49, 56)	/-1000,-241,-230,-224,-224,-256,-256,-1000/
data	(yypact(i),i= 57, 64)	/-227,-257,-1000,-1000,-240,-261,-250,-1000/
data	(yypact(i),i= 65, 68)	/-1000,-1000,-257,-1000/
short	yypgo[10]
data	(yypgo(i),i=  1,  8)	/   0,  74,  68,  72,  71,  67,  65,  70/
data	(yypgo(i),i=  9, 10)	/  69,  66/
short	yyr1[48]
data	(yyr1(i),i=  1,  8)	/   0,   1,   1,   2,   2,   3,   4,   5/
data	(yyr1(i),i=  9, 16)	/   5,   5,   5,   5,   5,   5,   5,   5/
data	(yyr1(i),i= 17, 24)	/   5,   5,   5,   5,   5,   5,   5,   8/
data	(yyr1(i),i= 25, 32)	/   9,   9,   9,   7,   7,   7,   7,   7/
data	(yyr1(i),i= 33, 40)	/   7,   7,   7,   7,   7,   7,   7,   7/
data	(yyr1(i),i= 41, 48)	/   7,   7,   7,   7,   7,   7,   7,   6/
short	yyr2[48]
data	(yyr2(i),i=  1,  8)	/   0,   2,   1,   1,   3,   2,   1,   3/
data	(yyr2(i),i=  9, 16)	/   3,   3,   3,   3,   3,   2,   2,   5/
data	(yyr2(i),i= 17, 24)	/   3,   1,   1,   1,   1,   2,   4,   1/
data	(yyr2(i),i= 25, 32)	/   1,   3,   1,   1,   1,   1,   1,   1/
data	(yyr2(i),i= 33, 40)	/   1,   1,   1,   1,   1,   1,   1,   1/
data	(yyr2(i),i= 41, 48)	/   1,   1,   1,   1,   1,   1,   1,   0/
short	yychk[68]
data	(yychk(i),i=  1,  8)	/-1000,  -1,  -2, 256,  -3,  -4,  -6, 293/
data	(yychk(i),i=  9, 16)	/ 292,  -5, 283, 284,  -7, 289, 279, 280/
data	(yychk(i),i= 17, 24)	/ 281, 282, 277, 257, 258, 259, 260, 261/
data	(yychk(i),i= 25, 32)	/ 262, 263, 264, 265, 266, 267, 268, 269/
data	(yychk(i),i= 33, 40)	/ 271, 270, 272, 273, 274, 275, 276,  -2/
data	(yychk(i),i= 41, 48)	/ 283, 284, 285, 286, 287, 288,  -5,  -5/
data	(yychk(i),i= 49, 56)	/ 289,  -5, 279,  -5,  -5,  -5,  -5,  -5/
data	(yychk(i),i= 57, 64)	/  -5,  -8,  -6, 290, 278,  -9,  -5,  -6/
data	(yychk(i),i= 65, 68)	/ 279, 290, 291,  -9/
short	yydef[68]
data	(yydef(i),i=  1,  8)	/  47,  -2,   0,   2,   3,   0,   6,   1/
data	(yydef(i),i=  9, 16)	/  47,   5,   0,   0,   0,   0,  17,  18/
data	(yydef(i),i= 17, 24)	/  19,  20,   0,  27,  28,  29,  30,  31/
data	(yydef(i),i= 25, 32)	/  32,  33,  34,  35,  36,  37,  38,  39/
data	(yydef(i),i= 33, 40)	/  40,  41,  42,  43,  44,  45,  46,   4/
data	(yydef(i),i= 41, 48)	/   0,   0,   0,   0,   0,   0,  13,  14/
data	(yydef(i),i= 49, 56)	/  47,   0,  21,   7,   8,   9,  10,  11/
data	(yydef(i),i= 57, 64)	/  12,  47,  23,  16,   0,   0,  24,  26/
data	(yydef(i),i= 65, 68)	/  22,  15,  47,  25/

begin
	call smark (yysp)
	call salloc (yyv, (YYMAXDEPTH+2) * YYOPLEN, TY_STRUCT)

	# Initialization.  The first element of the dynamically allocated
	# token value stack (yyv) is used for yyval, the second for yylval,
	# and the actual stack starts with the third element.

	yystate = 0
	yychar = -1
	yynerrs = 0
	yyerrflag = 0
	yyps = 0
	yyval = yyv
	yylval = yyv + YYOPLEN
	yypv = yylval

yystack_
	# SHIFT -- Put a state and value onto the stack.  The token and
	# value stacks are logically the same stack, implemented as two
	# separate arrays.

	if (yydebug) {
	    call printf ("state %d, char 0%o\n")
		call pargs (yystate)
		call pargi (yychar)
	}
	yyps = yyps + 1
	yypv = yypv + YYOPLEN
	if (yyps > YYMAXDEPTH) {
	    call sfree (yysp)
	    call eprintf ("yacc stack overflow\n")
	    return (ERR)
	}
	yys[yyps] = yystate
	YYMOVE (yyval, yypv)

yynewstate_
	# Process the new state.
	yyn = yypact[yystate+1]

	if (yyn <= YYFLAG)
	    goto yydefault_			# simple state

	# The variable "yychar" is the lookahead token.
	if (yychar < 0) {
	    yychar = yylex (fd, yylval)
	    if (yychar < 0)
		yychar = 0
	}
	yyn = yyn + yychar
	if (yyn < 0 || yyn >= YYLAST)
	    goto yydefault_

	yyn = yyact[yyn+1]
	if (yychk[yyn+1] == yychar) {		# valid shift
	    yychar = -1
	    YYMOVE (yylval, yyval)
	    yystate = yyn
	    if (yyerrflag > 0)
		yyerrflag = yyerrflag - 1
	    goto yystack_
	}

yydefault_
	# Default state action.

	yyn = yydef[yystate+1]
	if (yyn == -2) {
	    if (yychar < 0) {
		yychar = yylex (fd, yylval)
		if (yychar < 0)
		    yychar = 0
	    }

	    # Look through exception table.
	    yyxi = 1
	    while ((yyexca[yyxi] != (-1)) || (yyexca[yyxi+1] != yystate))
		yyxi = yyxi + 2
	    for (yyxi=yyxi+2;  yyexca[yyxi] >= 0;  yyxi=yyxi+2) {
		if (yyexca[yyxi] == yychar)
		    break
	    }

	    yyn = yyexca[yyxi+1]
	    if (yyn < 0) {
		call sfree (yysp)
		return (OK)			# ACCEPT -- all done
	    }
	}


	# SYNTAX ERROR -- resume parsing if possible.

	if (yyn == 0) {
	    switch (yyerrflag) {
	    case 0, 1, 2:
		if (yyerrflag == 0) {		# brand new error
		    call eprintf ("syntax error\n")
yyerrlab_
		    yynerrs = yynerrs + 1
		    # fall through...
		}

	    # case 1:
	    # case 2: incompletely recovered error ... try again
		yyerrflag = 3

		# Find a state where "error" is a legal shift action.
		while (yyps >= 1) {
		    yyn = yypact[yys[yyps]+1] + YYERRCODE
		    if ((yyn >= 0) && (yyn < YYLAST) &&
			(yychk[yyact[yyn+1]+1] == YYERRCODE)) {
			    # Simulate a shift of "error".
			    yystate = yyact[yyn+1]
			    goto yystack_
		    }
		    yyn = yypact[yys[yyps]+1]

		    # The current yyps has no shift on "error", pop stack.
		    if (yydebug) {
			call printf ("error recovery pops state %d, ")
			    call pargs (yys[yyps])
			call printf ("uncovers %d\n")
			    call pargs (yys[yyps-1])
		    }
		    yyps = yyps - 1
		    yypv = yypv - YYOPLEN
		}

		# ABORT -- There is no state on the stack with an error shift.
yyabort_
		call sfree (yysp)
		return (ERR)


	    case 3: # No shift yet; clobber input char.

		if (yydebug) {
		    call printf ("error recovery discards char %d\n")
			call pargi (yychar)
		}

		if (yychar == 0)
		    goto yyabort_		# don't discard EOF, quit
		yychar = -1
		goto yynewstate_		# try again in the same state
	    }
	}


	# REDUCE -- Reduction by production yyn.

	if (yydebug) {
	    call printf ("reduce %d\n")
		call pargs (yyn)
	}
	yyps  = yyps - yyr2[yyn+1]
	yypvt = yypv
	yypv  = yypv - yyr2[yyn+1] * YYOPLEN
	YYMOVE (yypv + YYOPLEN, yyval)
	yym   = yyn

	# Consult goto table to find next state.
	yyn = yyr1[yyn+1]
	yyj = yypgo[yyn+1] + yys[yyps] + 1
	if (yyj >= YYLAST)
	    yystate = yyact[yypgo[yyn+1]+1]
	else {
	    yystate = yyact[yyj+1]
	    if (yychk[yystate+1] != -yyn)
		yystate = yyact[yypgo[yyn+1]+1]
	}

	# Perform action associated with the grammar rule, if any.
	switch (yym) {
	    
case 1:
# line 45 "fcparser.y"
{
		    return (OK)
		}
case 2:
# line 48 "fcparser.y"
{
		    call fc_error ("Cannot continue parsing", PERR_SYNTAX)
		    return (ERR)
		}
case 3:
# line 54 "fcparser.y"
{
#		    YYMOVE ($1, $$)
		}
case 4:
# line 57 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		}
case 5:
# line 63 "fcparser.y"
{
#		    YYMOVE ($2, $$)
		    call fc_cend (yyval)
		}
case 6:
# line 69 "fcparser.y"
{
		    call fc_cinit ()
		}
case 7:
# line 74 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (PLUS, "", INDEFI, INDEFR, INDEFD)
		}
case 8:
# line 79 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (MINUS, "", INDEFI, INDEFR, INDEFD)
		}
case 9:
# line 84 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (STAR, "", INDEFI, INDEFR, INDEFD)
		}
case 10:
# line 89 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (SLASH, "", INDEFI, INDEFR, INDEFD)
		}
case 11:
# line 94 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (EXPON, "", INDEFI, INDEFR, INDEFD)
		}
case 12:
# line 99 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (CONCAT, "", INDEFI, INDEFR, INDEFD)
		}
case 13:
# line 104 "fcparser.y"
{
#		    call fc_cat2 (LEX_ID ($1), LEX_ID ($2),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (UPLUS, "", INDEFI, INDEFR, INDEFD)
		}
case 14:
# line 109 "fcparser.y"
{
#		    call fc_cat2 (LEX_ID ($1), LEX_ID ($2),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (UMINUS, "", INDEFI, INDEFR, INDEFD)
		}
case 15:
# line 114 "fcparser.y"
{
#		    call fc_cat4 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($4),
#				  LEX_ID ($5), LEX_ID ($$), LEN_ID)
		    call fc_cgen (LEX_TOK (yypvt-4*YYOPLEN), "", nargs, INDEFR, INDEFD)
		}
case 16:
# line 119 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		}
case 17:
# line 123 "fcparser.y"
{
#		    YYMOVE ($1, $$)
		    call fc_cgen (INUMBER, "", LEX_IVAL (yypvt), INDEFR, INDEFD)
		}
case 18:
# line 127 "fcparser.y"
{
#		    YYMOVE ($1, $$)
		    call fc_cgen (RNUMBER, "", INDEFI, LEX_RVAL (yypvt), INDEFD)
		}
case 19:
# line 131 "fcparser.y"
{
#		    YYMOVE ($1, $$)
		    call fc_cgen (DNUMBER, "", INDEFI, INDEFR, LEX_DVAL (yypvt))
		}
case 20:
# line 135 "fcparser.y"
{
#		    YYMOVE ($1, $$)
		    call fc_cgen (STRING, LEX_ID (yypvt), INDEFI, INDEFR, INDEFD)
		}
case 21:
# line 139 "fcparser.y"
{
#		    call fc_cat2 (LEX_ID ($1), LEX_ID ($2),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (COLUMN, "1", LEX_IVAL (yypvt), INDEFR, INDEFD)
		}
case 22:
# line 144 "fcparser.y"
{
#		    call fc_cat4 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($4), LEX_ID ($$), LEN_ID)
		    call fc_cgen (COLUMN, LEX_ID (yypvt), LEX_IVAL (yypvt-2*YYOPLEN),
				  INDEFR, INDEFD)
		}
case 23:
# line 152 "fcparser.y"
{
		    nargs = 0
		}
case 24:
# line 157 "fcparser.y"
{
#		    YYMOVE ($1, $$)
		    nargs = nargs + 1
		}
case 25:
# line 161 "fcparser.y"
{
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    nargs = nargs + 1
		}
case 27:
# line 169 "fcparser.y"
{
	    	    YYMOVE (yypvt, yyval)
		}
case 28:
# line 172 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 29:
# line 175 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 30:
# line 178 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 31:
# line 182 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 32:
# line 185 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 33:
# line 188 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 34:
# line 192 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 35:
# line 195 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 36:
# line 198 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 37:
# line 201 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 38:
# line 205 "fcparser.y"
{
	    	    YYMOVE (yypvt, yyval)
		}
case 39:
# line 208 "fcparser.y"
{
	    	    YYMOVE (yypvt, yyval)
		}
case 40:
# line 212 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 41:
# line 215 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 42:
# line 219 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 43:
# line 222 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 44:
# line 225 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 45:
# line 228 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}
case 46:
# line 232 "fcparser.y"
{
		    YYMOVE (yypvt, yyval)
		}	}

	goto yystack_				# stack new state and value
end
