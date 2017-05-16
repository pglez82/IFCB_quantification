#This file contains functions for making a subset of the whole dataset to make some experiments.

#Path of IFCB dataset
DS_PATH<-'../export/IFCB.csv'
#Path to save a subset of the IFCB dataset
SMALL_DS_PATH<-'export/IFCB_SMALL.csv'

#This function allows us to extract a smaller dataset from the IFCB dataset
#The aim of the function is to test de CNN faster
extractSmallerDataset<-function()
{
  library(data.table)
  minExamplesPerClass<-500
  
  IFCB<-fread(file = DS_PATH)
  IFCB_ORIGINAL_CLASS<-readRDS('../IFCB.RData') #We need this for the images
  IFCB$OriginalClass <- IFCB_ORIGINAL_CLASS$OriginalClass
  #We will only use for training the CNN the examples used for training in our quantification algorithms
  training<-read.table('training_samples.csv')
  IFCB<-IFCB[IFCB$Sample %in% training$V1,]
  IFCB$Class<-factor(IFCB$Class)
  IFCB_SMALL<-IFCB[, if(.N>minExamplesPerClass) .SD, by = Class]
  IFCB_SMALL$Class<-factor(IFCB_SMALL$Class)
  
  #Create balanced dataset
  createSets <- function(x, y, num_examples){
    size <- num_examples %/% length(unique(y))
    idx <- lapply(split(seq_len(nrow(x)), y), 
                  function(.x)
                  {
                    if (length(.x)<=size)
                      .x
                    else
                      sample(.x, size)
                  })
    unlist(idx)
  }
  
  set.seed(7)
  ind <- createSets(IFCB_SMALL, IFCB_SMALL$Class, 50000)
  
  IFCB_SMALL <- IFCB_SMALL[ind,]
  fwrite(IFCB_SMALL,SMALL_DS_PATH,nThread=12)
}

