# LAMBDA_TO_PIXEL2 -- Compute transformation table converting lambda to
#		      pixel number for relinearization

procedure lambda_to_pixel2 (w0out, wpcout, w0in, wpcin, login, ncols, 
	logarithm, invert)

real	w0out, wpcout, w0in, wpcin
bool	login
int	ncols
bool	logarithm
real	invert[ARB]

int	i
real	w

begin
	if ((logarithm && login) || (!logarithm && !login))
	    do i = 1, ncols {
	        w = w0out + (i - 1) * wpcout
	        invert[i] = (w - w0in) / wpcin + 1
	    }
	else if (logarithm)
	    do i = 1, ncols {
	        w = 10. ** (w0out + (i - 1) * wpcout)
	        invert[i] = (w - w0in) / wpcin + 1
	    }
	else
	    do i = 1, ncols {
	        w = log10 (w0out + (i - 1) * wpcout)
	        invert[i] = (w - w0in) / wpcin + 1
	    }
end
