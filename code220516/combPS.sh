#!/bin/bash -l

COUNTPATH=/proj/genomeanalysis2022/nobackup/work/alexab/htseq_count_newid
ARCHIVES=(SRR4342129 SRR4342133)
for A in ${ARCHIVES[@]}
do
cd $COUNTPATH/$A

for bin in *_P.*
do
TL=${bin##*bin_}
N=${TL%%_*}

PAIRED=bin_${N}_P.new.counts.tsv
SINGLE=bin_${N}_S.new.counts.tsv

awk '{A[$1]+=$2}END{for(k in A) print k,"\011",A[k]}' $PAIRED $SINGLE | sort -n  > bin_${N}_M.new.counts.tsv
#sort -n $PAIRED > s-${PAIRED}
#sort -n $SINGLE > s-${SINGLE}

done
done
