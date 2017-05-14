dimx<-224
dimy<-224

prepareImagesForFineTunning<-function()
{
  require(data.table)
  require(caTools)
  require(EBImage)
  require(itertools)
  require(doMC)
  #We need the function computeFileNames to process the images
  source('utils.R')
  nCores<-2
  registerDoMC(cores = nCores)
  IFCB_SMALL<-fread('export/IFCB_SMALL.csv')
  
  fileNames<-data.frame(fn=computeImageFileNames(IFCB_SMALL),stringsAsFactors=FALSE)
  fileNames$Class<-IFCB_SMALL$Class
  set.seed(7)
  fileNames$spl<-sample.split(fileNames$Class,SplitRatio=0.8)  
  fwrite(which(fileNames$spl),file = "export/IFCB_SMALL_INDEXTRAIN.csv")
  write.table(which(fileNames$spl),file = "export/IFCB_SMALL_INDEXTRAIN.csv",col.names = FALSE,row.names = FALSE)
  
  print("Starting processing...")
  foreach(fs=isplitRows(fileNames, chunks=nCores)) %dopar%
  {
    for (i in 1:nrow(fs))
    {
      if (fs[i,3])
        path<-paste0("../../resized/train/",as.character(fs[i,2]),"/",basename(fs[i,1]))
      else
        path<-paste0("../../resized/test/",as.character(fs[i,2]),"/",basename(fs[i,1]))
      dir.create(dirname(path), showWarnings = FALSE)	
      #We have to keep the directory with the class because the program im2rec needs it.
      writeImage(preproc.image(readImage(fs[i,1]),dimx,dimy,returnImage = TRUE),path)
    }
  }
}

#Compare normal features, with deeplearning features and with finetuned deeplearning features
compareModels<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 2)
  
  #Load datasets
  IFCB_TRAIN<-fread('export/IFCB_SMALL_TRAIN.csv')
  IFCB_TEST<-fread('export/IFCB_SMALL_TEST.csv')
  
  y<-factor(IFCB_SMALL_TRAIN$Class)
  x<-IFCB_SMALL_TRAIN[,c("Class","Sample","OriginalClass","roi_number","FunctionalGroup","Area_over_PerimeterSquared","Area_over_Perimeter","H90_over_Hflip","H90_over_H180","Hflip_over_H180","summedConvexPerimeter_over_Perimeter","rotated_BoundingBox_solidity"):=NULL]
  model_rf<-train(x,y,method="rf",trControl=trainControl(method="none"))
}
