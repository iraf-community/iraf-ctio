include	<imhdr.h>
include <error.h>

define	BOXSIZE		5	# size of search box

# ICNTR - Finds the centroids of all the stars whose positions are stored
# in one or more files. The centroids are calculated for all the images
# in the list.

procedure t_icntr()

char	images[SZ_FNAME]	# image list name
char	output[SZ_FNAME]	# output file name
char	pos[SZ_FNAME]		# star positions list name
pointer	poslist, imlist		# lists
int	poslen, imlen		# number of elements on lists
char	posname[SZ_FNAME]	# positions file name
int	infd, outfd		# file descriptors
int	i, n			# auxiliary counters
real	x, y			# initial star position

int	fntlenb(), fntgfnb(), open(), fscan()
pointer	fntopnb()

begin
	# Get CL parameters
	call clgstr ("images", images, SZ_FNAME)
	call clgstr ("positions", pos, SZ_FNAME)
	call clgstr ("output", output, SZ_FNAME)

	# Open star positions list
	poslist = fntopnb (pos, YES)
	poslen = fntlenb (poslist)

	# Open image list
	imlist = fntopnb (images, YES)
	imlen = fntlenb (imlist)

	# Open output file
	outfd = open (output, NEW_FILE, TEXT_FILE)

	# Loop over the file names
	do i = 1, poslen {

	    # get next file name and open file
	    n = fntgfnb (poslist, posname, SZ_FNAME)
	    infd = open (posname, READ_ONLY, TEXT_FILE)

	    # read coordinates from file and process all the images
	    # for each coordiante pair
	    while (fscan (infd) != EOF) {
	        call gargr (x)
		call gargr (y)

		call process_images (x, y, imlist, imlen, outfd)
	    }
	}

	# close output file
	call close (outfd)
end


# PROCESS_IMAGES - For each pair of star coordinates (x,y), opens each image
# on the list and finds the centroids. The starting positions, the calculated
# positions and the image name are written into the output file.

procedure process_images (x, y, imlist, imlen, outfd)

real	x, y		# star position
pointer	imlist		# list of images
int	imlen		# length of list of images
int	outfd		# output file descriptor (already opened)


int	i, n			# auxiliary counters
char	imname[SZ_FNAME]	# image name
real	xcntr, ycntr		# calculated star position
pointer	im			# image descriptor

int	fntgfnb()
pointer	immap()

begin
	# Loop over image names from the begining of the list
	call fntrewb (imlist)
	do i = 1, imlen {

	    # get next image name
	    n = fntgfnb (imlist, imname, SZ_FNAME)

	    # open image checking possible error
	    iferr (im = immap (imname, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # find star centroid
	    call mpcntr (im, IM_LEN (im,1), IM_LEN (im,2), x, y, BOXSIZE,
			 xcntr, ycntr)

	    # output results
	    call fprintf (outfd, "   %5.0f %5.0f  %8.3f %8.3f     %s\n")
		call pargr (x)
		call pargr (y)
		call pargr (xcntr)
		call pargr (ycntr)
		call pargstr (imname)

	    # close image
	    call imunmap (im)
	}

	# output a blank line between coordinates
	call fprintf (outfd, "\n")
end
