#This file contains functions for making a subset of the whole dataset to make some experiments.

#Path of IFCB dataset
DS_PATH<-'../export/IFCB.csv'
#Path to save a subset of the IFCB dataset
SMALL_DS_PATH<-'export/IFCB_SMALL.csv'

#This function allows us to extract a smaller dataset from the IFCB dataset
#The aim of the function is to test de DNN faster
extractSmallerDataset<-function()
{
  library(data.table)
  #Control the size of the dataset
  proportion<-0.008
  IFCB<-fread(file = DS_PATH)
  IFCB_SMALL<-IFCB[, if(.N>1000) .SD, by = Class]
  IFCB_SMALL$Class<-factor(IFCB_SMALL$Class)
  
  #Create balanced dataset
  createSets <- function(x, y, p){
    nr <- NROW(x)
    size <- (nr * p) %/% length(unique(y))
    idx <- lapply(split(seq_len(nr), y), function(.x) sample(.x, size))
    unlist(idx)
  }
  set.seed(7)
  ind <- createSets(IFCB_SMALL, IFCB_SMALL$Class, proportion)
  #We need the detailed class in order to get the image
  IFCB<-readRDS('../IFCB.RData')
  IFCB_SMALL <- IFCB_SMALL[ind,]
  IFCB_SMALL$OriginalClass <- IFCB$OriginalClass[ind]
  fwrite(IFCB_SMALL,SMALL_DS_PATH,nThread=12)
}

