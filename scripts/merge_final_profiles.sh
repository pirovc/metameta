grep -H "^[0-9]" $@ | sed 's/:/\t/1g' | sort -t$'\t' -k 2,2 | 
awk -F "\t" '{
	fn[$1];
	idx=$2"\t"$3"\t"$4"\t"$5; 
	values[idx]=values[idx]$1":"$6";"
}END{
	printf("%s\n%s\n%s\t%s\t%s\t%s\t","# Taxonomic Profiling Output","@Version:0.9.3","@@TAXID","RANK","TAXPATH","TAXPATHSN");
	n=asorti(fn,fn_sorted);
	for(i=1; i<=n; i++) printf("%s\t", fn_sorted[i]);
	for(v in values){
		printf("\n%s\t", v); 
		split(values[v], file_ab, ";");
		for(fab in file_ab){split(file_ab[fab], a, ":"); ab[a[1]]=a[2]};
		for(i=1; i<=n; i++) printf("%s\t",(fn_sorted[i] in ab) ? ab[fn_sorted[i]] : "0");
		delete ab;
	}
	print "";
}'
