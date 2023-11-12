# JULIAN - Calculate the julian date at a given UT. No consistency check
# is made on the date, except by the year range.
# Formula from "Almanac for Computers", 1986, page B2.
# Valid from 1901 Feb 28 through AD 2099.

double procedure julian (day, month, year, ut)

int	day		# day 	(1 - 31)
int	month		# month	(1 - 12)
int	year		# year	(1901 - 2099)
double	ut		# ut 	(decimal hours)

double	rd, rm, ry, jd

begin
	# Check for year value
	if (year < 1901 || year > 2099) 
	    call error (1, "Year out of range (1901 to 2099)")

	# Convert day, month and year to double
	rd = double (day)
	rm = double (month)
	ry = double (year)
 
	# Calculate julian date
	jd = 1721013.5D0 + 367.0D0 * ry 
	jd = jd - int (7.0D0 * (ry + int ((rm + 9.0D0) / 12.0D0)) / 4.0D0)
	jd = jd + int ((275.0D0 * rm / 9.0D0)) + rd + double (ut / 24.0)
 
	# Return value
	return (jd)
end
