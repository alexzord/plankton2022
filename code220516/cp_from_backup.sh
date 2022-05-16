#!/bin/bash/ -l

ARCHIVES=(SRR4342129 SRR4342133)
mkdir ~/plankton2022/results/fastabins2

for A in ${ARCHIVES[@]}
do
cd ~/plankton2022/results/prokka/$A
mkdir ~/plankton2022/results/fastabins2/$A

for bin in $(ls)
do
cd ~/plankton2022/results/prokka/$A


cd $bin

cp ${bin}.fna ~/plankton2022/results/fastabins2/$A

done
done
