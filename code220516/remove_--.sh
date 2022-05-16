#!/bin/bash/ -l

ARCHIVES=(SRR4342129 SRR4342133)

for A in ${ARCHIVES[@]}
do
cd ~/plankton2022/results/fastabins/$A

for bin in bin*
do
sed "s/-//g" $bin > temp_${bin}

mv temp_${bin} $bin

done
done
