.help fccode
Code generator

The parser generates code for all the expressions in Reverse Polish Notation
(RPN). Under this notation operands come first and the operation is after
the last operand.

In the current implementation, arguments can be either constants, or column
references. Column references use three words: one for the instruction code,
one for the column number and another one for the file number. Constants
values use two words: one for the instruction code and the other one is an
offset into one of the constant buffers (depending on the data type of the
constant).

Operations always use a single word, and functions might use up to two
words when they expect a variable number of arguments (e.g. min).

When expressions are evaluated operands are pushed into a stack, until an
operation is found. The operation takes as many stack places (from the stack
top) as needed for arguments, and puts the result in the top of the stack.
The final result will be always in the top of the stack.

The RPN instructions are stored into memory as a dinamically allocated
buffer of integer type (TY_INT).

.nf
Entry points:

	    fc_calloc    ()				    Allocate code buf.
	    fc_cfree     ()				    Free code buffers

	    fc_cinit     ()				    Start code gen.
	    fc_cend      (lexptr)			    End code gen.

	    fc_cgen      (token, strval, ival, rval, dval)  Generate code

     nexp = fc_ccount    ()				    Return number of
							    expressions.

     cptr = fc_cgetcode  (expnum)			    Get code buffer

      val = fc_cget[ird] (offset)			    Get constant
   nchars = fc_cgstr     (offset, strval, maxch)

   offset = fc_cput[ird] (val)				    Enter constant
   offset = fc_cpstr     (strval)

	    fc_cdump (maxcode)				    Dump code buffers
.fi
.endhelp

include	"lexer.h"
include	"eval.h"
include	"parser.h"
include	"token.h"

# Pointer Mem
define	MEMP	Memi


# FC_CALLOC - Allocate space for buffer containing pointers to code buffers.

procedure fc_calloc ()

include	"code.com"

begin
#call eprintf ("fc_calloc\n")

	# Initialize constant buffer pointers and offsets
	code_constc  = NULL
	code_consti  = NULL
	code_constr  = NULL
	code_constd  = NULL
	code_offsetc = 0
	code_offseti = 0
	code_offsetr = 0
	code_offsetd = 0

	# Initalize code buffer variables
	code_cp    = 0
	code_count = 0
	code_size  = 10

	# Allocate pointers to code buffers
	call malloc (code_pointers, code_size, TY_POINTER)
end


# FC_CFREE - Free pointer buffer and associated code buffers.

procedure fc_cfree ()

int	i
pointer	cptr

include	"code.com"

begin
#call eprintf ("fc_cfree\n")

	# Free code buffers
	do i = 1, code_count {
	    cptr = MEMP[code_pointers + i - 1]
	    if (cptr != NULL)
		call mfree (cptr, TY_INT)
	    else
		call error (0, "fc_cfree: Null code pointer")
	}

	# Free pointer buffer
	call mfree (code_pointers, TY_POINTER)
end


# FC_CINIT - Start code generation for a single expression.

procedure fc_cinit ()

include	"code.com"

begin
#call eprintf ("fc_cinit\n")

	# Point to the first instruction in the code buffer.
	code_cp = 1

	# Increment the expression counter
	code_count = code_count + 1

	# Allocate a new code buffer for the next expression. Reallocate
	# the pointer buffer if no more pointers are available.
	if (code_count > code_size) {
	    code_size = 2 * code_size
	    call realloc (code_pointers, code_size, TY_POINTER)
	}
	call malloc (MEMP[code_pointers + code_count - 1], LEN_CODE, TY_INT)
end


# FC_CEND - Finish code generation for a single expression.

procedure fc_cend (lexptr)

pointer	lexptr			# lexer symbol pointer

pointer	cptr

include	"code.com"

