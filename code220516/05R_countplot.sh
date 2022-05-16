#!/bin/bash -l

SRR129=/home/alexab/plankton2022/results/htseq_count_newid/SRR4342129/SRR4342129.counts.tsv
SRR133=/home/alexab/plankton2022/results/htseq_count_newid/SRR4342133/SRR4342133.counts.tsv
outputpng=/home/alexab/plankton2022/results/htseq_count_newid/plot.png

module load bioinfo-tools R R_packages/4.1.1

Rscript countgraph.R $SRR129 $SRR133 $outputpng
