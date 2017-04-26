# MKSHIFT -- Review the list of star coordinates given in a file,
#       and compute delta shifts for    input to IMSHIFT
#       The deltas are prepared into    a CL script ready to
#       run.    The deltas are also added to the image header
#       of the shifted image using the script   technique.
#
# Assumptions include that stars are entered in the same
# order for each image. A large dispersion will be used
# as a flag to indicate that this was not the case.

include <fset.h>
include <ctype.h>

# Typical dimensions might be 5-10 stars in 15-20 images for a
# total of about 200 entries in the file - 500 should be plenty.

define  MAX_IMAGES      50      # Maximum number of simultaneous images
define  MAX_STARS       500     # Maximum number of simultaneous stars

procedure t_mkshift ()

char    coord_file[SZ_FNAME], script_file[SZ_FNAME]
char    image[SZ_FNAME+1, MAX_STARS], im_table[SZ_FNAME+1,      MAX_STARS]
int     nstars, nimages, nentry
int     ix[MAX_STARS], iy[MAX_STARS]
int     fd
int     i
real    x[MAX_STARS], y[MAX_STARS]
real    dx[MAX_IMAGES], dy[MAX_IMAGES]
real    sigx[MAX_IMAGES], sigy[MAX_IMAGES]

int     open()

begin
        # Get coordinate file name
        call clgstr ("coord_file", coord_file,  SZ_FNAME)

        # Get script file name
        call clgstr ("script_file", script_file, SZ_FNAME)

        call fseti (STDOUT, F_FLUSHNL,  YES)

        # Open  and read file
        iferr (fd = open (coord_file, READ_ONLY, TEXT_FILE))
            call error  (0, "Cannot open coordinate file")

        call gcoords (fd, ix, iy, x, y, image,  nentry)
        call close (fd)

        # Using first image, compute deltas and errors
        call deltas (x, y, image, im_table, nentry, nstars, nimages,
            dx, dy, sigx, sigy)

        # Issue status  of shifts
        call printf ("\n    dx      sigma       dy     sigma    Image\n\n")

        do i =  2, nimages {
            call printf (" %7.3f %7.3f     %7.3f %7.3f  [%s]\n")
                call pargr (dx[i])
                call pargr (sigx[i])
                call pargr (dy[i])
                call pargr (sigy[i])
                call pargstr (im_table[1,i])
        }

        # Create IMSHIFT output script
        iferr (fd = open (script_file,  NEW_FILE, TEXT_FILE))
             call error (0, "Cannot open script file")

        call mkimscript (fd, dx, dy, im_table,  nimages)
        call close (fd)

        call printf ("\nScript  file  -%s-  has been generated\n")
        call pargstr (script_file)
        call printf ("Type cl <%s to execute the script\n\n")
        call pargstr (script_file)
end

# GCOORDS -- Read the data from the coordinate file

procedure gcoords (fd, ix, iy, x, y, image, nentry)

int     fd
int     ix[ARB], iy[ARB]
real    x[ARB], y[ARB]
char    image[SZ_FNAME+1, ARB]
int     nentry

int     i, line, nargs

int     fscan(), nscan()

begin
        # Scan  the input - ignore bad records if any
        i = 0
        line =  0

        while (fscan (fd) != EOF) {
            i = i + 1
            line = line + 1

            if  (i > MAX_STARS) {
                call eprintf ("Maximum entries (500) exceeded   in coord file\n")
                i = MAX_STARS
                go to   10
            }

            call gargi  (ix[i])
            call gargi  (iy[i])
            call gargr  (x [i])
            call gargr  (y [i])
            call gargstr (image[1,i], SZ_FNAME)
            call unwhite (image[1,i])

            # If we don;t scan  a full line, ignore the line
            nargs = nscan()
            if  (nargs < 5 && nargs > 0) {
                i = i   - 1
                call eprintf ("Bad record ignored on line: %d\n")
                    call pargi (line)
            } else
                if (nargs == 0)
                    i   = i - 1
        }

10      nentry = i

end

# DELTAS -- Review the input data and compute delta positions

procedure deltas (x, y, image, im_table, nentry, nstars, nimages,
                  dx,   dy, sigx, sigy)

char    image[SZ_FNAME+1,ARB]
int     nentry, nstars, nimages
real    x[ARB], y[ARB]
real    dx[ARB], dy[ARB], sigx[ARB], sigy[ARB]

int     i, j
char    im_table[SZ_FNAME+1, ARB]
bool    match
pointer sp, x_table, y_table, index, work

bool    streq()