begin
#call eprintf ("fc_cend: lexptr=%d\n")
#call pargi (lexptr)

	# Get pointer to the current code buffer
	cptr = MEMP[code_pointers + code_count - 1]

	# Put the end-of-code marker in the next instruction
	Memi[cptr + code_cp - 1] = PEV_EOC

	# Set code length
	LEX_CLEN (lexptr) = code_cp

	# Copy the contents of the code buffer into the lexer symbol
	call amovi (Memi[cptr], Memi[LEX_CODE (lexptr)], code_cp)

	# Reset code counter to the first instruction
	code_cp = 1
end


# FC_CGEN - Generate RPN code.

procedure fc_cgen (token, strval, ival, rval, dval)

int	token			# token
char	strval[ARB]		# string value
int	ival			# integer value
real	rval			# real value
real	dval			# double value

int	ip, fnum
pointer	cptr

include	"code.com"

int	ctoi()
int	fc_cputi(), fc_cputr(), fc_cputd(), fc_cpstr()

begin
#call eprintf ("fc_cgen: token=%d, strval=(%s), ival=%d, rval=%g, dval=%g\n")
#call pargi (token)
#call pargstr (strval)
#call pargi (ival)
#call pargr (rval)
#call pargd (dval)

	# Get pointer to current code buffer
	cptr = MEMP[code_pointers + code_count - 1]

	# Generate code for the current instruction according
	# with token value returned by the lexer
	switch (token) {

	case COLUMN:	# column reference

	    # Store column instruction code
	    Memi[cptr + code_cp - 1] = PEV_COLUMN
	    code_cp = code_cp + 1

	    # Store the file number obtained by just converting
	    # the file identifier into an integer. So far files
	    # are identified with integer numbers, but this may
	    # change in the future to allow more flexibility.
	    ip = 1
	    if (ctoi (strval, ip, fnum) > 0)
		Memi[cptr + code_cp - 1] = fnum
	    else
		call error (0, "fc_cgen: Cannot convert file number")
	    code_cp = code_cp + 1
	    
	    # Store column number
	    Memi[cptr + code_cp - 1] = ival


	case INUMBER:

	    # Store number instruction code and the integer number
	    # offset in the next instruction
	    Memi[cptr + code_cp - 1] = PEV_INUMBER
	    code_cp = code_cp + 1
	    Memi[cptr + code_cp - 1] = fc_cputi (ival)
	    #Memi[cptr + code_cp - 1] = fc_cputi (ival)

	case RNUMBER:

	    # Store number instruction code and the real number
	    # offset in the next instruction
	    Memi[cptr + code_cp - 1] = PEV_RNUMBER
	    code_cp = code_cp + 1
	    Memi[cptr + code_cp - 1] = fc_cputr (rval)
	    #Memr[cptr + code_cp - 1] = rval

	case DNUMBER:

	    # Store number instruction code and the double number
	    # value in the next instruction (REVISE)
	    Memi[cptr + code_cp - 1] = PEV_DNUMBER
	    code_cp = code_cp + 1
	    Memi[cptr + code_cp - 1] = fc_cputd (dval)
	    #Memr[cptr + code_cp - 1] = real (dval)

	case STRING:

	    # Store string instruction code and the string offset
	    # in the next instruction.
	    Memi[cptr + code_cp - 1] = PEV_STRING
	    code_cp = code_cp + 1
	    Memi[cptr + code_cp - 1] = fc_cpstr (strval)
	    

	case UPLUS:
	    Memi[cptr + code_cp - 1] = PEV_UPLUS

	case UMINUS:
	    Memi[cptr + code_cp - 1] = PEV_UMINUS


	case PLUS:
	    Memi[cptr + code_cp - 1] = PEV_PLUS

	case MINUS:
	    Memi[cptr + code_cp - 1] = PEV_MINUS

	case STAR:
	    Memi[cptr + code_cp - 1] = PEV_STAR

	case SLASH:
	    Memi[cptr + code_cp - 1] = PEV_SLASH

	case EXPON:
	    Memi[cptr + code_cp - 1] = PEV_EXPON

	case CONCAT:
	    Memi[cptr + code_cp - 1] = PEV_CONCAT


	case F_ACOS:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_ACOS
	    else
		call fc_error ("Incorrent number of arguments in ACOS",
			       PERR_SEMANTIC)

	case F_ASIN:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_ASIN
	    else
		call fc_error ("Incorrent number of arguments in ASIN",
			       PERR_SEMANTIC)

	case F_ATAN:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_ATAN
	    else
		call fc_error ("Incorrent number of arguments in ATAN",
			       PERR_SEMANTIC)

	case F_ATAN2:
	    if (ival == 2)
	        Memi[cptr + code_cp - 1] = PEV_ATAN2
	    else
		call fc_error ("Incorrent number of arguments in ATAN2",
			       PERR_SEMANTIC)


	case F_COS:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_COS
	    else
		call fc_error ("Incorrent number of arguments in COS",
			       PERR_SEMANTIC)

	case F_SIN:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_SIN
	    else
		call fc_error ("Incorrent number of arguments in SIN",
			       PERR_SEMANTIC)

	case F_TAN:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_TAN
	    else
		call fc_error ("Incorrent number of arguments in TAN",
			       PERR_SEMANTIC)


	case F_EXP:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_EXP
	    else
		call fc_error ("Incorrent number of arguments in EXP",
			       PERR_SEMANTIC)

	case F_LOG:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_LOG
	    else
		call fc_error ("Incorrent number of arguments in LOG",
			       PERR_SEMANTIC)

	case F_LOG10:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_LOG10
	    else
		call fc_error ("Incorrent number of arguments in LOG10",
			       PERR_SEMANTIC)

	case F_SQRT:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_SQRT
	    else
		call fc_error ("Incorrent number of arguments in SQRT",
			       PERR_SEMANTIC)


	case F_ABS:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_ABS
	    else
		call fc_error ("Incorrent number of arguments in ABS",
			       PERR_SEMANTIC)

	case F_INT:
	    if (ival == 1)
	        Memi[cptr + code_cp - 1] = PEV_INT
	    else
		call fc_error ("Incorrent number of arguments in INT",
			       PERR_SEMANTIC)


	case F_MIN:

	    # The number of arguments in the function defines whether to
	    # use numbers from a single column or numbers from a single row
	    if (ival > 1) {
		Memi[cptr + code_cp - 1] = PEV_MIN
		code_cp = code_cp + 1
		Memi[cptr + code_cp - 1] = ival
	    } else if (ival == 1) {
		# Memi[cptr + code_cp - 1] = PEV_COLMIN
		call fc_error ("Incorrent number of arguments in MIN",
			       PERR_SEMANTIC)
	    } else {
		call fc_error ("Incorrent number of arguments in MIN",
			       PERR_SEMANTIC)
	    }

	case F_MAX:

	    # The number of arguments in the function defines whether to
	    # use numbers from a single column or numbers from a single row
	    if (ival > 1) {
		Memi[cptr + code_cp - 1] = PEV_MAX
		code_cp = code_cp + 1
		Memi[cptr + code_cp - 1] = ival
	    } else if (ival == 1) {
		# Memi[cptr + code_cp - 1] = PEV_COLMAX
		call fc_error ("Incorrent number of arguments in MAX",
			       PERR_SEMANTIC)
	    } else {
		call fc_error ("Incorrent number of arguments in MAX",
			       PERR_SEMANTIC)
	    }

	case F_AVG:

	    # The number of arguments in the function defines whether to
	    # use numbers from a single column or numbers from a single row
	    if (ival > 1) {
		Memi[cptr + code_cp - 1] = PEV_AVG
		code_cp = code_cp + 1
		Memi[cptr + code_cp - 1] = ival
	    } else if (ival == 1) {
		# Memi[cptr + code_cp - 1] = PEV_COLAVG
		call fc_error ("Incorrent number of arguments in AVG",
			       PERR_SEMANTIC)
	    } else {
		call fc_error ("Incorrent number of arguments in AVG",
			       PERR_SEMANTIC)
	    }

	case F_MEDIAN:

	    # The number of arguments in the function defines whether to
	    # use numbers from a single column or numbers from a single row
	    if (ival > 1) {
		Memi[cptr + code_cp - 1] = PEV_MEDIAN
		code_cp = code_cp + 1
		Memi[cptr + code_cp - 1] = ival
	    } else if (ival == 1) {
		# Memi[cptr + code_cp - 1] = PEV_COLMEDIAN
		call fc_error ("Incorrent number of arguments in MEDIAN",
			       PERR_SEMANTIC)
	    } else {
		call fc_error ("Incorrent number of arguments in MEDIAN",
			       PERR_SEMANTIC)
	    }

	case F_MODE:

	    # The number of arguments in the function defines whether to
	    # use numbers from a single column or numbers from a single row
	    if (ival > 1) {
		Memi[cptr + code_cp - 1] = PEV_MODE
		code_cp = code_cp + 1
		Memi[cptr + code_cp - 1] = ival
	    } else if (ival == 1) {
		# Memi[cptr + code_cp - 1] = PEV_COLMODE
		call fc_error ("Incorrent number of arguments in MODE",
			       PERR_SEMANTIC)
	    } else {
		call fc_error ("Incorrent number of arguments in MODE",
			       PERR_SEMANTIC)
	    }

	case F_SIGMA:

	    # The number of arguments in the function defines whether to
	    # use numbers from a single column or numbers from a single row
	    if (ival > 1) {
		Memi[cptr + code_cp - 1] = PEV_SIGMA
		code_cp = code_cp + 1
		Memi[cptr + code_cp - 1] = ival
	    } else if (ival == 1) {
		# Memi[cptr + code_cp - 1] = PEV_COLSIGMA
		call fc_error ("Incorrent number of arguments in SIGMA",
			       PERR_SEMANTIC)
	    } else {
		call fc_error ("Incorrent number of arguments in SIGMA",
			       PERR_SEMANTIC)
	    }


	case F_STR:
	    Memi[cptr + code_cp - 1] = PEV_STR

	default:
	    call error (0, "fc_cgen: Illegal instruction")
	}

	# Count codes and check boundaries. Reserve at
	# least four places: three for the next instruction,
	# and one for the end-of-code marker
	code_cp = code_cp + 1
	if (code_cp > LEN_CODE - 3)
	    call error (0, "fc_cgen: Too much code")
