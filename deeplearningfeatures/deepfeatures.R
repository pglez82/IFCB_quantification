#Dimension needed for the images in the neural network
dimx<-224
dimy<-224
#Neural network to be used. Must exist a directory inside 'models' with this name.
modelName<-"resnet-18"



#Just a test to see how predict works
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

#This function computes the deep features from one of the last layers in CNN. 
#This function is heavily paralelized. We save the progress from time to time because
#we cannot fit everything into memory. 
#The foreach loop gives data to workers and each worker processes more than one image. This avoids creating and
#destroying workers to fast
computeDeepFeatures<-function()
{
  require(EBImage)
  require(mxnet)
  require(data.table)
  require(itertools)
  require(doMC)
  #We need the function computeFileNames to process the images
  source('utils.R')
  nCores<-12
  registerDoMC(cores = nCores)
  RESULTS_FILE<-paste("features/",modelName,"/deepfeatures.csv",sep="")
  if (file.exists(RESULTS_FILE)) file.remove(RESULTS_FILE)
  
  start.time<-Sys.time()
  
  #IFCB<-fread('export/IFCB_SMALL.csv')
  IFCB<-fread('../export/IFCB.csv')
  #We need the original class because the file names are based on this class
  IFCB$OriginalClass<-readRDS('../IFCB.RData')$OriginalClass  
  
  #Hasta que no podamos con todo...
  ###################
  #set.seed(7)
  #IFCB<-IFCB[sample(nrow(IFCB),10000),]
  #fwrite(IFCB,paste("features/",modelName,"/normalfeatures.csv",sep=""))
  ###################
  
  fileNames<-computeImageFileNames(IFCB)
  classes<-IFCB$Class
  rm(IFCB)
  gc()  
  
  #Load model
  model = mx.model.load(paste("models/",modelName,"/",modelName,sep=""), iteration=0)
  internals <- model$symbol$get.internals()
  outputs<-internals$outputs
  t<-sapply(1:length(outputs), function(x){internals$get.output(x)})
  out <- mx.symbol.Group(t)
  
  print(paste('Computing features for all the images...',length(fileNames),"images"))
  chunkSize<-500
  nChunks<-length(fileNames)%/%chunkSize
  for (chunk in 1:nChunks)
  {
    chunkStart <- (chunk-1)*chunkSize+1
    chunkEnd<-chunk*chunkSize
    print(paste("Starting to process partition",chunk,"[",chunkStart,",",chunkEnd,"]",chunk,"/",nChunks))
    #if we are in the last chunk, compute the rest of the images
    if (chunk==nChunks) chunkEnd<-length(fileNames)
    res<-foreach(fs=isplitVector(fileNames[chunkStart:chunkEnd], chunks=nCores),.combine='rbind') %dopar%{
      executor <- mx.simple.bind(symbol=out, data=c(dimx,dimy,3,1), ctx=mx.cpu())
      mx.exec.update.arg.arrays(executor, model$arg.params, match.name=TRUE)
      mx.exec.update.aux.arrays(executor, model$aux.params, match.name=TRUE)
      t(sapply(fs,function(f)
      {
        im <- readImage(f)
        normed <- preproc.image(im,dimx,dimy)
        mx.exec.update.arg.arrays(executor, list(data=mx.nd.array(normed)), match.name=TRUE)
        mx.exec.forward(executor, is.train=FALSE)
        c(as.array(executor$ref.outputs$flatten0_output),dim(im)[1:2]/1000)
      }))
    }
    print("Saving to file...")
    res<-data.table(res,Class=classes[chunkStart:chunkEnd])
    fwrite(res,file = RESULTS_FILE,append = TRUE)
    print("Saving done")  
  }
  print(Sys.time() - start.time)
}

#Test normal features in order to compare
testNormalFeatures<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 15)
  set.seed(7)
  IFCB_SMALL<-fread(paste("features/",modelName,"/normalfeatures.csv",sep=""))
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class","Sample","OriginalClass","roi_number","FunctionalGroup","Area_over_PerimeterSquared","Area_over_Perimeter","H90_over_Hflip","H90_over_H180","Hflip_over_H180","summedConvexPerimeter_over_Perimeter","rotated_BoundingBox_solidity"):=NULL]
  modelCaret<-train(x,y,method="rf", trControl=trainControl(method="cv",number=10,trim=TRUE,indexFinal=1:100))
  save(modelCaret,file=paste("features/",modelName,"/NORMAL_MODEL.RData",sep=""))
}

#Test deep features
testDeepFeatures<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  print("Training with deep features...")
  registerDoMC(cores = 10)
  start.time <- Sys.time()
  set.seed(7)
  IFCB_SMALL<-fread(paste("features/",modelName,"/deepfeatures.csv",sep=""))
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class"):=NULL]
  modelCaret<-train(x,y,method="svmLinear", trControl=trainControl(method="cv",number=10,verboseIter=TRUE,trim=TRUE,indexFinal=1:100))
  save(modelCaret,file=paste("features/",modelName,"/DEEP_MODEL.RData",sep=""))
  print(Sys.time() - start.time)
}