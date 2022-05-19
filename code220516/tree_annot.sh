#!/bin/bash/ -l

WD=$(pwd)
REFPATH=$1
cd $REFPATH
# Make temporary file for genome tar.gz's
echo "Organism" > $WD/genomelist.temp
ls *.gz >> $WD/genomelist.temp
cd $WD

# Clean up names to the NCBI Assembly ID level to match with summary file
touch genomelist.clean

while read line; do
if [ $line = Organism ]
then
echo "NCBI Assembly ID" >> genomelist.match
else 
echo ${line%%.*} >> genomelist.match
fi
done < genomelist.temp

# Make file list without tar.gz's to match with tree.nwk annotation
sed 's/.faa.gz//g' genomelist.temp >> genomelist.clean

# Combine files for matching
paste genomelist.match genomelist.clean > genomelist.comb

cp $REFPATH/summary* ./summary.txt

# Create file to include tree.nwk match column with summary info
touch genomelist.sum
sumhead=$(head -n 1 summary.txt)
echo -e "Accession\t$sumhead" > genomelist.sum
join -j 1 -t $'\t'  <(sort -k1 genomelist.comb) <(sort -k1 summary.txt) >> genomelist.sum

#Remove last line (remnants of summary header)
sed -i '$ d' genomelist.sum 

# Extract needed columns
cut -f 2,8 genomelist.sum > tree.annot

# Clean up
rm genomelist.match genomelist.temp genomelist.clean genomelist.comb genomelist.sum

