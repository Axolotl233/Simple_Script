library(ggplot2)

p_need <- as.numeric(1)
ITEM_all_fixed <- read.csv("Normal.Fst.AS-ES.10K.0.25.windowed.weir.fst.z_trans", header = TRUE,sep ="\t")

#ITEM_all_fixed$Zdxy=as.numeric(ITEM_all_fixed$Zdxy)
#ITEM_all_fixed$ITEM=as.numeric(ITEM_all_fixed$ITEM)
ITEM_all_fixed$P=pnorm(ITEM_all_fixed[,5])

ITEM_all_fixed$ITEM=ITEM_all_fixed$WEIGHTED_FST

ITEM_flt_p_high <- ITEM_all_fixed[which(ITEM_all_fixed$P>=(1-p_need)),]

ITEM_flt_p_low <- ITEM_all_fixed[which(ITEM_all_fixed$P<p_need),]
ITEM_flt_p_low$POS <- c(1:length(ITEM_flt_p_low[,1]))
length(ITEM_flt_p_high$P)
#if ( length(ITEM_flt_p_high$P) > 1 ) {
pdf(file=paste0("Normal.Fst.AS-ES.10K.0.25.windowed.weir.fst.z_trans",".ITEM_",p_need,"high.pdf"),width=10,height=100)
ggplot(ITEM_flt_p_high, aes(x=BIN_START,y=WEIGHTED_FST)) + geom_point(size=0.5) + facet_grid(CHROM ~ . , scales='free_x') +
  #geom_ma(size=0.5, color='red',ma_fun = SMA, n = 5, linetype=1) +
  theme_classic()
#lositanITEMSmooth(ITEM_flt_p_high, p.cutoff=(p_need/5));
dev.off()
#}

quit()


ITEM_flt_p_low <- ITEM_all_fixed[which(ITEM_all_fixed$P<p_need),]

length(ITEM_flt_p_low$P)

#if ( length(ITEM_flt_p_low$P) > 1 ) {
pdf(file=paste0("Normal.Fst.AS-ES.10K.0.25.windowed.weir.fst.z_trans",".ITEM_",p_need,"low.pdf"),width=10,height=100)
ggplot(ITEM_flt_p_low, aes(x=POS,y=WEIGHTED_FST)) + geom_point(size=0.5) + theme_classic() + scale_x_continuous(breaks = NULL)
ggThemeAssistGadget(a)
#lositanITEMSmooth(ITEM_flt_p_low, p.cutoff=(p_need/5));

dev.off()
#}



quit()
