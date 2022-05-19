library(CoverageView)

args <- commandArgs(trailingOnly = TRUE)

bam <- args[1]
bed <- args[2]
out <- args[3]

trm<-CoverageBamFile(bam)

covmatrix<-cov.matrix(trm,coordfile=bed, no_windows=10,num_cores=2, bin_width=10)
draw.profile(covmatrix,ylab="avg coverage",outfile=out,main=bam)
