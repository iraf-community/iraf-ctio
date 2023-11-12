define  MAX_PTS         200     # Maximum number of     ring measurements
define  SZ_KEY          1       # Input key length

# T_FITRING -- Compute the coefficients of the ring dispersion
#            solution   from ring parameters: radius, z, lambda.

procedure t_fitring ()

char    ring_file[SZ_FNAME], output[SZ_FNAME], key[SZ_KEY]
int     i, nline, npts, cnpts
int     fd_out
real    coef[3], coef_err[3]
real    sigma
int     accept
pointer lambda, z, radius, sp
pointer clambda, cz, cradius, flag

int     open(), clgeti()

begin
        # Get ring input file
        call clgstr ("ringfile", ring_file, SZ_FNAME)

        # And output answer file
        call clgstr ("output",  output, SZ_FNAME)

        # Allocate space for ring data
        call smark (sp)
        call salloc (lambda, MAX_PTS, TY_REAL)
        call salloc (z      , MAX_PTS, TY_REAL)
        call salloc (radius, MAX_PTS, TY_REAL)

        # Also  save space for copies and a flag
        call salloc (flag  , MAX_PTS, TY_INT)
        call salloc (clambda, MAX_PTS,  TY_REAL)
        call salloc (cz     , MAX_PTS,  TY_REAL)
        call salloc (cradius, MAX_PTS,  TY_REAL)

        # Initialize the flag to 1 to indicate  "use the value"
        do i =  1, MAX_PTS
            Memi[flag+i-1] = 1

        # Read  the ring data
        call ring_input (ring_file, Memr[lambda], Memr[z], Memr[radius], npts)
        if (npts < 3)
            call error  (0, "Insufficient number of ring values")

        # Initialize first Guess
        call rngft0 (Memr[lambda], Memr[z], Memr[radius], coef)

        # Perform fit as many times as  user wants
        # First copy good values to temporary arrays
        repeat  {
            call copy_good (Memi[flag], Memr[lambda], Memr[clambda],
                Memr[z], Memr[cz], Memr[radius], Memr[cradius], npts,   cnpts)

            # Now use differential least-squares to find better solution
            call rngfit (Memr[clambda], Memr[cz], Memr[cradius], cnpts,
                coef,   coef_err, sigma)

            # Display solution  to user and allow rejection of points
            call show_fit (STDOUT, Memr[lambda], Memr[z], Memr[radius],
                Memi[flag], npts, coef, coef_err, sigma)

            # Get point number  to delete, re-insert or accept
            call printf ("\n")
            call clgstr ("insdel", key, SZ_KEY)

            switch (key[1]) {
                # 'd'   Delete
                case 'd':
                    call clputi ("del_line.p_max", npts)
                    nline = clgeti ("del_line")
                    Memi[flag+nline-1] = 0
                          call clputi ("del_line", 0)
                    accept = NO

                # 'i'   Insert
                case 'i':
                    call clputi ("ins_line.p_max", npts)
                    nline = clgeti ("ins_line")
                    Memi[flag+nline-1] = 1
                          call clputi ("ins_line", 0)
                    accept = NO

                # 'q'   Accept current solution
                case 'q':
                    accept = YES

                default:
                    accept = YES
            }

            # Clear parameters  to force query
            call clpstr ("insdel", ".")

        } until (accept == YES)
        iferr (fd_out = open (output, NEW_FILE, TEXT_FILE))
            call error  (0, "cannot open output file")

        call fprintf (fd_out, "%9.3f    %9.4f   %9.3f\n")
            call pargr  (coef[1])
            call pargr  (coef[2])
            call pargr  (coef[3])

        call show_fit (fd_out,  Memr[lambda], Memr[z], Memr[radius],
            Memi[flag], npts, coef, coef_err, sigma)

        call close (fd_out)

        call sfree (sp)
end

# COPY_GOOD -- Copy the undeleted points into a "good" buffer for fitting

procedure copy_good (flag, lambda, clambda, z, cz, radius, cradius,
                     npts, cnpts)

int     flag[ARB]
real    lambda[ARB], clambda[ARB]
real    z[ARB], cz[ARB]
real    radius[ARB], cradius[ARB]
int     npts, cnpts

int     i

begin
        cnpts = 0

        do i =  1, npts
            if  (flag[i] == 1) {
                cnpts            = cnpts + 1
                clambda[cnpts] = lambda[i]
                cz       [cnpts] = z     [i]
                cradius[cnpts] = radius[i]
            }
end

# RING_INPUT -- Read ring data from file

procedure ring_input (ring_file, lambda, z, radius, npts)

char    ring_file[SZ_FNAME]
real    lambda[ARB]
real    z[ARB]
real    radius[ARB]
int     npts

int     fd,     i

int     open(), fscan()

begin
        # Open  input file
        iferr (fd = open (ring_file, READ_ONLY, TEXT_FILE))
            call error  (0, "Cannot find ring file")

        i = 0
        while (fscan (fd) != EOF) {
            i = i + 1
            call gargr  (lambda[i])
            call gargr  (z[i])
            call gargr  (radius[i])
        }

        call close (fd)
        npts =  i
end

# SHOW_FIT -- Display fit to the ring data, on file specified

procedure show_fit (fd, lambda, z, radius, flag, npts, coef, coef_err, sigma)

int     fd
int     npts
int     flag[ARB]
real    lambda[ARB], z[ARB], radius[ARB]
real    coef[3], coef_err[3]
real    sigma

int     i
real    lamfit, resid

real    cos(), atan2()

begin
        call fprintf (fd, "\n       Fabry-Perot Calibration Ring Fit\n\n")
        call fprintf (fd, "Lambda = (A  + B*z) * Cos [Arctan (radius/C)]\n\n")

        call fprintf (fd, "          A = %9.3f   +/-   %9.3f\n")
            call pargr  (coef[1])
            call pargr  (coef_err[1])

        call fprintf (fd, "          B = %9.4f   +/-   %9.4f\n")
            call pargr  (coef[2])
            call pargr  (coef_err[2])

        call fprintf (fd, "          C = %9.2f   +/-   %9.2f\n\n")
            call pargr  (coef[3])
            call pargr  (coef_err[3])

        call fprintf (fd, "          Standard deviation of the fit: %6.3f\n\n")
            call pargr  (sigma)

        call fprintf (fd,
            "    Line     Z      Radius     Lambda     Lam-Fit   Residual\n\n")

        do i =  1, npts {
            lamfit = (coef[1] + coef[2]*z[i]) * cos (atan2 (radius[i],  coef[3]))
            resid  = lambda[i]  - lamfit

            call fprintf (fd,
                "  %3d%s   %6.3f   %7.2f   %9.3f   %9.3f   %6.3f %s\n")
                call pargi (i)

                # Note deleted lines with a 'd'
                if (flag[i] == 1)
                    call pargstr (" ")
                else
                    call pargstr ("d")

                call pargr (z[i])
                call pargr (radius[i])
                call pargr (lambda[i])
                call pargr (lamfit)
                call pargr (resid)

                if (flag[i] == 1)
                    call pargstr (" ")
                else
                    call pargstr ("<-- deleted")
        }
end
