# MetaMeta: Integrating metagenome analysis tools to improve taxonomic profiling

Vitor C. Piro (vitorpiro@gmail.com)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat-square)](http://bioconda.github.io/recipes/metameta/README.html)

Install:
--------
Miniconda:

    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh # Download conda installer
    chmod +x Miniconda3-latest-Linux-x86_64.sh 	# Set permissions
    ./Miniconda3-latest-Linux-x86_64.sh 		# Execute. Make sure to "yes" to add the conda to your PATH

MetaMeta:
	
	conda install -c bioconda metameta=1.2.0

* All other tools and dependencies are installed in their own environment automatically on the first run (with `--use-conda` parameter active). 

Alternatively, install MetaMeta in a separated environment (named "metametaenv") with the command: 

	conda create -c bioconda -n metametaenv metameta=1.2.0	
	source activate metametaenv # Command to activate the environment. To deactivate use "source deactivate"

Run:
----

Create a configuration file (yourconfig.yaml) with the required fields (workdir, dbdir and samples):

	workdir: "/home/user/folder/results/"
	dbdir: "/home/user/folder/databases/"
	samples:
	  sample_name_1:
	     fq1: "/home/user/folder/reads/file.1.fq"
	     fq2: "/home/user/folder/reads/file.2.fq"

* All paths set on this file are relative to the workdir (if not absolute)

Check rules and output files:
	
	metameta --configfile yourconfig.yaml -np
	
Run MetaMeta:

	metameta --configfile yourconfig.yaml --use-conda --keep-going --cores 24

* Alternatively, make a copy of the configuration file for the complete set of parameters ``cp ~/miniconda3/opt/metameta/config/example_complete.yaml yourconfig.yaml``
* The number of `--cores` is the total amount avaiable for the pipeline. Number of specific threads for the tools should be set on the configuration file (yourconfig.yaml) with the parameter `threads`
* On the first run MetaMeta will download and install the configured tools as well as the database files (`archaea_bacteria_201503` by default - see below) necessary for each tool.

Pre-configured databases:
-------------------------

Available databases:

| Info | Date | metameta database name |
| --- | --- | --- |
| Archaea + Bacteria - RefSeq Complete Genomes | 2015-03 | `archaea_bacteria_201503` |
| Fungal + Viral - RefSeq Complete Genomes | 2017-09 | `fungal_viral_201709` |


Database availability per tool:

| database | clark | dudes | gottcha | kaiju | kraken | motus |
| --- | --- | --- | --- | --- | --- | --- |
| `archaea_bacteria_201503` | [Yes](https://zenodo.org/record/820055) | [Yes](https://zenodo.org/record/820053) | [Yes](https://zenodo.org/record/819341) | [Yes](https://zenodo.org/record/819425) | [Yes](https://zenodo.org/record/819363) | [Yes](https://zenodo.org/record/819365) |
| `fungal_viral_201709` | [Yes](https://zenodo.org/record/1044318) | [Yes](https://zenodo.org/record/1044328) | No | [Yes](https://zenodo.org/record/1044326) | [Yes](https://zenodo.org/record/1044330) | No |


Running sample data:
--------------------

	cd ~/miniconda3/opt/metameta/
	(or using environments: cd ~/miniconda3/envs/metametaenv/opt/metameta/)
	
Pre-configured Archaea and Bacteria database:
	
	./metameta --configfile sampledata/sample_data_archaea_bacteria.yaml --use-conda --keep-going --cores 6
	
Custom database (some viral reference genomes):
		
	./metameta --configfile sampledata/sample_data_custom_viral.yaml --use-conda --keep-going --cores 6

Results:

	cd sampledata/results/ 
	
Running MetaMeta on a cluster environment:
------------------------------------------	
	
Make a copy of the configuration file and the cluster configuration file:

	cp ~/miniconda3/opt/metameta/config/example_complete.yaml yourconfig.yaml
	cp ~/miniconda3/opt/metameta/config/cluster.json yourcluster.json
	
Edit those files to set-up the working directory, samples, threads and cpu/memory usage for each rule.
	
Run MetaMeta (slurm example):	

    metameta --configfile yourconfig.yaml --keep-going --use-conda -j 999 --cluster-config yourcluster.json --cluster "sbatch --job-name {cluster.job-name} --output {cluster.output} --partition {cluster.partition} --nodes {cluster.nodes} --cpus-per-task {cluster.cpus-per-task} --mem {cluster.mem} --time {cluster.time}"

* you can change the cluster command (`sbatch`) and adapt them to your cluster system.

Custom databases:
-----------------

MetaMeta uses by default Archaea and Bacteria sequences as reference database. Additionaly MetaMeta allows the creation of custom database (check "Pre-configured databases" section).

First select which databses should be used on the configuration file:

	databases:
	  - archaea_bacteria_201503
	  - custom_db

* all samples will run agains the "archaea_bacteria_201503" and the new "custom_db" databases

Second, create an entry with the path to the sequences that should be added to the custom database:
  
	custom_db:
	    clark: "sampledata/database/"
	    dudes: "sampledata/database/"
	    kaiju: "sampledata/database/"
	    kraken: "sampledata/database/"

* clark and dudes require one or more fasta files (extension .fna) with the accession.version identifier after the header ">" (e.g. ">NC_001998.1 Guinea pig Chlamydia phage, complete genome")
* kaiju requires one or more GenBank flat file (extension .gbff)
* kraken requires one or more fasta files (extension .fna) with the gi identifier on the header (e.g. ">gi|9632287|ref|NC_001998.1| Guinea pig Chlamydia phage, complete genome")

MetaMeta will compile the "custom_db" on the first run and use it as a database. After finished it is possible to delete de database definition from the configuration file for the following runs.

Creating a custom database based on NCBI genomes:
-------------------------------------------------

It is possible to create a custom database based on the set of genomes from NCBI

Download the genome_updater script:
	
	git clone https://github.com/pirovc/genome_updater
	
Download the desired database:
Example -> All fungi genomes available on refseq, fasta and GenBank formats with 6 threads:
	
	./genome_updater.sh -d "refseq" -g "fungi" -f "genomic.fna.gz,genomic.gbff.gz" -t 6 -o fungi_genomes/
	mkdir -p custom_fungi_db/clark_dudes/ custom_fungi_db/kaiju/ custom_fungi_db/kraken/
	
Extract files:
clark and dudes:

	zcat fungi_genomes/files/*.fna.gz > custom_fungi_db/clark_dudes/fungi_genomes.fna
	
kaiju:

	zcat fungi_genomes/files/*.gbff.gz > custom_fungi_db/kaiju/fungi_genomes.gbff

kraken (with header conversion to GI, old NCBI style):

	zcat fungi_genomes/files/*.fna.gz | awk '{if(substr($0, 0, 1)==">"){sep=index($0," ");acc=substr($0,2,sep-2);header=substr($0,sep+1); cmd="wget -qO - \"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id="acc"&rettype=gi\""; cmd | getline gi; close(cmd); print ">gi|" gi "|ref|" acc "| " header }else{ print $0 }}' > custom_fungi_db/kraken/fungi_genomes.fna
	
Add entry on the configuration file:

	databases:
	  - new_custom_fungi_db
	
Finally, add the path for each set of reference sequences on the configuration file:

	new_custom_fungi_db:
	    clark: "custom_fungi_db/clark_dudes/"
	    dudes: "custom_fungi_db/clark_dudes/"
	    kaiju: "custom_fungi_db/kaiju/"
	    kraken: "custom_fungi_db/kraken/"	

On the first run MetaMeta will compile the "new_custom_fungi_db" database for each configured tool. After finished it is possible to delete de database definition from the configuration file for the following runs.

Pre-install a complete environment:
-----------------------------------

	wget https://raw.githubusercontent.com/pirovc/metameta/master/envs/metameta_complete.yaml
	conda env create -f metameta_complete.yaml
	source activate metametaenv_complete

Merging final results:
----------------------

To merge final results from many samples into one final tabular file:

	(script location: ~/miniconda3/opt/metameta/scripts/ or using environments: ~/miniconda3/envs/metameta/opt/metameta/scripts/)
	./merge_final_profiles.sh workdir/samples_*/metametamerge/database/final.metametamerge.profile.out

Folder structure:
-----------------

MetaMeta can run several tools with several samples against several databases. The files on the working directory and database directory are organized in the structure below:

	WORKDIR:
		SAMPLE_1/
			TOOL_1/ (*)
				DB_1/
				DB_2/
				...
			TOOL_2/ (*)
				...
			PROFILES/
				DB_1/
					TOOL_1.profile.out
					TOOL_2.profile.out
					...
				DB_2/
					...
			METAMETAMERGE/
				DB_1/
					FINAL_PROFILE.out
					FINAL_PROFILE_KRONA.html
				DB_2/
					...
			LOG/
				DB_1/
				DB_2/
				...
			READS/ (*)
				TOOL_1.1.fq
				TOOL_1.2.fq
				TOOL_2.1.fq
				TOOL_2.2.fq
				...
		SAMPLE_2/
			...
		CLUSTERLOG/ (**)

	DBDIR:
		DB_1/
			TOOL_1_DB/
			TOOL_2_DB/
			...
			TOOL_1.dbprofile.out
			TOOL_2.dbprofile.out
			...
			LOG/
		DB_2/
			...
		LOG/

(\*) removed when keepfiles=0
(\*\*) only when running on cluster mode

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
		
	tools/newtool_db_custom.sm -> specifies how to download/compile the database/references
		Rules:
		- newtool_db_custom_1[..n] -> one or more rules necessary to compile the database.
		- newtool_db_custom_profile -> this rule generates automatically the database profile. It should have as an output a file (newtool.dbaccession.out) with the accession version identifier for all sequences used in the database.
		- newtool_db_custom_check -> rule to check the required database files. It should have as an input all mandatory files that should be present to the database work properly.

* Template files can be found inside the folder tools/template. Once the two files are inside the tools folder, it is necessary to add the tool identifier to the YAML configuration file.


NEW:
----
v1.2.0) 
- Updated to Snakemake 4.3.0 (from 3.9.1)
- Bug fixes on custom database creation and database profile generation. 
- Updated tools: kaiju 1.0 -> 1.4.5, dudes 0.07 -> 0.08, spades 3.9.0 -> 3.11.1
- Addition of new pre-configured databases: fungal_viral_201709
- Multiple pre-configured databases support
- Centralized taxonomy download

v1.1.1) Bug fixes parsing output files for kraken and kaiju

v1.1) Support single and paired-end reads, multiple and custom databases, krona integration

