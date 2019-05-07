#!/bin/bash
# Run with multiple threads: cat acc_list.txt | xargs --max-procs=24 -I '{}' bash acc2tab.bash '{}' > out.txt 2> out.err &
# tab2count.bash out.txt

# Pre-defined ranks to generate lineage
ranks=( superkingdom phylum class order family genus species )
# Number of attempst to request data from e-utils
att=10

retrieve_nucleotide_fasta_xml()
{
	echo "$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${1}&rettype=fasta&retmode=xml")"
}
retrieve_taxonomy_xml()
{
	echo "$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&id=${1}")"
}

for ACC in $1
do
	# Try to retrieve information
	for i in $(seq 1 ${att});
	do
		xml_out="$(retrieve_nucleotide_fasta_xml "${ACC}")"
		taxid="$(echo "$xml_out" | grep -m 1 -oP '(?<=TSeq_taxid>)[^<]+')"
		# If taxid was found, break
		if [[ ! -z "${taxid}" ]]; then break; fi;
	done
	# If taxid was not found, add to the error list and continue
	if [[ -z "${taxid}" ]]; 
	then 
		nucl_error="${nucl_error}${ACC}"
		continue
	fi
	# Extract sequence length 
	len="$(echo "$xml_out" | grep -m 1 -oP '(?<=TSeq_length>)[^<]+')"
	# Extract organism name and replace single quote 
	name="$(echo "$xml_out" | grep -m 1 -oP '(?<=TSeq_orgname>)[^<]+')"
	name="${name//&apos;/\'}"
	
	# Try to retrieve information
	for i in $(seq 1 ${att});
	do
		taxonomy_xml_out="$(retrieve_taxonomy_xml "${taxid}")"
		rank="$(echo "$taxonomy_xml_out" | grep -m 1 -oP '(?<=Rank>)[^<]+')"
		# If rank was found, break
		if [[ ! -z "${rank}" ]]; then break; fi;
	done
	# If rank was not found, add to the error list and continue
	if [[ -z "${rank}" ]]; 
	then 
		tax_error="${tax_error}${ACC}"
		continue
	fi
	
	# Build lineage based on pre-defined rank
	lineage_name=""
	lineage_taxid=""
	for r in "${ranks[@]}"
	do
		
		# If sequence is referenced to some pre-defined rank, add the name the lineage (not found in the xml file)
		if [ "${rank}" = "${r}" ];
		then
			lineage_name="${lineage_name}${name}|"
			lineage_taxid="${lineage_taxid}${taxid}|"
		else
			# Extract lineage and replace single quote 
			o="$(echo "$taxonomy_xml_out" | grep -m 1 -B 2 "<Rank>$r</Rank>")"
			lname="$(echo "$o" | grep -m 1 -oP '(?<=ScientificName>)[^<]+')"
			lname="${lname//&apos;/\'}"
			ltaxid="$(echo "$o" | grep -m 1 -oP '(?<=TaxId>)[^<]+')"
			lineage_name="${lineage_name}${lname}|"
			lineage_taxid="${lineage_taxid}${ltaxid}|"
		fi
	done
	# Remove last "|"
	lineage_name="${lineage_name%?}"
	lineage_taxid="${lineage_taxid%?}"

	# Print output to STDOUT
	echo ${ACC}$'\t'${len}$'\t'${name}$'\t'${taxid}$'\t'${lineage_name}$'\t'${lineage_taxid}
done

# Print errors to STDERR
if [ ! -z "${nucl_error}" ]
then
	(>&2 echo "Problems retrieving nucleotide information for the following entries: "${nucl_error}) 
fi
if [ ! -z "${tax_error}" ]
then
	(>&2 echo "Problems retrieving taxonomic information for the following entries: "${tax_error}) 
fi
