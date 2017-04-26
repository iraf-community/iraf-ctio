# INTVEL - Interactive velocity determination. This CL script call the
# task AVGVEL interactively using the image cursor readback to get its input.

procedure intvel (cube_image, output, lambda_rest)

string	cube_image	{ "", prompt = "Input name for image cube" }
string	output		{ "", prompt = "Output file name" }
real	lambda_rest	{ INDEF, prompt = "Rest wavelength of observed line" }
int	band		{ 1, prompt = "Image band to display" }
int	nrings		{ 0, min = 0, prompt = "Number of square rings to average" }
int	x_offset	{ 1, min = 1, prompt = "Offset in x due to subraster extraction" }
int	y_offset	{ 1, min = 1, prompt = "Offset in y due to subraster extraction" }
bool	verbose		{ yes, prompt = "Output results to standard output" }
bool	plot		{ yes, prompt = "Create plots at each fitting point" }
string	device		{ "stdgraph", prompt = "Output device for plots" }
imcur	*cursor		{ "", prompt = "Image cursor" }
real	x
real	y
int	wcs
string	key

begin
	# Positional parameters
	string	image
	string	outfile
	int	image_band
	real	lambda

	# Auxiliary variables
	string	aux

	# Get positional parameters only once
	image = intvel.cube_image
	outfile = intvel.output
	image_band = intvel.band
	lambda = intvel.lambda_rest
	
	# Display the image band
	aux = image // "[*,*," // str (image_band) // "]"
	display (aux, 1)

	# Loop until a 'q' is pressed
	while (fscan (cursor, x, y, wcs, key) != EOF) {

	    # Test for quit
	    if (key == 'q')
		break

	    # Call avgvel task
	    avgvel (image,
		    outfile,
		    lambda,
		    x = x,
		    y = y,
		    nrings = nrings,
		    x_offset = x_offset,
		    y_offset = y_offset,
		    verbose = verbose,
		    plot = plot,
		    device = device)
	}
end
