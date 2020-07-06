rm(list=ls())
library(tidyverse)
PA <- function(x){
  dataA <- as.data.frame(read.table(x))
  dataA[,3] = apply(dataA,1,mean)
  dataF <- subset(dataA,dataA$V3 != 0)
  jud1 <-  dataF[,3] < 0
  jud2 <- dataF[,3]> 0

  dataT1 <- dataF[jud2,] 
  dataT2 <- dataF[jud1,]
  
  nameA <- gsub(".lcf.final.txt","",x)

  dataT1[,4] <- c("rigth")
  dataT2[,4] <- c("left")

  dataF <- rbind(dataT1,dataT2)
  a <- ggplot(dataF,aes(x=dataF$V3,fill=dataF$V4))+
    geom_histogram(binwidth = 0.5,colour= "black",position = "identity",boundary=0)+
    labs(x="Log2Foldchang",y="Gene count",title = nameA)+
    theme_bw()+
    guides(fill=FALSE)
  return(a)
}

a <- PA("LG01-LG02.lcf.final.txt")
b <- PA("LG03-LG07.lcf.final.txt")
c <- PA("LG03-LG10.lcf.final.txt")
d <- PA("LG04-LG06.lcf.final.txt")
e <- PA("LG05-LG12.lcf.final.txt")
f <- PA("LG08-LG13.lcf.final.txt")
g <- PA("LG09-LG11.lcf.final.txt")
library(patchwork)
z <- a+b+c+d+e+f+g
z