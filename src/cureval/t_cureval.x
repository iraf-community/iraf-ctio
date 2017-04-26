# Calculation types
define	CALC_TYPES	"|real|double|"
define	CALC_REAL	1
define	CALC_DOUBLE	2

# Maximun number of characters needed to store a calculation type string
define	SZ_TYPE		6


# T_CUREVAL -- Evaluate the fit for a finction fitted by CURFIT. The input
# to this task is the output of CURFIT.

procedure t_cureval ()

char	input[SZ_FNAME]			# input file name
char	curfin[SZ_FNAME]		# input to CURFIT
char	curfout[SZ_FNAME]		# output from CURFIT
char	type[SZ_TYPE]
int	calctype			# calculation type
real	xmin, xmax			# limit values for CURFIT input

int	clgwrd()
real	clgetr()

begin
	# Get parameters
	call clgstr ("input",   input,   SZ_FNAME)
	call clgstr ("curfin",  curfin,  SZ_FNAME)
	call clgstr ("curfout", curfout, SZ_FNAME)
	xmin = clgetr ("xmin")
	xmax = clgetr ("xmax")
	calctype = clgwrd ("calctype", type, SZ_TYPE, CALC_TYPES)

	# Call the processing procedure acording to the calculation type
	if (calctype == CALC_REAL)
	    call cev_procr (input, curfin, curfout, xmin, xmax)
	else
	    call cev_procd (input, curfin, curfout, double (xmin), 
			    double (xmax))
end
