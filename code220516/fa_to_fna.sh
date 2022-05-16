#!/bin/bash -l

DIR=~/plankton2022/results/fastabins
ARCHIVES=(SRR4342129 SRR4342133)

for A in ${ARCHIVES[@]}
do

cd $DIR/$A

for bin in *fa
do

oldname=${bin##*/}
newname=${oldname%%.*}.fna

mv $oldname $newname

done
done
