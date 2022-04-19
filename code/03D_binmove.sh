#/bin/bash -l

#Renames bins so that they do not have a dot in the name
#Assumes there are two other files in the directory (depth.txt and paired.txt)

MBAT=/home/alexab/plankton2022/results/metabat
ARCHIVES=(SRR4342129 SRR4342133)

for A in ${ARCHIVES[@]}
do
cd $MBAT/$A
N=$(ls -1 | wc -l)
B=$(($N-2))
	for n in $(seq 1 $B)
	do
	mv bin3.$n bin_$n
	done
done 
