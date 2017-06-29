# Manual download instead of using snakemake remote function because we snakemake checks for updates on the remote files	
def download(link,output):
	cmd = "curl -L -o " + output + " " + link
	#cmd = "wget --no-verbose --continue --tries=5 --read-timeout=20 -O " + output + " " + link
	#print(cmd)
	return(cmd)
