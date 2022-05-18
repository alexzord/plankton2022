# Usage: countgraph.R [129 counts.tsv] [133 counts.tsv] [png name]
setwd('C:/Users/brown/Documents/MobaXterm/home')

SRR434129 <- read.table('SRR4342129.counts.tsv', sep="\t")
SRR434133 <- read.table('SRR4342133.counts.tsv', sep="\t")
colnames(SRR434129) <- c('Gene', 'Count')
colnames(SRR434133) <- c('Gene', 'Count')
full <- merge(SRR434129, SRR434133, by="Gene")
genes_only <- full[-(1:5),]
colnames(genes_only) <- c('Gene', 'SR129', 'SR133')
library(dplyr)
exp_only <- filter(genes_only, SR129 > 0 | SR133 > 0)

#Get that which is only expresed in one
#srr129only<-subset(SRR434129, !(SRR434129$Gene %in% full$Gene))
#srr133only<-subset(SRR434133, !(SRR434133$Gene %in% full$Gene))
#srr129only_exp <- subset(srr129only, !(srr129only$Count == 0))
#attach(srr129only_exp)
#srr129only_exp <- srr129only_exp[order(-Count),]
#srr133only_exp <- subset(srr133only, !(srr133only$Count == 0))
#attach(srr133only_exp)
#srr133only_exp <- srr133only_exp[order(-Count),]


g1 <- subset(exp_only, 
             Gene == "436308.Nmar_1650 " | 
               Gene == "1229909.NSED_08500 " | 
               Gene == "754436.JCM19237_3093 " |
               Gene == "436308.Nmar_1308 ")

g2 <- subset(exp_only,
             Gene == '436308.Nmar_0479 ' |
               Gene  == "388739.RSK20926_006554 ")

library(ggrepel)
#png(plot_local, width = 800, height = 600)
ggplot(exp_only, aes(log10(SR129),log10(SR133))) +
  geom_point() + geom_abline(intercept = 0, slope = 1, color="red") +
  geom_point(data=g1, colour="red") +  # this adds red points
  geom_text_repel(data=g1, aes(label=Gene)) + # this adds a label for the red points
  geom_point(data=g2, colour="blue") +  # this adds blue points
  geom_text_repel(data=g2, aes(label=Gene)) # this adds a label for the blue points
  #geom_text(aes(label = Gene), size =5)
dev.off()



             