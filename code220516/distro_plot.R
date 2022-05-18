
# Get data
SRR434129 <- read.table('SRR4342129.counts.tsv', sep="\t")
SRR434133 <- read.table('SRR4342133.counts.tsv', sep="\t")
colnames(SRR434129) <- c('Gene', 'Count')
colnames(SRR434133) <- c('Gene', 'Count')

#Remove non-gene entries
SRR434129 <- SRR434129[- grep("__", SRR434129$Gene),]
SRR434133 <- SRR434133[- grep("__a", SRR434133$Gene),]
SRR434133 <- SRR434133[- grep("__n", SRR434133$Gene),]
SRR434133 <- SRR434133[- grep("__t", SRR434133$Gene),]

# Sort by count order
SRR434129 <- SRR434129[order(-SRR434129$Count),]
SRR434133 <- SRR434133[order(-SRR434133$Count),]

# Enumerate
SRR434129$Num <- seq.int(nrow(SRR434129))
SRR434133$Num <- seq.int(nrow(SRR434133))

# Plot
par(mfrow=c(2,1))
png('counts_distr.png')
plot(SRR434129$Num, log10(SRR434129$Count))
plot(SRR434133$Num, log10(SRR434133$Count))
dev.off()