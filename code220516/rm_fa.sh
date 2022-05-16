#!/bin/bash/ -l

mkdir ~/plankton2022/trash

ARCHIVES=(SRR4342129 SRR4342133)
for A in ${ARCHIVES[@]}
do
cd ~/plankton2022/results/RNA_mapping/$A

for file in *.fa.*
do
mv $file ~/plankton2022/trash

done
done
