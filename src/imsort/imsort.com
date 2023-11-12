# IMSORT.COM -- imsort common. This is necessary since there is no way
# to pass parameters to the function called by the sorting procedure.

pointer	sd			# sort descriptor
bool	numeric			# numeric sorting ?

common	/imsortcom/	sd, numeric
