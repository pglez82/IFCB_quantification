#Dimension needed for the images in the neural network
dimx<-224
dimy<-224
#Neural network to be used. Must exist a directory inside 'models' with this name.
modelName<-"resnet-18"



#Just a test to see how predict works. It tries to perdict a dog. A network trained in Imagenet should
#be able to recognize it easily.
testPredict<-function()
{
  require(mxnet)
  require(EBImage)
  model = mx.model.load(paste("models/",modelName,"/",modelName,sep=""), iteration=0)
  im <- readImage("models/dog.jpg")
  normed <- preproc.image(im,dimx,dimy)
  prob <- predict(model, X=normed)
  max.idx <- max.col(t(prob))
  synsets <- readLines(paste("models/",modelName,"/synset.txt",sep=""))
  print(paste0("Predicted Top-class: ", synsets  [[max.idx]]))
}

#resize all images
prepareImages<-function(imgPath="../../data",destPath="../../resized",nCores=12)
{
  require(EBImage)
  require(doMC)
  require(itertools)
  #We need the function computeFileNames to process the images
  source('utils.R')
  registerDoMC(cores = nCores)
  IFCB<-readRDS('../IFCB.RData')
  fileNames<-data.frame(origin=computeImageFileNames(IFCB,imgPath=imgPath),stringsAsFactors = FALSE)
  fileNames$dest<-gsub(imgPath,destPath,fileNames$origin)
  res<-foreach(fs=isplitRows(fileNames, chunks=nCores)) %dopar%
  {
    for (i in 1:nrow(fs))
    {
      dir.create(dirname(fs[i,2]), showWarnings = FALSE,recursive=TRUE)	
      writeImage(preproc.image(readImage(fs[i,1]),dimx,dimy,returnImage = TRUE),fs[i,2])
    }
  }
}

#This function computes the deep features from one of the last layers in CNN. 
#This function is heavily paralelized. We save the progress from time to time because
#we cannot fit everything into memory. 
#The foreach loop gives data to workers and each worker processes more than one image. This avoids creating and
#destroying workers to fast.
#This function can be run paralelized nCores>1 if we want to run it in the cpu. If not, leave nCores to 1.
computeDeepFeatures<-function(modelName="resnet-18",it=0,imgPath="../../resized",chunkSize=500,nCores=1,device=mx.gpu())
{
  require(EBImage)
  require(mxnet)
  require(data.table)
  require(itertools)
  require(doMC)
  #We need the function computeFileNames to process the images
  source('utils.R')
  registerDoMC(cores = nCores)
  RESULTS_FILE<-paste("features/",modelName,"/deepfeatures.csv",sep="")
  if (file.exists(RESULTS_FILE)) file.remove(RESULTS_FILE)
  
  start.time<-Sys.time()
  
  IFCB<-readRDS('../IFCB.RData')
  
  #Hasta que no podamos con todo...
  ###################
  #set.seed(7)
  #IFCB<-IFCB[sample(nrow(IFCB),10000),]
  ###################
  
  #Load original image dims
  imagedims<-fread('imagedims.csv')  
  fileNames<-computeImageFileNames(IFCB,imgPath=imgPath)
  
  #Load model
  model = mx.model.load(paste("models/",modelName,"/",modelName,sep=""), iteration=it)
  internals <- model$symbol$get.internals()
  outputs<-internals$outputs
  t<-sapply(1:length(outputs), function(x){internals$get.output(x)})
  out <- mx.symbol.Group(t)
  
  print(paste('Computing features for all the images...',length(fileNames),"images"))
  nChunks<-length(fileNames)%/%chunkSize
  for (chunk in 1:nChunks)
  {
    chunkStart <- (chunk-1)*chunkSize+1
    chunkEnd<-chunk*chunkSize
    print(paste("Starting to process partition",chunk,"[",chunkStart,",",chunkEnd,"]",chunk,"/",nChunks))
    #if we are in the last chunk, compute the rest of the images
    if (chunk==nChunks) chunkEnd<-length(fileNames)
    res<-foreach(fs=isplitVector(fileNames[chunkStart:chunkEnd], chunks=nCores),.combine='rbind') %dopar%{
      executor <- mx.simple.bind(symbol=out, data=c(dimx,dimy,3,1), ctx=device)
      mx.exec.update.arg.arrays(executor, model$arg.params, match.name=TRUE)
      mx.exec.update.aux.arrays(executor, model$aux.params, match.name=TRUE)
      t(sapply(fs,function(f)
      {
        normed <- round(as.array(imageData(readImage(f))) * 255)#-170
        dim(normed) <- c(dimx, dimy, 3, 1)
        #normed <- preproc.image(im,dimx,dimy)
        
        mx.exec.update.arg.arrays(executor, list(data=mx.nd.array(normed)), match.name=TRUE)
        mx.exec.forward(executor, is.train=FALSE)
        round(c(as.array(executor$ref.outputs$flatten0_output)),digits=5)
      }))
    }
    print("Saving to file...")
    res<-data.table(Sample=IFCB$Sample[chunkStart:chunkEnd],
                    roi_number=IFCB$roi_number[chunkStart:chunkEnd],
                    Class=IFCB$AutoClass[chunkStart:chunkEnd],
                    FunctionalGroup=IFCB$FunctionalGroup[chunkStart:chunkEnd],res)
    fwrite(res,file = RESULTS_FILE,append = TRUE)
    print("Saving done")  
  }
  print(Sys.time() - start.time)
}


#Features computed by a CNN does not have information about size. We add this information
#to the
addImageSizeToFeatures(modelName)
{
  require(data.table)
  FEAT_FILE<-paste("features/",modelName,"/deepfeatures.csv",sep="")
  imageDims<-fread('imagedims.csv')
  features<-fread(FEAT_FILE)
  features[,V513:=imageDims$V513]
  features[,V514:=imageDims$V514]
  fwrite(file = FEAT_FILE,features)
}

#Compare normal features, with deeplearning features and with finetuned deeplearning features
#Model with  normal features
trainRF<-function()
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
}

#Compute the deep features with the CNN pased as modelN and make a training testing iteration over the data.
#This function is useful to compare between different CNNs or between different finetuning approaches.
trainDeepFeat<-function(modelN,it=0,nCores=1,device=mx.gpu())
{ 
  require(caret)
  require(data.table)
  
  #Load dataset
  IFCB_SMALL<-fread('export/IFCB_SMALL.csv')
  index_train<-read.table(file='export/IFCB_SMALL_INDEXTRAIN.csv')
  
  computeDeepFeatures(modelName = modelN,it,nCores,device)
  IFCB_SMALL<-fread(paste0("features/",modelN,"/deepfeatures.csv"))
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class","Sample","roi_number","FunctionalGroup"):=NULL]
  model_deep<-train(x,y,method="svmLinear", trControl=trainControl(method="cv",index=list(index_train$V1)))
  save(model_deep,file=paste0("results/IFCB_SMALL_DEEP",modelN,".RData"))
}