#!/bin/sh

## script that filters the microbiome feature table (ASV/OTU) by total frequency and number of samples
## it works with biom files and uses the biom-format package (http://biom-format.org/index.html; https://anaconda.org/bioconda/biom-format)
## you need to tune the parameters below:
## i) type of quality score; ii) quality threshold (depends on the quality score that has been selected)

set -x

## setting the enviornmnent
currpath=$(pwd)
project_home="$HOME/deep_micro_core"
input_file="merged_results/feature-table.biom"
outdir="${project_home}/merged_results"
core=4

min_frequency=100
min_samples=10

if [ ! -d "${outdir}" ]; then
	mkdir -p ${outdir}
fi

if [ ! -d "${project_home}/tmp" ]; then
	mkdir -p ${project_home}/tmp
fi


## 1) CONVERTING FROM BIOM TO TSV
echo "convert from biom to tsv"
biom convert -i ${input_file} -o ${project_home}/tmp/feature-table.tsv --to-tsv

## 2) FILTERING (AWK)
echo "filtering"
awk -v minf="$min_frequency" -v mins="$min_samples" 'NR==1 {next} NR==2 {print; next} {sum=0; n=0; for(i=2;i<=NF;i++){sum+=$i; if($i>0)n++} if(sum>=minf && n>=mins) print}' ${project_home}/tmp/feature-table.tsv > $project_home/tmp/table.filtered.tsv

## 3) CONVERT BACK TO BIOM
echo "converting back from tsv to biom"
base_name=$(basename ${input_file})
biom convert -i $project_home/tmp/table.filtered.tsv -o $outdir/filtered_${base_name} --table-type="OTU table" --to-hdf5

## remove temporary files
echo "removing temporary folder and files"
rm -r tmp
#rm $project_home/table.filtered.tsv
#rm ${project_home}/feature-table.tsv

echo "DONE!!"
