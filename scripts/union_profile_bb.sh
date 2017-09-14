grep -H "^[0-9]" $@ | sed 's/:/\t/1g' | sort -t$'\t' -k 2,2 | 
awk -F "\t" '{
	fn[$1];
	idx=$2"\t"$3"\t"$4"\t"$5; 
	values[idx]=values[idx]$1":"$6";"
}END{
	printf("%s\t%s\t%s\t%s\t","@@TAXID","RANK","TAXPATH","TAXPATHSN")
	for(file in fn) printf("%s\t", file)
	for(v in values){
		printf("\n%s\t", v); 
		split(values[v], file_ab, ";");
		for(fab in file_ab){split(file_ab[fab], a, ":"); ab[a[1]]=a[2]};
		for(file in fn) printf("%s\t",(file in ab) ? ab[file] : "0");
		delete ab;
	}
}'
