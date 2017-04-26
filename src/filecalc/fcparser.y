%{

include	<ctype.h>
include	<lexnum.h>
include	"lexer.h"
include	"parser.h"

# Parser stack and structure lengths
define	YYMAXDEPTH	128
define	YYOPLEN		LEN_LEX

# Redefine the name of the parser
define	yyparse		fc_parser

%L

int	nargs			# number of arguments in function call

%}

%token	F_ACOS F_ASIN F_ATAN, F_ATAN2
%token	F_COS F_SIN F_TAN
%token	F_EXP F_LOG F_LOG10 F_SQRT
%token	F_ABS F_INT
%token	F_MAX F_MIN
%token	F_AVG F_MEDIAN F_MODE F_SIGMA
%token	F_STR

%token	COLUMN FILE
%token	INUMBER RNUMBER DNUMBER STRING
%token	PLUS MINUS STAR SLASH EXPON CONCAT
%token	LPAR RPAR
%token	COMMA SEMICOLON
%token	EOLINE

%left	CONCAT
%left	PLUS MINUS
%left	STAR SLASH
%left	EXPON
%right	UPLUS UMINUS


%%

expressions	: stmtlist EOLINE {
		    return (OK)
		}
		| error {
		    call fc_error ("Cannot continue parsing", PERR_SYNTAX)
		    return (ERR)
		}
		;

stmtlist	: stmt {
#		    YYMOVE ($1, $$)
		}
		| stmt SEMICOLON stmtlist {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		}
		;

stmt		: exprinit expr {
#		    YYMOVE ($2, $$)
		    call fc_cend ($$)
		}
		;

exprinit	: empty {
		    call fc_cinit ()
		}
		;

expr		: expr PLUS expr {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (PLUS, "", INDEFI, INDEFR, INDEFD)
		}
		| expr MINUS expr {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (MINUS, "", INDEFI, INDEFR, INDEFD)
		}
		| expr STAR expr {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (STAR, "", INDEFI, INDEFR, INDEFD)
		}
		| expr SLASH expr {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (SLASH, "", INDEFI, INDEFR, INDEFD)
		}
		| expr EXPON expr {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (EXPON, "", INDEFI, INDEFR, INDEFD)
		}
		| expr CONCAT expr {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (CONCAT, "", INDEFI, INDEFR, INDEFD)
		}
		| PLUS expr %prec UMINUS {
#		    call fc_cat2 (LEX_ID ($1), LEX_ID ($2),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (UPLUS, "", INDEFI, INDEFR, INDEFD)
		}
		| MINUS expr %prec UMINUS {
#		    call fc_cat2 (LEX_ID ($1), LEX_ID ($2),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (UMINUS, "", INDEFI, INDEFR, INDEFD)
		}
		| funct LPAR arginit arglist RPAR {
#		    call fc_cat4 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($4),
#				  LEX_ID ($5), LEX_ID ($$), LEN_ID)
		    call fc_cgen (LEX_TOK ($1), "", nargs, INDEFR, INDEFD)
		}
		| LPAR expr RPAR {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		}
		| INUMBER {
#		    YYMOVE ($1, $$)
		    call fc_cgen (INUMBER, "", LEX_IVAL ($1), INDEFR, INDEFD)
		}
		| RNUMBER {
#		    YYMOVE ($1, $$)
		    call fc_cgen (RNUMBER, "", INDEFI, LEX_RVAL ($1), INDEFD)
		}
		| DNUMBER {
#		    YYMOVE ($1, $$)
		    call fc_cgen (DNUMBER, "", INDEFI, INDEFR, LEX_DVAL ($1))
		}
		| STRING {
#		    YYMOVE ($1, $$)
		    call fc_cgen (STRING, LEX_ID ($1), INDEFI, INDEFR, INDEFD)
		}
		| COLUMN INUMBER {
#		    call fc_cat2 (LEX_ID ($1), LEX_ID ($2),
#				  LEX_ID ($$), LEN_ID)
		    call fc_cgen (COLUMN, "1", LEX_IVAL ($2), INDEFR, INDEFD)
		}
		| COLUMN INUMBER FILE INUMBER {
#		    call fc_cat4 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($4), LEX_ID ($$), LEN_ID)
		    call fc_cgen (COLUMN, LEX_ID ($4), LEX_IVAL ($2),
				  INDEFR, INDEFD)
		}
		;

arginit		: empty {
		    nargs = 0
		}
		;

arglist		: expr {
#		    YYMOVE ($1, $$)
		    nargs = nargs + 1
		}
		| expr COMMA arglist {
#		    call fc_cat3 (LEX_ID ($1), LEX_ID ($2), LEX_ID ($3),
#				  LEX_ID ($$), LEN_ID)
		    nargs = nargs + 1
		}
		| empty
		;

funct		: F_ACOS {
	    	    YYMOVE ($1, $$)
		}
      		| F_ASIN {
		    YYMOVE ($1, $$)
		}
		| F_ATAN {
		    YYMOVE ($1, $$)
		}
		| F_ATAN2 {
		    YYMOVE ($1, $$)
		}

		| F_COS {
		    YYMOVE ($1, $$)
		}
		| F_SIN {
		    YYMOVE ($1, $$)
		}
		| F_TAN {
		    YYMOVE ($1, $$)
		}

		| F_EXP {
		    YYMOVE ($1, $$)
		}
		| F_LOG {
		    YYMOVE ($1, $$)
		}
		| F_LOG10 {
		    YYMOVE ($1, $$)
		}
		| F_SQRT {
		    YYMOVE ($1, $$)
		}

		| F_ABS {
	    	    YYMOVE ($1, $$)
		}
		| F_INT {
	    	    YYMOVE ($1, $$)
		}

		| F_MIN {
		    YYMOVE ($1, $$)
		}
		| F_MAX {
		    YYMOVE ($1, $$)
		}

		| F_AVG {
		    YYMOVE ($1, $$)
		}
		| F_MEDIAN {
		    YYMOVE ($1, $$)
		}
		| F_MODE {
		    YYMOVE ($1, $$)
		}
		| F_SIGMA {
		    YYMOVE ($1, $$)
		}

		| F_STR {
		    YYMOVE ($1, $$)
		}
		;


empty		: ;


%%
