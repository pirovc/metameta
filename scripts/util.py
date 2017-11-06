# Manual download instead of using snakemake remote function because we snakemake checks for updates on the remote files	
def download(link,output):
	cmd = "curl -L -o " + output + " " + link
	#print(cmd)
	return(cmd)
def has_custom_db(tool):
	import os
	return True if os.path.isfile(srcdir("tools/"+tool+"_db_custom.sm")) else False
