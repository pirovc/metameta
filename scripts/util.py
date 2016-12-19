def rmTempFilesDB(folder,input): 
	cmd = "find " + folder + " " + ''.join([" ! -wholename '" + i + "'" for i in input]) + " -type f -delete -print"
	#print(cmd)
	return(cmd)

def rmEmptyFolderDB(folder):
	cmd = "find " + folder + " -type d -empty -delete -print"
	#print(cmd)
	return(cmd)

# Manual download instead of using snakemake remote function because we snakemake checks for updates on the remote files	
def download(link,output):
	cmd = "curl -L -o " + output + " " + link
	#print(cmd)
	return(cmd)
		