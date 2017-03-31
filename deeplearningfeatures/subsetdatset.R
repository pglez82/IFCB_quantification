extractSmallerDataset<-function()
{
  library(data.table)
  IFCB<-fread(file = '../export/IFCB.csv')
  IFCB_SMALL<-IFCB[, if(.N>1000) .SD, by = Class]
  IFCB_SMALL$Class<-factor(IFCB_SMALL$Class)
  
  #Create balanced dataset
  createSets <- function(x, y, p){
    nr <- NROW(x)
    size <- (nr * p) %/% length(unique(y))
    idx <- lapply(split(seq_len(nr), y), function(.x) sample(.x, size))
    unlist(idx)
  }
  ind <- createSets(IFCB_SMALL, IFCB_SMALL$Class, 0.008)
  IFCB_SMALL <- IFCB_SMALL[ind,]
  fwrite(IFCB_SMALL,"../export/IFCB_SMALL.csv",nThread=12)
}