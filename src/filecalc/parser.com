# Parser common

int	par_nerrors		# number of errors
int	par_nwarnings		# number of warnings

common	/parcom/ par_nerrors, par_nwarnings
