#!/usr/bin/python3
import argparse, gzip
from itertools import islice
import numpy as np
import multiprocessing

def main():

    global args
    global readgz
    global ext
    global temp_list
    global lines
	
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', metavar='<fasta_q_files>', dest="fasta_q_files", help="fasta/fastq [.gz] single file")
    parser.add_argument('-f1', metavar='<paired1_fasta_q_files>', dest="paired1_fasta_q_files", help="first paired fasta/fastq [.gz] file")
    parser.add_argument('-f2', metavar='<paired2_fasta_q_files>', dest="paired2_fasta_q_files", help="second paired fasta/fastq[.gz] file")
    parser.add_argument('-s', '--sample-size', metavar='<sample_size>', dest="sample_size", type=float, default=0.1, help="Total amount of reads per sample. Integer value to set a specific read number (e.g. 100 -> 100 reads), float value for percentage (e.g. 0.1 -> 10%% of the reads), 1 to use the whole set (e.g. 1 -> all reads). Default: 0.1")
    parser.add_argument('-n', '--sample-number', metavar='<sample_number>', dest="sample_number", type=int, default=1, help="Number of samples. Default: 1")
    parser.add_argument('-r', '--replacement', metavar='<replacement>', dest="replacement", type=int, default=0, help="Sampling with replacement [1] or without replacement [0]. Default: 0")
    parser.add_argument('-g', '--gzip-output', metavar='<gzip_output>', dest="gzip_output", type=int, default=0, help="Output flat [0] or gziped [1] files. Default: 0")
    parser.add_argument('-o', '--output-prefix', metavar='<output_prefix>', dest="output_prefix", help="Prefix for the output files")
    args = parser.parse_args()

    main_file = args.paired1_fasta_q_files if args.paired1_fasta_q_files and args.paired2_fasta_q_files else args.fasta_q_files
    readgz = True if main_file.endswith(".gz") else False

    ############################### OPEN FILES
    if args.paired1_fasta_q_files and args.paired2_fasta_q_files:
        f = gzip.open(args.paired1_fasta_q_files, 'rb') if readgz else open(args.paired1_fasta_q_files,'r')
        f2 = gzip.open(args.paired2_fasta_q_files, 'rb') if readgz else open(args.paired2_fasta_q_files,'r')
    else:
        f = gzip.open(args.fasta_q_files, 'rb') if readgz else open(args.fasta_q_files,'r')

    ############################### DEFINE FILE TYPE
    if f.read(1)==">": #fasta
        lines = 2
        ext = ".fa"
    else: #fastq
        lines = 4
        ext = ".fq"
    f.seek(0)
    
    ############################### COUNT LINES
    try: # LINUX - faster
        import subprocess
        if readgz:
            cmd = "zcat " + main_file + " | wc -l"
        else:
            cmd = "wc -l " + main_file
        seqs = int(subprocess.getoutput(cmd).split()[0])//lines
    except: # general
        seqs = sum(1 for line in f)//lines
        f.seek(0)

    ############################### VALIDATION
    if ((args.sample_size>1 and args.sample_size*args.sample_number>seqs and not args.replacement) or
            (args.sample_size<1 and args.sample_size*args.sample_number>1 and not args.replacement) or
            args.sample_number>seqs):
        print("There is not enough sequences to create the requested sub-samples")
        return 1

    ############################### CREATE LISTS
    # sample size, create a list with all reads and shuffle it
    seq_list = list(range(0,seqs))
    np.random.shuffle(seq_list)
    temp_list = []
    if args.sample_size==1: # Use the whole set
        split_value = seqs//args.sample_number
    else: # Use specific part of the set
        split_value = int(seqs * args.sample_size) if args.sample_size<1 else int(args.sample_size)

    cont=0
    for i in range(args.sample_number):
        # Get part of the list
        temp_list.append(np.sort(list(islice(seq_list, split_value*cont,split_value*(cont+1)))))
        cont+=1
        # Re-shuffle in the case replacement is requested
        if args.replacement and args.sample_size!=1:
            np.random.shuffle(seq_list)
            cont=0 #Go back to the start of the list for the cases that sample_number*sample_size > number of reads
    ## Add remainder to the last list (if using the whole set)
    if args.sample_size==1: temp_list[-1] = np.sort(np.concatenate((temp_list[-1],list(islice(seq_list, split_value*cont,None)))))
    
	# Add gzip to output
    if args.gzip_output: ext = ext + ".gz"
	
    # Write files in parallel
	# Open pool
    pool_size = args.sample_number * 2 if args.paired1_fasta_q_files and args.paired2_fasta_q_files else args.sample_number
    pool = multiprocessing.Pool(pool_size)
    pool.map(write_files, list(range(pool_size)))
	
    f.close()
    if args.paired1_fasta_q_files and args.paired2_fasta_q_files: f2.close()
	
def write_files(s):
	forward = s%2 == 0
	# Read input files
	if args.paired1_fasta_q_files and args.paired2_fasta_q_files:
		if forward:
			file = gzip.open(args.paired1_fasta_q_files, 'rt') if readgz else open(args.paired1_fasta_q_files,'r')
		else:
			file = gzip.open(args.paired2_fasta_q_files, 'rt') if readgz else open(args.paired2_fasta_q_files,'r')
	else:
		file = gzip.open(args.fasta_q_files, 'rt') if readgz else open(args.fasta_q_files,'r')
	# Open output files
	if args.paired1_fasta_q_files and args.paired2_fasta_q_files:
		if forward:
			file_name = args.output_prefix + "_" + str(s//2) + ".1" + ext
			file_out = gzip.open(file_name, 'wt') if args.gzip_output else open(file_name, 'w')
		else:
			file_name = args.output_prefix + "_" + str(s//2) + ".2" + ext
			file_out = gzip.open(file_name, 'wt') if args.gzip_output else open(file_name, 'w')
	else:
		file_name = args.output_prefix + "_" + str(s) + ext
		file_out = gzip.open(file_name, 'wt') if args.gzip_output else open(file_name, 'w')

	pointer_pos = 0
	for read_pos in temp_list[s//2]:
		file_out.write(''.join(list(islice(file, int((read_pos-pointer_pos)*lines), int((read_pos-pointer_pos+1)*lines)))))
		pointer_pos = read_pos+1
	file.close()
	file_out.close()
	
if __name__ == "__main__":
    main()