end


# FC_CCOUNT -- Return the number of code buffers generated, where expressions
# are stored.

int procedure fc_ccount ()

include	"code.com"

begin
	return (code_count)
end


# FC_CGETCODE -- Get code pointer for a given expression number.

pointer procedure fc_cgetcode (expnum)

int	expnum			# expression number

include	"code.com"

begin
#call eprintf ("fc_cget: expnum=%d, cptr=%x\n")
#call pargi (expnum)
#call pargi (MEMP[code_pointers + expnum - 1])

	if (expnum < 1 || expnum > code_count)
	    call error (0, "fc_cget: Illegal expression number")
	else
	    return (MEMP[code_pointers + expnum - 1])
end


# FC_CGET[IRD] -- Get a constant value from one of the constant buffers.


int procedure fc_cgeti (offset)

int	offset			# constant offset

include	"code.com"

begin
#call eprintf ("fc_cget: offset=%d\n")
#call pargi (offset)

	# Raise an error if no constant buffer has been allocated,
	# or if the given offset is out of range.
	if (code_consti == NULL)
	    call error (0, "fc_cget: No buffer has been allocated")
	else if (offset < 0 || offset > code_offseti)
	    call error (0, "fc_cget: Constant offset out of range")
	else
	    return (Memi[code_consti + offset])
