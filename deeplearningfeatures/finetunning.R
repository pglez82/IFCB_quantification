dimx<-224
dimy<-224

prepareImagesForFineTunning<-function()
{
  require(data.table)
  require(EBImage)
  require(itertools)
  require(doMC)
  #We need the function computeFileNames to process the images
  source('utils.R')
  nCores<-3
  IFCB_SMALL<-fread('export/IFCB_SMALL.csv')
  
  fileNames<-computeImageFileNames(IFCB_SMALL)
  res<-foreach(fs=isplitVector(fileNames, chunks=nCores),.combine='rbind') %dopar%{
    im <- readImage(f)
    resized<-preproc.image(im,dimx,dimy)
    writeImage(resized,paste(basename(fileNames[1]),"../../data/resized/",sep=""))
  }
}