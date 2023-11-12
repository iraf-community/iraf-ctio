# Global MKPKG definitions for the CTIO package.

$set XFLAGS	= "$(XFLAGS) -p ctio"
$set XVFLAGS	= "$(XVFLAGS) -p ctio"
$set LFLAGS	= "$(LFLAGS) -p ctio"

# Uncomment and modify the following to add special file list entries for
# various machine architectures and Fortran compilers.

# $ifeq (MACH, sparc) then
# $include "ctio$lib/mkpkg.sf.sun4"
# $else $ifeq (MACH, vms) then
# $include "ctio$lib/mkpkg.sf.vms"
# $end
