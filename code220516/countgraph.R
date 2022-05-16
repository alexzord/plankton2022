# Usage: countgraph.R [129 counts.tsv] [133 counts.tsv] [png name]

args <- commandArgs(trailingOnly = TRUE)

SRR434129 <- read.table(args[1], sep="\t")
SRR434133 <- read.table(args[2], sep="\t")
colnames(SRR434129) <- c('Gene', 'Count')
colnames(SRR434133) <- c('Gene', 'Count')
full <- merge(SRR434129, SRR434133, by="Gene")
genes_only <- full[-(1:5),]
colnames(genes_only) <- c('Gene', 'SR129', 'SR133')
library(dplyr)
exp_only <- filter(genes_only, SR129 > 0 | SR133 > 0)

#ggplot(exp_only, aes(SR129,SR133)) +
#  geom_point() +
#  geom_text(aes(label = Gene))

g1 <- subset(exp_only, Gene == "436308.Nmar_1650 " | Gene == "1229909.NSED_08500 " | Gene == "754436.JCM19237_3093 " | Gene == "436308.Nmar_1308 ")

library(ggrepel)
png(args[3], width = 800, height = 600)
ggplot(exp_only, aes(log10(SR129),log10(SR133))) +
  geom_point() + geom_abline(intercept = 0, slope = 1, color="red") +
  geom_point(data=g1, colour="red") +  # this adds a red point
  geom_text_repel(data=g1, aes(label=Gene)) # this adds a label for the red point
  #+ geom_text(aes(label = Gene), size =2)
dev.off()



             
