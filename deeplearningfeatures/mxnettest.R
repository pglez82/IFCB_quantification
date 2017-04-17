preproc.image <- function(im) {
  # crop the image
  im<-toRGB(im)
  shape <- dim(im)
  short.edge <- min(shape[1:2])
  xx <- floor((shape[1] - short.edge) / 2)
  yy <- floor((shape[2] - short.edge) / 2)
  cropped<-im[(1+xx):(shape[1]-xx),(1+yy):(shape[2]-yy),]
  # resize to 224 x 224, needed by input of the model.
  resized <- resize(cropped, 224, 224)
  # convert to array (x, y, channel)
  arr <- round(as.array(resized) * 255)
  dim(arr) <- c(224, 224, 3)
  # subtract the mean
  normed <- arr#-117
  # Reshape to format needed by mxnet (width, height, channel, num)
  dim(normed) <- c(224, 224, 3, 1)
  return(normed)
}

testPredict<-function()
{
  model = mx.model.load("models/resnet50/resnet-50", iteration=0)
  im <- load.image("models/parrots.jpg")
  normed <- preproc.image(im)
  prob <- predict(model, X=normed)
  max.idx <- max.col(t(prob))
  synsets <- readLines("models/resnet50/synset.txt")
  print(paste0("Predicted Top-class: ", synsets  [[max.idx]]))
}


model<-"resnet-50"


#imagen de prueba para probar. Esto saca los valores de cualquier capa de nuestra red. Ahora solo queda paralelizar y calcularlo en todas las imagenes
#grabarlo en un csv y probar a entrenar.
computeDeepFeatures<-function()
{
  require(EBImage)
  require(mxnet)
  require(data.table)
  require(itertools)
  require(doMC)
  source('subsetdatset.R')
  nCores<-12
  registerDoMC(cores = nCores)
  RESULTS_FILE<-paste("features/",model,"/deepfeatures.csv",sep="")
  if (file.exists(RESULTS_FILE)) file.remove(RESULTS_FILE)
  
  IFCB<-fread('export/IFCB_SMALL.csv')
  
  #Hasta que no podamos con todo...
  ###################
  #set.seed(7)
  #IFCB<-IFCB[sample(nrow(IFCB),10000),]
  fwrite(IFCB,paste("features/",model,"/normalfeatures.csv",sep=""))
  ###################
  
  fileNames<-computeImageFileNames(IFCB)
  
  #Load model
  model = mx.model.load(paste("models/",model,"/",model,sep=""), iteration=0)
  internals <- model$symbol$get.internals()
  outputs<-internals$outputs
  t<-sapply(1:length(outputs), function(x){internals$get.output(x)})
  out <- mx.symbol.Group(t)
  
  print(paste('Computing features for all the images...',length(fileNames),"images"))
  chunkSize<-1000
  nChunks<-length(fileNames)%/%chunkSize
  for (chunk in 1:nChunks)
  {
    chunkStart <- (chunk-1)*chunkSize+1
    chunkEnd<-chunk*chunkSize
    print(paste("Starting to process partition",chunk,"[",chunkStart,",",chunkEnd,"]",chunk,"/",nChunks))
    #if we are in the last chunk, compute the rest of the images
    if (chunk==nChunks) chunkEnd<-length(fileNames)
    res<-foreach(fs=isplitVector(fileNames[chunkStart:chunkEnd], chunks=nCores),.combine='rbind') %dopar%{
      executor <- mx.simple.bind(symbol=out, data=c(224,224,3,1), ctx=mx.cpu())
      mx.exec.update.arg.arrays(executor, model$arg.params, match.name=TRUE)
      mx.exec.update.aux.arrays(executor, model$aux.params, match.name=TRUE)
      t(sapply(fs,function(f)
      {
        im <- readImage(f)
        normed <- preproc.image(im)
        mx.exec.update.arg.arrays(executor, list(data=mx.nd.array(normed)), match.name=TRUE)
        mx.exec.forward(executor, is.train=FALSE)
        c(as.array(executor$ref.outputs$flatten0_output),dim(im)[1:2])
      }))
    }
    print("Saving to file...")
    res<-data.table(res,Class=IFCB$Class[chunkStart:chunkEnd])
    fwrite(res,file = RESULTS_FILE,append = TRUE)
    print("Saving done")
  }
}

testNormalFeatures<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 15)
  set.seed(7)
  IFCB_SMALL<-fread(paste("features/",model,"/normalfeatures.csv",sep=""))
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class","Sample","OriginalClass","roi_number","FunctionalGroup","Area_over_PerimeterSquared","Area_over_Perimeter","H90_over_Hflip","H90_over_H180","Hflip_over_H180","summedConvexPerimeter_over_Perimeter","rotated_BoundingBox_solidity"):=NULL]
  model<-train(x,y,method="rf", trControl=trainControl(method="cv",number=5))
  save(model,file=paste("features/",model,"/NORMAL_MODEL.RData",sep=""))
}

testDeepFeatures<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 5)
  set.seed(7)
  IFCB_SMALL<-fread(paste("features/",model,"/deepfeatures.csv",sep=""))
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class"):=NULL]
  rm(IFCB_SMALL)
  model<-train(x,y,method="svmLinear", trControl=trainControl(method="cv",number=5),tuneGrid=expand.grid(C = c(0.1,1,10)))
  save(model,file=paste("features/",model,"/DEEP_MODEL.RData",sep=""))
}