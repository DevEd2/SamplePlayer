# sampler.py - Convert raw audio samples to GB format

import sys, getopt, struct

assert str is not bytes, "Python 3 is required to run this script"

global GBSSongPointers

def ReadByte():
	return(ord(InFile.read(1)))
	
def swap(x):
	return((x & 0x0F)<<4|(x & 0xF0)>>4)

def main(argv):
	# set up stack
	global stack
	stack = []
	
	#misc vars
	inputfile = ''
	outputfile = ''
	argc = len(sys.argv)
	print("GB Sampler by DevEd")
	try:
		opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
	except getopt.GetoptError:
		print("Usage: sampler.py -i <inputfile> -o <outputfile>")
		sys.exit(2)
	
	# the above doesn't work if there are less than the expected number of arguments for some reason
	if argc != 5:
		print("Usage: sampler.py -i <inputfile> -o <outputfile>")
		sys.exit()
	
	for opt, arg in opts:
		if opt == '-h':
			print("Usage: sampler.py -i <inputfile> -o <outputfile>")
			sys.exit()
		elif opt in ("-i", "--ifile"):
			inputfile = arg
		elif opt in ("-o", "--ofile"):
			outputfile = arg
		 
	# Start of actual code

	# open files for access
	try:
		global InFile
		InFile = open(inputfile, "rb")
	except FileNotFoundError:
		print("ERROR:", inputfile, "doesn't exist")
		sys.exit(2)
	try:
		global OutFile
		OutFile = open(outputfile, "wb")
	except:
		print("Failed to open",outputfile)
		sys.exit(2)
	print("Opened", InFile.name)
			
	z=[]
	s=0
	while 1:
		try:
			x=swap(ord(InFile.read(1))&0xf0)
			y=ord(InFile.read(1))&0xf0
			z.append(x+y)
			s=s+1
		except TypeError:
			break
	OutFile.write(bytes(z))
	print("Conversion complete.\n\nSample size:",s//1024,"\bK (",'\b'+str(s),"\b bytes)")
	if s>16384:
		print("Warning: Sample is larger than 16K.")
	
	InFile.close()
	OutFile.close()

if __name__ == "__main__":
	main(sys.argv[1:])
	
