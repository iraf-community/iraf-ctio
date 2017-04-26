include	<ctype.h>


# STRWHT - Check if an string contains only whitespaces.

bool procedure strwht (str)

char	str[ARB]		# input string

int	i

int	strlen()

begin
	do i = 1, strlen (str) {
	    if (!IS_WHITE (str[i]))
		return (false)
	}

	return (true)
end
