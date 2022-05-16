#!/bin/bash -l

COUNTPATH=/proj/genomeanalysis2022/nobackup/work/alexab/htseq_count_newid
ARCHIVES=(SRR4342129 SRR4342133)
for A in ${ARCHIVES[@]}
do
cd $COUNTPATH/$A

merged=($(ls *_M.*))

awk '{A[$1]+=$2}END{for(k in A) print k,"\011",A[k]}' ${merged[@]} | sort  > ${A}.counts.tsv

done
