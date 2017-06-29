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
		print("Please check the main log file for more information:")
		print("\t" + log_file)
		print("Detailed output and execution time for each rule can be found at:")
		print("\t" + config["dbdir"] + "log/")
		print("\t" + config["workdir"] + "SAMPLE_NAME/log/")
		print("---------------------------------------------------------------------------------------")
		print("")
	
	onsuccess:
		onend("MetaMeta finished successfuly", log)

	onerror:
		onend("An error has occured.", log)
		
	############################################################################################## 

	import os.path


	include: "scripts/db.sm"
	include: "scripts/preproc.sm"
	include: "scripts/clean_files.sm"
	include: "scripts/metametamerge.sm"
	include: "scripts/util.py"
	for t in config["tools"]:
		if os.path.isfile(srcdir("tools/"+t+"_db_custom.sm")):
			include: "tools/"+t+"_db_custom.sm"
		include: ("tools/"+t+".sm")

	############################################################################################## 

	rule all:
		input: 
			clean_reads = expand("{sample}/clean_reads.done", sample=config["samples"]) ## TARGET SAMPLES CLEAN READS
	
	# Clean reads after every sample is finished
	rule clean_reads:
		input: final_profiles = expand("{{sample}}/metametamerge/{database}/final.metametamerge.profile.out", database=config["databases"])
		output: temp(touch("{sample}/clean_reads.done"))
		log: "{sample}/log/clean_reads.log"
		benchmark: "{sample}/log/clean_reads.time"
		run:
			if not config["keepfiles"]: shell("rm -rfv {wildcards.sample}/reads/ > {log} 2>&1")

	############################################################################################## 
