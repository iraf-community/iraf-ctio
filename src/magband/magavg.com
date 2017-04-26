# MAGAVG.COM -- magavg common. This is necessary to pass the sort table
# pointer to the comparison routine.

pointer	sd			# sort descriptor

common	/magavgcom/	sd
