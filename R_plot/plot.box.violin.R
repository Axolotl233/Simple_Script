
rm(list=ls())
library(tidyverse)
AS2_size <- read.table("AS2_size.stat")
AS2_size[,1] <- "AS2" 
NFS5_size <- read.table("NFS5_size.stat")
NFS5_size[,1] <- "NFS5"
ES6_size <- read.table("ES6_size.stat")
ES6_size[,1] <- "ES"
data <- as.data.frame(rbind(AS2_size,NFS5_size,ES6_size))
colnames(data) <- c("loc","size")
ggplot(data=data, aes(x=loc,y=size))+geom_boxplot(aes(fill=loc))
data <- as.data.frame(read.table("SEED.txt"))
colnames(data) <- c("loc","broken")

median.quartile <- function(x){
  out <- quantile(x, probs = c(0.25,0.5,0.75))
  names(out) <- c("ymin","y","ymax")
  return(out) 
}

median.for.violin <- function(x){
  out <- quantile(x, probs = c(0.5))
  names(out) <- c("y")
  return(out)
}

ggplot(data=data, aes(x=loc,y=size))+
  geom_violin(aes(fill=loc))+theme_bw()+
  scale_fill_discrete(h= c(0,360) +15,c=100,l=100,h.start = 0)+
  stat_summary(fun.y=median.quartile,geom='line')+
  stat_summary(fun.y=median.for.violin,geom='point')
  
  
library(tidyverse)
k21 <- read.table("R_lunaria.k21.histo")
plot(datax[1:99,], type="l")
ggplot(data=dataf,aes(x=number,y=count,group=1))+
  geom_line()+
  scale_x_continuous(breaks=seq(0,50,2))

datax <- read.csv("A.csv")
datax <- datax[1:100,]
colnames(datae) <- c("number","count")
class(datax[,1])
as.numeric(as.character(datax[,"number"]))
as.numeric(levels(datax$number))[as.integer(datax$number)]