#!/bin/bash/ -l

ProkkaDIR=/home/alexab/plankton2022/results/prokka2
code=~/plankton2022/code
ARCHIVES=(SRR4342129 SRR4342133)

touch Prokka.numbers

for A in ${ARCHIVES[@]}
do
cd $code
echo $A >> prokka.numbers 
cd $ProkkaDIR/$A
for folder in bin*
do
cd $folder
echo $folder >> $code/prokka.numbers
grep 'CDS\|tRNA' *.gff | wc -l  >> $code/prokka.numbers
grep hypothetical *.gff | wc -l >> $code/prokka.numbers
cd ..
done
done

