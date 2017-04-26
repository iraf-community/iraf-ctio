include	"parser.h"

# FC_ERROR - Issue an error message to the standard output and count
# errors acording to the error severity code.

procedure fc_error (msg, severity)

char	msg[ARB]		# error message
int	severity		# severity code

char	ch

include	"lexer.com"
include	"parser.com"

begin
	# Print line up to the point where the error was detected
	ch = Memc[lex_line + lex_pos - 1]
	Memc[lex_line + lex_pos - 1] = EOS
	call eprintf ("** %s <===\n")
	    call pargstr (Memc[lex_line])
	Memc[lex_line + lex_pos - 1] = ch

	# Branch on error severity code
	switch (severity) {
	case PERR_WARNING:
	    par_nwarnings = par_nwarnings + 1
	    call eprintf ("** Warning near '%s': %s\n")
		call pargstr (lex_id)
	        call pargstr (msg)
	case PERR_SYNTAX:
	    par_nerrors = par_nerrors + 1
	    call eprintf ("** Syntax error near '%s': %s\n")
		call pargstr (lex_id)
	        call pargstr (msg)
	case PERR_SEMANTIC:
	    par_nerrors = par_nerrors + 1
	    call eprintf ("** Semantic error near '%s': %s\n")
		call pargstr (lex_id)
	        call pargstr (msg)
	}
end