end


real procedure fc_cgetr (offset)

int	offset			# constant offset

include	"code.com"

begin
#call eprintf ("fc_cget: offset=%d\n")
#call pargi (offset)

	# Raise an error if no constant buffer has been allocated,
	# or if the given offset is out of range.
	if (code_constr == NULL)
	    call error (0, "fc_cget: No buffer has been allocated")
	else if (offset < 0 || offset > code_offsetr)
	    call error (0, "fc_cget: Constant offset out of range")
	else
	    return (Memr[code_constr + offset])
end


double procedure fc_cgetd (offset)

int	offset			# constant offset

include	"code.com"

begin
#call eprintf ("fc_cget: offset=%d\n")
#call pargi (offset)

	# Raise an error if no constant buffer has been allocated,
	# or if the given offset is out of range.
	if (code_constd == NULL)
	    call error (0, "fc_cget: No buffer has been allocated")
	else if (offset < 0 || offset > code_offsetd)
	    call error (0, "fc_cget: Constant offset out of range")
	else
	    return (Memd[code_constd + offset])
end




# FC_CPUT[IRD] -- Enter a constant in one of the constant buffers.


int procedure fc_cputi (ival)

int	ival

include	"code.com"

begin
#call eprintf ("fc_cput: val=%g\n")
#call parg$t ($tval)

	# Allocate space for one more constant
	if (code_consti == NULL) {
	    code_offseti = 0
	    call malloc (code_consti, code_offseti + 1, TY_INT)
	} else {
	    code_offseti = code_offseti + 1
	    call realloc (code_consti, code_offseti + 1, TY_INT)
	}

	# Enter constant in the buffer
	Memi[code_consti + code_offseti] = ival

	# Return constant offset
	return (code_offseti)
