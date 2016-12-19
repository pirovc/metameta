# MetaMeta: Integrating metagenome analysis tools to improve taxonomic profiling

Vitor C. Piro (vitorpiro@gmail.com)

Install:
--------
Miniconda:

    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh; chmod +x Miniconda3-latest-Linux-x86_64.sh
    ./Miniconda3-latest-Linux-x86_64.sh 

MetaMeta:
	
	conda install -c bioconda metameta

* Alternatively, install MetaMeta in a separated environment with the command: ``conda create -c bioconda -n metameta metameta=1.0`` and activate it with ``source activate metameta`` (to deactivate use ``source deactivate``).
* This command will also install snakemake=3.9.0. All other tools are installed in their own environment automatically on the first run.

Run:
----

Create a configuration file (yourconfig.yaml) with the required fields (workdir, dbdir and samples):

	workdir: "/home/user/folder/results/"
	dbdir: "/home/user/folder/databases/"
	samples:
	  "sample_name_1":
	     fq1: "/home/user/folder/reads/file.1.fq"
	     fq2: "/home/user/folder/reads/file.2.fq"

* Alternatively, make a copy of the configuration file for the complete set of parameters ``cp ~/miniconda3/opt/metameta/config/example_complete.yaml yourconfig.yaml``

Check rules and output files:
	
	metameta --configfile yourconfig.yaml -np
	
Run MetaMeta:

    metameta --configfile yourconfig.yaml --use-conda --keep-going --cores 24

* The number of --cores is the total amount avaiable for the pipeline. Number of specific threads for the tools should be set on the configuration file (yourconfig.yaml) with the parameter "threads"
* On the first run MetaMeta will download and install the configured tools as well as the database files necessary for each tool.

Run MetaMeta on cluster:
------------------------	
	
The automatic integration of conda and Snakemake is still not available in cluster mode. It is then necessary to pre-install the necessary tools (recommended in a separated environment)
	
	conda create -c bioconda -n metameta metameta-all=1.0

* this command will install the following packages: metameta=1.0 snakemake=3.9.0 metametamerge=1.0 spades=3.9.0 trimmomatic=0.36 jellyfish=1.1.11 bowtie2=2.2.8 clark=1.2.3 dudes=0.07 gottcha=1.0 kaiju=1.0 kraken=0.10.5beta motus=1.0

Make a copy of the configuration file (use example_complete.yaml for a complete set of parameters) and the cluster configuration file:

    cp ~/miniconda3/opt/metameta/config/example.yaml yourconfig.yaml
	cp ~/miniconda3/opt/metameta/config/cluster.json yourcluster.json
	
Edit the file to set-up the working folders, threads, sample files, e-mail and cpu/memory for each rule:

	vim yourconfig.yaml
	vim yourcluster.json
	
Activate the environment and execute MetaMeta (slurm example):	
    
    source activate metameta # Activate MetaMeta environment
    
    metameta --configfile yourconfig.yaml --keep-going -j 999 --cluster-config yourcluster.json --cluster "sbatch --job-name {cluster.job-name} --output {cluster.output} --partition {cluster.partition} --nodes {cluster.nodes} --cpus-per-task {cluster.cpus-per-task} --mem {cluster.mem} --time {cluster.time} --mail-type {cluster.mailtype} --mail-user {cluster.mailuser}"
    
    source deactivate # Deactivate MetaMeta environment
    
* you can change the cluster commands and adapt them to your cluster system

Adding a new tool:
------------------

MetaMeta integrates profiling and binning tools and it has 6 pre-configured tools (clark, dudes, gottcha, kaiju, kraken and motus). New tools are required to use the NCBI Taxonomy structure and nomenclature/identifiers to be added to the pipeline. MetaMeta accepts BioBoxes format directly (https://github.com/bioboxes/rfc/tree/master/data-format) or a .tsv file in the following format:

- Profiling: rank, taxon name or taxid, abundance

Example:

    genus   Methanospirillum        0.0029
    genus   Thermus 0.0029
    genus   568394      0.0029
    species Arthrobacter sp. FB24   0.0835
    species 195      0.0582
    species Mycoplasma gallisepticum        0.0536


- Binning: readid, taxon name or taxid, lenght of sequence assigned

Example:

    M2|S1|R140      354     201
    M2|S1|R142      195     201
    M2|S1|R145      457425  201
    M2|S1|R146      562     201
    M2|S1|R147      1245471 201
    M2|S1|R150      354     201

MetaMeta pipeline uses Snakemake. To add a new tool to the pipeline it is necessary to create two main files described below. Replace 'newtool' with the tool identifier (lower case, no spaces, no special chars):
  
    tools/newtool.sm -> specifies how to execute the tool
      Rules:
	    - newtool_run_1[..n] -> one or more rules necessary to run the tool
		- newtool_rpt -> final rule that should output a file newtool.profile.out in an accepted output format (described above)
		
    tools/newtool_db.sm -> specifies how to download/compile the standard database/references
	  Rules:
	    - newtool_db_1[..n] -> one or more rules necessary to download and compile the database.
		- newtool_db_profile -> this rule generates automatically the database profile. It should have as an output a file (newtool.dbaccession.out) with the accession version identifier for all sequences used in the database.
		- newtool_db_check -> rule to check the required database files. It should have as an input all mandatory files that should be present to the database work properly.

Template files can be found inside the folder tools/template. Once the two files are inside the tools folder, it is necessary to add the tool identifier to the YAML configuration file.
  