begin
        # First build table of  image names
        nimages = 1
        call strcpy (image[1,1], im_table[1,1], SZ_FNAME)

        do i =  2, nentry {
            match = false

            do  j = 1, nimages
                if (streq (image[1,i], im_table[1,j]))
                    match = true

            if  (! match) {
                nimages = nimages + 1
                call strcpy (image[1,i], im_table[1,nimages],   SZ_FNAME)
            }
        }

        # Now sort out  the stars in a 2-dim table, having second
        # dimension as  the image number

        if (nimages < 2)
            call error  (0, "Less than 2 images - no shifts")

        # The number of stars should be an integral multplier
        # on the number of images.
        nstars  = nentry / nimages
        if (nstars*nimages != nentry)
            call error  (0, "Inconsistent number of images and stars in file")

        call smark (sp)
        call salloc (x_table, nentry, TY_REAL)
        call salloc (y_table, nentry, TY_REAL)
        call salloc (index, nimages, TY_INT)

        # Sift  thru the stars, assuming that for every image there
        # are the same  stars in the same order in the input table

        call aclri (Memi[index], nimages)

        # For each entry, locate the image index in the image table
        do i =  1, nentry {
            j = 0
            repeat {
                j = j   + 1
            } until (streq (image[1,i], im_table[1,j]))

            Memi[index+j-1] = Memi[index+j-1] + 1

            call load_table (Memi[index+j-1], Memr[x_table], nstars,
                nimages, i, j, x)

            call load_table (Memi[index+j-1], Memr[y_table], nstars,
                nimages, i, j, y)
        }

        # Compute deltas and sigmas
        call salloc (work, nstars, TY_REAL)

        do i =  2, nimages {
            call mkdelta (i, nstars, nimages, Memi[index+i-1],  Memr[x_table],
                        dx[i], sigx[i], Memr[work])
            call mkdelta (i, nstars, nimages, Memi[index+i-1],  Memr[y_table],
                        dy[i], sigy[i], Memr[work])
        }

        call sfree (sp)
end

# LOAD_TABLE -- Loads the star position table

procedure load_table (index, table, nstars, nimages, ipos, iimage, pos)

int     index, nstars, nimages, ipos, iimage
real    table[nstars,nimages], pos[nstars]

begin
        table[index, iimage] =  pos[ipos]
end

# MKDELTA -- Compute deltas and sigmas

procedure mkdelta (iimage, nstars, nimages, index, x_table, dx, sigx, work)

int     iimage, nstars, nimages, index
real    x_table[nstars, nimages]
real    dx, sigx
real    work[ARB]

int     i, j

begin
        # Compute delta x and store in  work array
        j = 0
        do i =  1, nstars {
            j = j + 1
            work[j] = x_table[i,1] - x_table[i,iimage]
        }

        # Compute average and sigma
        call aavgr (work, nstars, dx, sigx)

end

# MKIMSCRIPT -- Generate CL script for IMSHIFT

procedure mkimscript (fd, dx, dy, image, nimages)

int     fd,     nimages
char    image[SZ_FNAME+1, ARB]
real    dx[ARB], dy[ARB]

int     i

begin
        # Make  a comment line
        call fprintf (fd, "# IMSHIFT/HEDIT script generated by  MKSHIFT\n\n")

        # Shift all images relative to  #1
        # Create new images with "s" appended
        do i =  2, nimages {
            # Generate  IMSHIFT script
            call fprintf (fd,
             "imshift (input='%s',output='%ss',xshift=%7.2f,yshift=%7.2f)\n")
                call pargstr (image[1,i])
                call pargstr (image[1,i])
                call pargr (dx[i])
                call pargr (dy[i])

            # Generate  HEDIT for XSHIFT parameter
            call fprintf (fd,
                "hedit (images='%ss',fields='xshift',value=%7.2f,")
                call pargstr (image[1,i])
                call pargr (dx[i])
            call fprintf (fd, "add=yes,verify=no,show=no)\n")

            # Generate  HEDIT for YSHIFT parameter
            call fprintf (fd,
                "hedit (images='%ss',fields='yshift',value=%7.2f,")
                call pargstr (image[1,i])
                call pargr (dy[i])
            call fprintf (fd,   "add=yes,verify=no,show=no)\n")

        }
end

# UNWHITE -- Pack white space from string.

procedure unwhite (str)

char    str[ARB]

int     i, j

begin
        i = 1
        j = 1

        while (str[i] != EOS) {
             if (!IS_WHITE (str[i])) {
                str[j] = str[i]
                j = j   + 1
            }
            i = i + 1
        }
        str[j]  = EOS
end