end


int procedure fc_cputr (rval)

real	rval

include	"code.com"

begin
#call eprintf ("fc_cput: val=%g\n")
#call parg$t ($tval)

	# Allocate space for one more constant
	if (code_constr == NULL) {
	    code_offsetr = 0
	    call malloc (code_constr, code_offsetr + 1, TY_REAL)
	} else {
	    code_offsetr = code_offsetr + 1
	    call realloc (code_constr, code_offsetr + 1, TY_REAL)
	}

	# Enter constant in the buffer
	Memr[code_constr + code_offsetr] = rval

	# Return constant offset
	return (code_offsetr)
end


int procedure fc_cputd (dval)

double	dval

include	"code.com"

begin
#call eprintf ("fc_cput: val=%g\n")
#call parg$t ($tval)

	# Allocate space for one more constant
	if (code_constd == NULL) {
	    code_offsetd = 0
	    call malloc (code_constd, code_offsetd + 1, TY_DOUBLE)
	} else {
	    code_offsetd = code_offsetd + 1
	    call realloc (code_constd, code_offsetd + 1, TY_DOUBLE)
	}

	# Enter constant in the buffer
	Memd[code_constd + code_offsetd] = dval

	# Return constant offset
	return (code_offsetd)
end




# FC_CGSTR -- Get character string from the character constant buffer. It
# returns the number of characters in the output string.

int procedure fc_cgstr (offset, strval, maxch)

int	offset			# string offset
char	strval[maxch]		# output string
int	maxch			# maximum number of characters

int	gstrcpy()

include	"code.com"

begin
#call eprintf ("fc_cgstr: offset=%d, maxch=%d\n")
#call pargi (offset)
#call pargi (maxch)

	# Raise an error if no string buffer has been allocated,
	# or if the given offset is out of range.
	if (code_constc == NULL)
	    call error (0, "fc_cgstr: No string buffer has been allocated")
	else if (offset < 0 || offset > code_offsetc)
	    call error (0, "fc_cgstr: String offset out of range")
	else
	    return (gstrcpy (Memc[code_constc + offset], strval, maxch))
