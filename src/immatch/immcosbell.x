include	<math.h>


# IMM_COSBELLR -- Apply cosine bell to a real data array. The operation 
# can be performed in place.

procedure imm_cosbellr (input, output, npts)

real	input[npts]		# input array
real	output[npts]		# output array
int	npts			# number of points

int	i
real	slope

begin
	slope = PI / (npts - 1)
	do i = 1, npts 
	    output[i] = input[i] * cos ((i - 1) * slope - HALFPI)
end


# IMM_COSBELLX -- Apply cosine bell to a complex data array. The operation
# can be performed in place.

procedure imm_cosbellx (input, output, npts)

complex	input[npts]		# input array
complex	output[npts]		# output array
int	npts			# number of points

int	i
real	slope

begin
	slope = PI / (npts - 1)
	do i = 1, npts 
	    output[i] = input[i] * cos ((i - 1) * slope - HALFPI)
end
