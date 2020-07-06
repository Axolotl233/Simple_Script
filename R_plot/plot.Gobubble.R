
rm(list=ls())
library(tidyverse)
dataA <- as.data.frame(read.csv("test.order.csv"))
dataA <- dataA[order(dataA$Type,dataA$Fisher),]
write.csv(dataA,file="test.order.csv")

y<-factor(dataA$Function,levels = rev(dataA$Function))
x=-(log10(dataA$x.2))
ggplot(dataA,aes(x,y))+
  geom_point(aes(size=list1InGO,color=-log10(dataA$Fisher),shape=Type))+
  scale_color_gradient(low = "blue", high = "red")+ 
  labs(color=expression(-Log.q.value.),x="-LogP",y="",title="Go enrichment of Common DEGs")+
  theme_bw()+
  theme(axis.line = element_line(colour = "black"), 
        axis.text = element_text(color = "black",size = 14),
        legend.text = element_text(size = 14),
        legend.title=element_text(size=14),
        axis.title.x = element_text(size = 14))+
  scale_size_continuous(range=c(4,8))
