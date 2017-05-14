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
  registerDoMC(cores = 3)
  
  #Load dataset
  IFCB_SMALL<-fread('export/IFCB_SMALL.csv')
  index_train<-read.table(file='export/IFCB_SMALL_INDEXTRAIN.csv')
  
  #train random forest with normal features
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class","Sample","OriginalClass","roi_number","FunctionalGroup","Area_over_PerimeterSquared","Area_over_Perimeter","H90_over_Hflip","H90_over_H180","Hflip_over_H180","summedConvexPerimeter_over_Perimeter","rotated_BoundingBox_solidity"):=NULL]
  model_rf<-train(x,y,method="rf",trControl=trainControl(method="cv",index = list(index_train$V1)))
  save(model_rf,file="results/IFCB_SMALL_RF.RData")
  
  #compute deeplearning features and train a svm linear
  source('deepfeatures.R')
  computeDeepFeatures(modelName = "resnet-18")
  IFCB_SMALL<-fread("features/resnet-18/deepfeatures.csv")
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class"):=NULL]
  model_deep<-train(x,y,method="svmLinear", trControl=trainControl(method="cv",index=list(index_train$V1)))
  save(model_deep,file="results/IFCB_SMALL_DEEP.RData")
  
  #fine-tunning
  computeDeepFeatures(modelName = "resnet-18b")
  IFCB_SMALL<-fread("features/resnet-18b/deepfeatures.csv")
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class"):=NULL]
  model_deep_fit<-train(x,y,method="svmLinear", trControl=trainControl(method="cv",index=list(index_train$V1)))
  save(model_deep_fit,file="results/IFCB_SMALL_DEEP_FIT.RData")
  
  
  
  
  

  
  
}