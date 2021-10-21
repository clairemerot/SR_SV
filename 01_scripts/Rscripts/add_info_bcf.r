argv <- commandArgs(T)
ANNOT<- argv[1]

annot<-read.table(ANNOT)[,1:3]
colnames(annot)<-c("CHROM","POS","END")

annot$SVLEN<-annot$END-annot$POS
write.table(annot[,c(1,2,4)], paste0(ANNOT,".annot"), sep="\t", col.names=F, row.names=F, quote=F)