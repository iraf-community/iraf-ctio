# IMUNCOMPRESS.CL -- Uncompress the pixel file of an IRAF image, and update
# the image header to reflect the change in the pixel file name. The pixel
# file is uncompressed in place.

procedure imuncompress (images)

string	images		{"", prompt = "Images to uncompress"}
bool	verbose		{no, prompt = "Verbose operation ?"}

begin
	improc (images, verbose=verbose, operation="uncompress")
end
