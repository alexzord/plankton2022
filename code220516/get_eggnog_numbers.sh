#!/bin/bash -l

ARCHIVES=(SRR4342129 SRR4342133)
EGGPATH=/home/alexab/plankton2022/results/eggNOGmapper/

touch $EGGPATH/eggnog_summary.txt

for A in ${ARCHIVES[@]}
do
cd $EGGPATH/$A

for file in *.annotations
do

lines=($(wc -l $file))
annotations=$(expr ${lines[0]} - 8)

printf "${A}\t${file%%.*}\t${annotations}\n" >> ../eggnog_summary.txt 

done
done

