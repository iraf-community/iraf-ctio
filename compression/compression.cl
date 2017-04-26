#{ Data compression package

dataio
images

package	compression

task	fitswrite	= "compression$fitswrite.cl"
task	fitsread	= "compression$fitsread.cl"

task	imcompress	= "compression$imcompress.cl"
task	imuncompress	= "compression$imuncompress.cl"

task	improc		= "compression$improc.cl"

task	_compress	= "$compress"
task	_uncompress	= "$uncompress"

hidetask improc, _compress, _uncompress

clbye()
