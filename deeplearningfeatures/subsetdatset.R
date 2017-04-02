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
  save(model,file="results/IFCB_SMALL_NORMALFEAT.RData")
}

#Get the file names in order to process all the images for deep learning
computeImageFileNames<-function(IFCB)
{
  #Get the year
  year<-sapply(strsplit(IFCB$Sample,"_"),"[[",2)
  paths<-vector(length=length(year))
  for (i in 1:length(year))
    paths[i]<-paste("../data/",year[i],"/",IFCB$Class[i],"/",IFCB$Sample[i],"_",formatC(IFCB$roi_number[i], width=5, flag="0"),".png",sep="")
  
  return (paths)
}

preprocessImagesForH2O<-function()
{
  library(EBImage)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 14)
  
  dimen<-64
  IFCB<-fread('export/IFCB_SMALL.csv')
  paths<-computeImageFileNames(IFCB)
  IFCB<-IFCB[1:500,]
  paths<-paths[1:500]
  images = foreach(i=1:length(paths),.combine = 'rbind')%dopar%
  {
    m<-matrix(0,nrow = dimen,ncol=dimen)
    image<-readImage(paths[i])
    image<-resize(image,dimen)
    startx<-(dimen-dim(image)[1])%/%2+1
    starty<-(dimen-dim(image)[2])%/%2+1
    m[startx:(startx+dim(image)[1]-1),starty:(starty+dim(image)[2]-1)]=imageData(image)
    as.vector(m)
  }
  
  res<-data.table(Class=IFCB$Class,Sample=IFCB$Sample,roi_number=IFCB$roi_number,FunctionalGroup=IFCB$FunctionalGroup,images)
  fwrite(res,file = "export/IFCB_SMALL_H2O.csv")
}