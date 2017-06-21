version="1.1"

# Check for required parameters
if "samples" not in config:
	print("No samples defined on the configuration file")
elif "workdir" not in config:
	print("No working directory defined on the configuration file")
elif "dbdir" not in config:
	print("No database directory defined on the configuration file")
else:

	# Load default values (when they are not set on the configfile.yaml)
	include: "scripts/default.sm"

	# Set snakemake main workdir variable
	workdir: config["workdir"]

	# Path definition for configured tools and dbs - for alternative paths use configuration file
	db_path={}
	tool_path={}
	for tool in config["tools"]:
		db_path[tool] = config["db_alt_path"][tool] if config["db_alt_path"][tool] else config["dbdir"] + tool + "_db/"
		tool_path[tool] = config["tool_alt_path"][tool] if config["tool_alt_path"][tool] else ""

	onstart:
		import pprint, os
		# create dir for log on cluster mode (script breaks without it)
		shell("mkdir -p {config[workdir]}/clusterlog")
		print("")
		print("---------------------------------------------------------------------------------------")
		print("MetaMeta Pipeline v%s by Vitor C. Piro (vitorpiro@gmail.com, http://github.com/pirovc)" % version)
		print("---------------------------------------------------------------------------------------")
		print("Parameters:")
		for k,v in sorted(config.items()):
			print(" - " + k + ": ", end='')
			pprint.pprint(v)
		print("---------------------------------------------------------------------------------------")
		print("")
		
	def onend(msg, log):
		#Remove clusterlog folder (if empty)
		shell("rm -d {config[workdir]}/clusterlog 2> /dev/null")
		from datetime import datetime
		dtnow = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
		log_file = config["workdir"] + "/metameta_" + dtnow + ".log"
		shell("cp {log} {log_file}")
		print("")
		print("---------------------------------------------------------------------------------------")
		print(msg)
		print("Please check the main log file for more information:\n\t%s\nDetailed output and execution time for each rule can be found at:\n\t%s" % (log_file,config["workdir"] + "/SAMPLE_NAME/log/"))
		print("---------------------------------------------------------------------------------------")
		print("")
	
	onsuccess:
		onend("MetaMeta finished successfuly", log)

	onerror:
		onend("An error has occured.", log)
		
			
	############################################################################################## 

	include: "scripts/util.py"
	include: "scripts/preproc.sm"
	include: "scripts/dbprofile.sm"
	include: "scripts/clean_files.sm"

	############################################################################################## 

	rule all:
		input: expand("{sample}/metametamerge/final.metametamerge.profile.out",sample=config["samples"]) ## TARGET SAMPLES METAMETA
		#input: expand("{sample}/metametamerge/eval.png",sample=config["samples"]) ## TARGET SAMPLES metametamerge_plots
	include: ("scripts/metametamerge.sm")

	############################################################################################## 

	for t in config["tools"]:
		include: ("tools/"+t+"_db.sm")
		include: ("tools/"+t+".sm")

	############################################################################################## 
