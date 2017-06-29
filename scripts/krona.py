#!/usr/bin/python

import argparse
import subprocess
import os

parser = argparse.ArgumentParser(description='Random metagenomic abundance profile')
parser.add_argument('-r', metavar='<result_file>', dest="res", help="Result file")
parser.add_argument('-na', metavar='<names_file>', dest="names", help="Path to names.dmp")
parser.add_argument('-no', metavar='<nodes_file>', dest="nodes", help="Path to nodes.dmp")
parser.add_argument('-o', metavar='<output_file>', dest="output", help="Output")
#parser.add_argument('-ht', metavar='<html_file>', dest="html", help="Final output Html")
args = parser.parse_args()

name_dict = {}
name_dict_rev = {}
ranks = ['phylum','class','order','family','genus','species']

#Parse taxonomy .dmp files
print("Parse names.dmp")
name_file = open(args.names, 'r')
while 1:
    line = name_file.readline()
    if line == "":
        break
    line = line.rstrip()
    line = line.replace("\t","")
    tab = line.split("|")
    if tab[3] == "scientific name":
        tid,name = tab[0],tab[1]
        name_dict[tid] = name
        name_dict_rev[name] = tid
name_file.close()

tax_and_parent = {}
tax_and_rank = {}

print("Parse nodes.dmp")
node_file = open(args.nodes, 'r')
while 1:
    line = node_file.readline()
    if line == "":
        break
    line = line.rstrip()
    line = line.replace("\t", "")
    tab = line.split("|")
    tid,pid,rank = tab[0],tab[1],tab[2]
    tax_and_parent[tid] = pid
    tax_and_rank[tid] = rank
node_file.close()

output = open(args.output, 'w')
result_file = open(args.res, 'r')

print("Parse result file")
if os.path.basename(result_file.name).startswith("final.") == True:
    for line in result_file:
        if line.split("\t")[0]!="species":
            continue
        name = ""
        tab = line.split("\t")
        res_id = name_dict_rev[tab[1].rstrip()]
        while tax_and_rank[res_id] != "superkingdom":
            if tax_and_rank[res_id] in ranks:
                name = "\t" + name_dict[res_id] + name
                res_id = tax_and_parent[res_id]
            else:
                res_id = tax_and_parent[res_id]
        name = name_dict[res_id] + name
        output.write(tab[2].rstrip() + "\t" + name + "\n")

else:
    for line in result_file:
        if line.split("\t")[0]!="species":
            continue
        name = ""
        tab = line.split("\t")
        res_id = tab[1].rstrip()
        while tax_and_rank[res_id] != "superkingdom":
            if tax_and_rank[res_id] in ranks:
                name = "\t" + name_dict[res_id] + name
                res_id = tax_and_parent[res_id]
            else:
                res_id = tax_and_parent[res_id]
        name = name_dict[res_id] + name
        output.write(tab[2].rstrip() + "\t" + name + "\n")
output.close()
result_file.close()
#subprocess.call("ktImportText -o " + args.html + " -n root " + args.output, shell = True)