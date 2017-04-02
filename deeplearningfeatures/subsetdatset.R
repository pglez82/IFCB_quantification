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
  set.seed(7)
  ind <- createSets(IFCB_SMALL, IFCB_SMALL$Class, 0.008)
  #We need the detailed class in order to get the image
  IFCB<-readRDS('../IFCB.RData')
  IFCB_SMALL <- IFCB_SMALL[ind,]
  IFCB_SMALL$OriginalClass <- IFCB$OriginalClass[ind]
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
  x<-IFCB_SMALL[,c("Class","Sample","OriginalClass","roi_number","FunctionalGroup","Area_over_PerimeterSquared","Area_over_Perimeter","H90_over_Hflip","H90_over_H180","Hflip_over_H180","summedConvexPerimeter_over_Perimeter","rotated_BoundingBox_solidity"):=NULL]
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
    paths[i]<-paste("../data/",year[i],"/",IFCB$OriginalClass[i],"/",IFCB$Sample[i],"_",formatC(IFCB$roi_number[i], width=5, flag="0"),".png",sep="")
  
  return (paths)
}

preprocessImagesForH2O<-function()
{
  library(EBImage)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 6)
  
  dimen<-64
  IFCB<-fread('export/IFCB_SMALL.csv')
  paths<-computeImageFileNames(IFCB)
  #We have 3.5 million images. We cannot fit them in memory. We break the loop in parts and we save partially the data to disk
  chunkSize<-10000
  nChunks<-length(paths)%/%chunkSize
  for (chunk in 1:nChunks)
  {
    chunkStart <- (chunk-1)*chunkSize+1
    chunkEnd<-chunk*chunkSize
    print(paste("Starting to process partition",chunk,"[",chunkStart,",",chunkEnd,"]"))
    #if we are in the last chunk, compute the rest of the images
    if (chunk==nChunks) chunkEnd<-length(paths)
    images<-foreach (i=chunkStart:chunkEnd,.combine='rbind')%dopar%
    {
      print(paste("Leyendo imagen",i))
      m<-matrix(0,nrow = dimen,ncol=dimen)
      image<-readImage(paths[i])
      originalDim<-dim(image)
      print(paste("Leida",originalDim))
      if (originalDim[1]>originalDim[2])
        image<-resize(image,w = dimen)
      else
        image<-resize(image,h=dimen)
      
      startx<-(dimen-dim(image)[1])%/%2+1
      starty<-(dimen-dim(image)[2])%/%2+1
      m[startx:(startx+dim(image)[1]-1),starty:(starty+dim(image)[2]-1)]=imageData(image)
      c(originalDim,as.vector(m))
    }
    res<-data.table(Class=IFCB$Class[chunkStart:chunkEnd],Sample=IFCB$Sample[chunkStart:chunkEnd],roi_number=IFCB$roi_number[chunkStart:chunkEnd],FunctionalGroup=IFCB$FunctionalGroup[chunkStart:chunkEnd],images)
    fwrite(res,file = "export/IFCB_SMALL_H2O.csv",append = TRUE,nThread=12)
  }
}