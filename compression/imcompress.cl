# IMCOMPRESS.CL -- Compress the pixel file of an IRAF image, and update
# the image header to reflect the change in the pixel file name. The pixel
# file is compressed in place.

procedure imcompress (images)

string	images		{"", prompt = "Images to compress"}
bool	verbose		{no, prompt = "Verbose operation ?"}

begin
	improc (images, verbose=verbose, operation="compress")
end
