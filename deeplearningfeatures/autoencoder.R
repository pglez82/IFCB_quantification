#resize image dimension
dimen<-64

#Path to save a subset of the IFCB dataset
SMALL_DS_PATH<-'export/IFCB_SMALL.csv'
#Mean pixel value
MEAN_PIXEL_VALUE<-'export/MEAN_PIXEL_VALUE.RData'
#Model using a random forest with normal features
RF_NORMALFEAT_MODEL<-"results/IFCB_SMALL_NORMALFEAT.RData"
#Path to export the images in csv format for training the NN 
H2O_DS_IMAGES<-"export/IFCB_SMALL_H2O_IMAGES.csv"
#Aditional data to the images (Class, roi_number, etc)
H2O_DS_EXTRA<-"export/IFCB_SMALL_H2O_EXTRA.csv"
#Dataframe name in H2O for importing the images
H2O_DF_NAME<-"IFCB_SMALL_H2O_IMAGES.hex"
#Path to export the NN computed features
H2O_NN_FEATURES<-"export/H2O_FEATURES.csv"
#Model using the features computed by the NN
RF_NNFEAT_MODEL<-"results/IFCB_MODEL_H2O.RData"
#deep features + normal features
RF_COMBINED_MODEL<-"results/IFCB_MODEL_COMBINED.RData"


#We build a model using caret using normal features. This is the baseline result that
#we have to improve with the new features
testNormalFeatures<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 14)
  set.seed(7)
  IFCB_SMALL<-fread(file=SMALL_DS_PATH)
  y<-factor(IFCB_SMALL$Class)
  x<-IFCB_SMALL[,c("Class","Sample","OriginalClass","roi_number","FunctionalGroup","Area_over_PerimeterSquared","Area_over_Perimeter","H90_over_Hflip","H90_over_H180","Hflip_over_H180","summedConvexPerimeter_over_Perimeter","rotated_BoundingBox_solidity"):=NULL]
  model<-train(x,y,method="rf", trControl=trainControl(method="cv",number=5))
  save(model,file=RF_NORMALFEAT_MODEL)
}



#Function to compute the mean pixel value.
computeMeanPixelValue<-function()
{
  library(EBImage)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 6)
  nImages<-10000
  IFCB<-fread(SMALL_DS_PATH)
  paths<-computeImageFileNames(IFCB)
  selected<-sample(paths,nImages)
  meanpixels<-foreach (i=1:length(paths),.combine='c') %dopar%
    mean(readImage(paths[i]))
  saveRDS(mean(meanpixels),file = MEAN_PIXEL_VALUE)
}

#This parelelized function, iterates over all the images, resizes them and saves them in a csv
#prepared to be loaded in H2O cluster
preprocessImagesForH2O<-function()
{
  library(EBImage)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 6)
  
  
  IFCB<-fread(SMALL_DS_PATH)
  paths<-computeImageFileNames(IFCB)
  
  #resizedPaths<-gsub("data","resized",paths)
  #for (p in unique(dirname(resizedPaths)))
  #  dir.create(p,recursive = TRUE,showWarnings = FALSE)
  
  #Load the value of the mean pixel previously computed. Stored in mp
  mp<-readRDS(MEAN_PIXEL_VALUE)
  
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
    images<-foreach (i=chunkStart:chunkEnd,.combine='rbind',.maxcombine=chunkSize)%dopar%
    {
      print(paste("Leyendo imagen",i))
      m<-matrix(mp,nrow = dimen,ncol=dimen)
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
      #writeImage(Image(m),resizedPaths[i])
      c(originalDim,as.vector(m))
    }
    print("Saving to file...")
    res<-data.table(images[,3:ncol(images)])
    fwrite(res,file = H2O_DS_IMAGES,append = TRUE,nThread=12)
    extradata<-data.table(Class=IFCB$Class[chunkStart:chunkEnd],Sample=IFCB$Sample[chunkStart:chunkEnd],roi_number=IFCB$roi_number[chunkStart:chunkEnd],FunctionalGroup=IFCB$FunctionalGroup[chunkStart:chunkEnd],Width=images[,1],Height=images[,2])
    fwrite(extradata,file = H2O_DS_EXTRA,append = TRUE,nThread=12)
    print("Saving done")
  }
}

