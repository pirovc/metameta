version="1.1"

# Load default values (when they are not set on the configfile.yaml)
include: "scripts/default.sm"

# Set snakemake workdir variable
workdir: config["workdir"]

# Path definition for configured tools and dbs - for alternative paths use configuration file
db_path={}
tool_path={}
for tool in config["tools"]:
	db_path[tool] = config["db_alt_path"][tool] if config["db_alt_path"][tool] else config["dbdir"] + tool + "_db/"
	tool_path[tool] = config["tool_alt_path"][tool] if config["tool_alt_path"][tool] else ""

onstart:
    print("MetaMeta Pipeline v%s" % version)
    import os
    os.makedirs(config["workdir"] + "/slurmlog", exist_ok=True)

############################################################################################## 

include: "scripts/util.py"
include: "scripts/preproc.sm"
include: "scripts/dbprofile.sm"
include: "scripts/clean_files.sm"

############################################################################################## 

rule all:
	#input: expand("{sample}/metametamerge/final.metametamerge.profile.out",sample=config["samples"]) ## TARGET SAMPLES METAMETA
	input: expand("{sample}/metametamerge/eval.png",sample=config["samples"]) ## TARGET SAMPLES metametamerge_plots
include: ("scripts/metametamerge.sm")

############################################################################################## 

for t in config["tools"]:
	include: ("tools/"+t+"_db.sm")
	include: ("tools/"+t+".sm")

############################################################################################## 
