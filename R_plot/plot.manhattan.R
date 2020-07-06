rm(list=ls())

libaray(qqman)
data <- read.table("Normal.Fst.AS-ES.10K.0.25.windowed.weir.fst.z_trans.fix",head = T)
manhattan(data,col = c("gray20"),suggestiveline = -log10(1e-03))
data <- read.table("Normal.Fst.AS-NFS.10K.0.25.windowed.weir.fst.z_trans.fix",head = T)
manhattan(data,col = c("gray20"),suggestiveline = -log10(1e-03))