#Loads the data in H2O cluster prepared to be used by deep learning algorithms
loadDataH2O<-function()
{
  library(h2o)
  h2o.init(nthreads = -1, port = 54321, startH2O = FALSE,ip="pomar.aic.uniovi.es") 
  h2o.importFile(paste("/Network/Servers/pomar.aic.uniovi.es/Volumes/VTRAK/Users/pomar_pgonzalez/Documents/Tesis/IFCB/IFCB_quantification/deeplearningfeatures/",H2O_DS_IMAGES,sep=""),destination_frame = H2O_DF_NAME)
}

#Trains an autoencoder and extracts the features (one NN layer). The idea is that this
#NN layer is a representation of the images that can be used in supervised training
trainCNN<-function()
{
  #Connect to h2o load the data and train the network
  library(h2o)
  library(data.table)
  instance =  h2o.init(nthreads = -1, port = 54321, startH2O = FALSE,ip="pomar.aic.uniovi.es")
  IFCB<-h2o.getFrame(H2O_DF_NAME)
  print("Training Deep Neural Network")
  NN_model = h2o.deeplearning(
    x = 1:(dimen*dimen),
    training_frame = IFCB,
    hidden = c(500,200,100,200,500),
    epochs = 600,
    activation = "Tanh",
    autoencoder = TRUE,
    shuffle_training_data=TRUE,
    stopping_rounds=100,
    model_id = "IFCB_AUTOENCODER_MODEL"
  )
  print("Done. Computing features for images.")
  features<-h2o.deepfeatures(NN_model, IFCB, layer=3)
  features<-as.data.frame(features)
  print("Done. Saving features to csv")
  IFCB_DF<-fread(H2O_DS_EXTRA)
  features$Width<-IFCB_DF$Width
  features$Height<-IFCB_DF$Height
  features$Class<-IFCB_DF$Class
  features$Sample<-IFCB_DF$Sample
  features$roi_number<-IFCB_DF$roi_number
  fwrite(as.data.frame(features),file = H2O_NN_FEATURES,nThread=12)
  print("Done.")
}

#If we want to see how the reconstructed images look
exportReconstructedImages<-function()
{
  library(h2o)
  library(EBImage)
  h2o.init(nthreads = -1, port = 54321, startH2O = FALSE,ip="pomar.aic.uniovi.es")
  model<-h2o.getModel('IFCB_AUTOENCODER_MODEL')
  IFCB<-h2o.getFrame(H2O_DF_NAME)
  originals<-IFCB[1:5,]
  reconstructed<-as.data.frame(h2o.predict(model,originals))
  originals<-as.data.frame(originals)
  for (i in 1:nrow(originals))
  {
    writeImage(Image(matrix(originals[i,],ncol = dimen,nrow = dimen)),paste("results/original",i,".png",sep=""))
    writeImage(Image(matrix(reconstructed[i,],ncol = dimen,nrow = dimen)),paste("results/reconstructed",i,".png",sep=""))
  }
}

#With the features computed by the deep learning algorithm we train a RF caret
#model. The aim is to get a better accuracy than using the normal features
testH2OFeatures<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 15)
  set.seed(7)
  IFCB_H2O<-fread(file=H2O_NN_FEATURES)
  y<-factor(IFCB_H2O$Class)
  x<-IFCB_H2O[,c("Class","Sample","roi_number","Width","Height"):=NULL]
  model<-train(x,y,method="rf", trControl=trainControl(method="cv",number=5))
  save(model,file=RF_NNFEAT_MODEL)
}

#deep plus normal features
testCombinedFeatures<-function()
{
  library(caret)
  library(data.table)
  library(doMC)
  registerDoMC(cores = 15)
  set.seed(7)
  IFCB_H2O<-fread(file=H2O_NN_FEATURES)
  IFCB_NORMAL<-fread(file=SMALL_DS_PATH)
  y<-factor(IFCB_NORMAL$Class)
  x<-IFCB_NORMAL[,c("Class","Sample","OriginalClass","roi_number","FunctionalGroup","Area_over_PerimeterSquared","Area_over_Perimeter","H90_over_Hflip","H90_over_H180","Hflip_over_H180","summedConvexPerimeter_over_Perimeter","rotated_BoundingBox_solidity"):=NULL]
  x<-cbind(x,IFCB_H2O[,c("Class","Sample","roi_number","Width","Height"):=NULL])
  model<-train(x,y,method="rf", trControl=trainControl(method="cv",number=5))
  save(model,file=RF_COMBINED_MODEL)
}