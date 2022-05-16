#!/bin/bash
#SBATCH -A uppmax2022-2-5 -M snowy
#SBATCH -p core
#SBATCH -n 1
#SBATCH -J metaphl
#SBATCH -t 01:00:00


ARCHIVES=(SRR4342129 SRR4342133)
OUTPATH=/proj/genomeanalysis2022/nobackup/work/alexab/cleangff
SRCPATH=/home/alexab/plankton2022/results/eggNOGmapper

mkdir $OUTPATH

for A in ${ARCHIVES[@]}; do
cd $SNIC_TMP
mkdir $A
cd $A
cp $SRCPATH/$A/*.seed_orthologs $SRCPATH/$A/*.gff .

mkdir $OUTPATH/$A

for seed in *.seed_orthologs
do
sed '/^#/d' $seed | awk -F" " '{ print $1,$2 }' > contig_name.txt 

filename=${seed##*/}
binname=${filename%%.*}

while IFS= read -r line; do
list=($line)
query=${list[0]}
contig=${query%_*}
elem=${query##*_}

newid="ID=${list[1]}"

oldid=$(cat ${binname}.fa.emapper.gff | awk -v c=$contig -F" " '{if($1==c) print $9}' | awk -F";" '{ print $1 }' | awk -v e=$elem -F"_" '{if($2==e) print $0}')

sed -i "s/${oldid}/${newid}/g" ${binname}.fa.emapper.gff

done < contig_name.txt

rm sed*
rm contig_name.txt

cp ${binname}.fa.emapper.gff ${binname}.newid.gff

done

cp *.newid.gff $OUTPATH/$A

done

