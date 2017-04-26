include	<time.h>


# PUT_TIME - Put time stamp into a text file

procedure put_time (fd, label)

int	fd			# log file descriptor
char	label[ARB]		# string label

char	str[SZ_TIME]		# time string

long	clktime()

begin
	call cnvtime (clktime (long (0)), str, SZ_TIME)

	call fprintf (fd, "\n**** %s **** (%s) ****\n")
	    call pargstr (str)
	    call pargstr (label)
end
