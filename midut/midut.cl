# Sets the header parameter midut to the ut at the  midpoint of the exposure
# according to the prescription suggested by Frank Valdes.

procedure midut (images)

string	images		{prompt="List of images to edit"}

string	keywrd		{"midut", prompt="keyword to use for mid exposure time"}
string	ut		{"ut",  prompt="keyword containing starting ut"}
string	exptime		{"exptime", prompt="exposure time keyword"}

begin
	string	tmp, key, expresion

	tmp = mktemp ("tmp")
	files (images, > tmp)

	key = keywrd

	hedit ("@"//tmp, key, 0., add+, ver-, show-)
	expresion = "("//ut//")"
	hedit ("@"//tmp, key, expresion, add+, ver-, show-)
	expresion = "(mod ("//key//"+"//exptime//"/7200.,24.))"
	hedit ("@"//tmp, key, expresion, add+, ver-, show-)
	
	delete (tmp, ver-)
end
