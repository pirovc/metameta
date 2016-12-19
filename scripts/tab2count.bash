#!/bin/bash

ranks=( superkingdom phylum class order family genus species )

# Sum the length of the references to each taxonomic group
rankid=0
for r in "${ranks[@]}"
do
	rankid=$((rankid + 1))
	awk -F$'\t' '{split($6,r,"|");arr[r["'"$rankid"'"]]+=$2}END{for (a in arr) print "'"$r"'" "\t" (a=="" ? "no_" "'"$r"'" : a) "\t" arr[a]}' $1
done

#awk -F$'\t' '{arr[$3]+=$2}END{for (a in arr) print "strain\t" (a=="" ? "no_strain" : a) "\t" arr[a]}' $1
