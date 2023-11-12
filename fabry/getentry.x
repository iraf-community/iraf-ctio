include	<mach.h>

# GET_NEXT_ENTRY -- Given a list of ranges and the current file	number,
# find and return the next file	number in order	of entry.
# EOF is returned at the end of	the list.

int procedure get_next_entry (ranges, number)

int	ranges[ARB]		# Range array
int	number			# Both input and output parameter

int	ip,	first, last, step, next_number,	remainder
int	flag1, flag2, flag3

common	/gnicom/	flag1, flag2

data	flag3/YES/

begin
	number	= number + 1
	next_number = MAX_INT
	if ((flag2 == YES) || (flag3 == YES)) {
	    ip	= 1
	    flag2 = NO
	    flag3 = NO
	}

	first = min (ranges[ip], ranges[ip+1])
	last =	max (ranges[ip], ranges[ip+1])
	step =	ranges[ip+2]

	if (number >= first &&	number <= last)	{
	    remainder = mod (number - first, step)
	    if	(remainder == 0)
		return (number)
	    if	(number	- remainder + step <= last)
		next_number =	number - remainder + step
	    else
		go to	10

	} else	if (first > number)
	    next_number = min (next_number, first)

	else {
10	    ip = ip + 3
	    if	(ranges[ip] != 0 && ranges[ip+1] !=0 &&	ranges[ip+2] !=0)
		next_number =	min (ranges[ip], ranges[ip+1])
	}

	if (next_number == MAX_INT) {
	    ip	= 1
	    flag2 = YES
	    return (EOF)

	} else	{
	    number = next_number
	    return (number)
	}
end

procedure rst_get_entry	()

int	first, flag2
common	/gnicom/	first, flag2

begin
	flag2 = YES
end