end


# FC_CPSTR -- Enter a character string in the character constant buffer.

int procedure fc_cpstr (strval)

char	strval[ARB]		# string constant

int	len

int	strlen()

include	"code.com"

begin
#call eprintf ("fc_cpstr: strval=(%s)\n")
#call pargstr (strval)

	# Get string length
	len = strlen (strval)

	# Allocate space for the new string in the buffer
	if (code_constc == NULL) {
	    code_offsetc = 0
	    call malloc (code_constc, len, TY_CHAR)
	} else {
	    code_offsetc = code_offsetc +
			   strlen (Memc[code_constc + code_offsetc]) + 1
	    call realloc (code_constc, code_offsetc + len, TY_CHAR)
	}

	# Copy string into the constant buffer
	call strcpy (strval, Memc[code_constc + code_offsetc], len)

	# Return offset to the string
	return (code_offsetc)
end


# FC_CDUMP -- Dump all code buffers.

procedure fc_cdump (maxcode)

int	maxcode			# max number of code buffer elements to dump

int	i, j
pointer	cptr

include	"code.com"

int	strlen()

begin
	call eprintf (
	    "-- Code dump: pointers=%x, count=%d, size=%d, cp=%d --\n")
	    call pargi (code_pointers)
	    call pargi (code_count)
	    call pargi (code_size)
	    call pargi (code_cp)

	if (code_pointers == NULL) {
	    call eprintf ("Null pointer to code buffers\n")
	    return
	}

	# Dump code buffers
	do i = 1, code_count {

	    cptr = Memi[code_pointers + i - 1]

	    call eprintf ("%d, cptr=%x: [")
		call pargi (i)
		call pargi (cptr)

	    if (cptr == NULL) {
		call eprintf ("Null code buffer pointer]\n")
		next
	    }

	    do j = 1, min (maxcode, LEN_CODE) {

		call eprintf ("%d ")
		    call pargi (Memi[cptr + j - 1])

		if (Memi[cptr + j - 1] == PEV_EOC)
		    break
	    }

	    call eprintf ("]\n")
	}

	# Dump integer constants
	call eprintf ("Integer constants %x, %d: ")
	    call pargi (code_consti)
	    call pargi (code_offseti)
	if (code_consti != NULL) {
	    do i = 0, code_offseti {
		call eprintf ("%d ")
		    call pargi (Memi[code_consti + i])
	    }
	    call eprintf ("\n")
	} else
	    call eprintf ("Null buffer pointer\n")

	# Dump real constants
	call eprintf ("Real constants    %x, %d: ")
	    call pargi (code_constr)
	    call pargi (code_offsetr)
	if (code_constr != NULL) {
	    do i = 0, code_offsetr {
		call eprintf ("%g ")
		    call pargr (Memr[code_constr + i])
	    }
	    call eprintf ("\n")
	} else
	    call eprintf ("Null buffer pointer\n")

	# Dump double constants
	call eprintf ("Double constants  %x, %d: ")
	    call pargi (code_constd)
	    call pargi (code_offsetd)
	if (code_constd != NULL) {
	    do i = 0, code_offsetd {
		call eprintf ("%g ")
		    call pargd (Memd[code_constd + i])
	    }
	    call eprintf ("\n")
	} else
	    call eprintf ("Null buffer pointer\n")

	# Dump character strings
	call eprintf ("Character strings %x, %d: ")
	    call pargi (code_constc)
	    call pargi (code_offsetc)
	if (code_constc != NULL) {
	    for (i = 0; i <= code_offsetc;
		 i = i + strlen (Memc[code_constc + i]) + 1) {
		call eprintf ("(%s) ")
		    call pargstr (Memc[code_constc + i])
	    }
	    call eprintf ("\n")
	} else
	    call eprintf ("Null buffer pointer\n")

	call eprintf ("-- -- -- -- -- -- -- -- --\n")
end
