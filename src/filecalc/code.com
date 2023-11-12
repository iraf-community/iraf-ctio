# Code generator common. This common handles the buffer with pointers to the
# code buffers as well as some control counters. Each code buffer contains
# the code for a single expression.

int	code_constc		# character string buffer
int	code_offsetc		# character string offset

int	code_consti		# integer constant buffer
int	code_offseti		# integer constant offset

int	code_constr		# real constant buffer
int	code_offsetr		# real constant offset

int	code_constd		# double constant buffer
int	code_offsetd		# double constant offset

int	code_cp			# next free instruction for current buffer
int	code_count		# expression counter
int	code_size		# size of pointer buffer (allocated pointers)
pointer	code_pointers		# pointers to code buffers

common	/codecom/	code_constc, code_offsetc,
			code_consti, code_offseti,
			code_constr, code_offsetr,
			code_constd, code_offsetd,
			code_cp, code_count, code_size, code_pointers
