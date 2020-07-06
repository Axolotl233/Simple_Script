library(ggplot2)
data <- read.table("AS-NFS.xpclr.txt",header = T)
data$order <- 1:length(data[,1])
ggplot(data,aes(x=order,y=xpclr)) + 
  geom_point(size=1.5, colour="gray20") + 
  xlab("Physical distance (window num)")+ 
  ylab("XP-CLR")+
  geom_hline(yintercept = quantile(data$xpclr, probs = c(0.95)),colour="blue",size=0.75)+
  geom_hline(yintercept = quantile(data$xpclr, probs = c(0.99)),colour="red",size=0.75)
