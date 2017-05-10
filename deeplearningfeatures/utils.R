#Get the file names in order to process all the images for deep learning
computeImageFileNames<-function(IFCB)
{
  #Get the year
  year<-sapply(strsplit(IFCB$Sample,"_"),"[[",2)
  return(paste("../../data/",year,"/",IFCB$OriginalClass,"/",IFCB$Sample,"_",formatC(IFCB$roi_number, width=5, flag="0"),".png",sep=""))
}

#This function pads the image and resizes it to the desired dimension
preproc.image<-function(im,dimx,dimy)
{
  mp<-0.7019857
  m<-matrix(mp,nrow = dimx,ncol=dimy)
  originalDim<-dim(im)
  
  if(originalDim[1]>originalDim[2])
    im<-resize(im,w = dimx)
  else
    im<-resize(im,h=dimy)
  
  startx<-(dimx-dim(im)[1])%/%2+1
  starty<-(dimy-dim(im)[2])%/%2+1
  data<-imageData(im)
  m[startx:(startx+dim(im)[1]-1),starty:(starty+dim(im)[2]-1)]=imageData(im)
  im<-toRGB(as.Image(m))
  arr <- round(as.array(im) * 255)#-170
  dim(arr) <- c(dimx, dimy, 3, 1)
  return(arr)
}