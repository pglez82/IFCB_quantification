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

testNormalFeatures<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 14)
  set.seed(7)
  IFCB_SMALL<-fread(file='../export/IFCB_SMALL.csv')
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class","Sample","roi_number","FunctionalGroup","Area_over_PerimeterSquared","Area_over_Perimeter","H90_over_Hflip","H90_over_H180","Hflip_over_H180","summedConvexPerimeter_over_Perimeter","rotated_BoundingBox_solidity"):=NULL]
  model<-train(x,y,method="rf", trControl=trainControl(method="cv",number=5))
  save(model,file="../results/IFCB_SMALL_NORMALFEAT.RData");
}