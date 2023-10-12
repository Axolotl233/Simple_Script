#! Rscript
args <- commandArgs(T)
#library(tidyverse)
data <- read.table(args[1])
colnames(data) <- c("depth","site_num","fre","cum","cum_pre")
data$cum_all <- 1-data$cum_pre
pdf("depth.pdf",width = 7,height = 5.72)
plot(data$depth[2:100],data$fre[2:100],xlim=c(0,100),col="blue",ylab="depth_fre")
par(new=T)
plot(data$depth[2:100],data$cum_all[2:100],xlim=c(0,100),col="red",axes = F,ylab = "")
axis(4, ylim=c(0,1),col="black")
mtext("cum_fre",side=4,col="black")
legend("top",legend=c("depth_fre","cum_fre"),text.col=c("blue","red"),
pch=c(16,16),col=c("blue","red"))
dev.off()
