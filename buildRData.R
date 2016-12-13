#This function process all the downloaded images from http://dx.doi.org/10.1575/1912/7341
#We have all the information in the file and folder name. The folder name has the class
#while the file name we have: IFCB1_2006_270_170728_02023.png (intrument_year_day_time_roi_number
#A sample is identified by unknown_year_day_time
#Results: a file IFCB with all the information for the 3.5M images.
#         a file IFCB_SAMPLES with one row per sample.
buildBaseData<-function()
{
  library(plyr)
  #Put here the base directory where you have the data
  DATA_DIR<-"/home/pablo/Escritorio/PLANKTON/data"
  #list all png files
  files <- list.files(path=DATA_DIR, pattern="*.png", full.names=T, recursive=TRUE)
  print(paste("Read files:",length(files),". Processing..."))
  
  ifcb<-data.frame(matrix(NA,nrow=length(files),ncol=4))
  colnames(ifcb) <- c("Sample","roi_number","OriginalClass","AutoClass")
  
  split<-strsplit(files, "/")
  #The class should be the last directory before the name
  ifcb$OriginalClass<-factor(sapply(split, "[[", length(split[[1]])-1))
  #The last split is the file name
  fileName<-sapply(split, "[[", length(split[[1]]))
  
  #We parse the filename because we have usefull information there
  split<-strsplit(fileName,"_")
  ifcb$Sample<-factor(paste(sapply(split, "[[", 1),sapply(split, "[[", 2),sapply(split, "[[", 3),sapply(split, "[[", 4),sep="_"))
  ifcb$roi_number<-as.integer(tools::file_path_sans_ext(sapply(split, "[[", 5)))
  #Sort by sample and roi_number
  ifcb<-arrange(ifcb,Sample,roi_number)
  
  #We compute a new column from the OriginalClass to the Auto.class following this table:
  #https://beagle.whoi.edu/redmine/projects/ifcb-man/wiki/Table_of_annotation_classes
  classes<-read.table(file = 'classes.csv',header = TRUE,sep = ',')
  ifcb$AutoClass<-factor(mapvalues(ifcb$OriginalClass,as.character(classes$Current.Manual.Class),as.character(classes$Auto.class)))
  saveRDS(ifcb,"IFCB.RData")
  
  #Finally, store some information about each sample
  ifcb_samples<-data.frame(Sample=unique(ifcb$Sample),Instrument="",Year=0,Day=0,Time="")
  split<-strsplit(as.character(ifcb_samples$Sample),"_")
  ifcb_samples$Instrument<-factor(sapply(split, "[[", 1))
  ifcb_samples$Year<-factor(sapply(split, "[[", 2))
  ifcb_samples$Day<-factor(sapply(split, "[[", 3))
  ifcb_samples$Time<-as.character(sapply(split, "[[", 4))
  saveRDS(ifcb_samples,"IFCB_SAMPLES.RData")
}

#This function downloads all the csv files from http://ifcb-data.whoi.edu/mvco
#The 3.5M images are part of much larger dataset (over 700M images).
#The csv contain the features already computed. Note that the samples sometimes are
#not completely classified so in the csv we will have more information than needed
downloadFeatures<-function()
{ 
  BASE_URL<-"http://ifcb-data.whoi.edu/mvco/"
  DEST_DIR<-"sample_features/"
  samples<-readRDS('IFCB_SAMPLES.RData')
  #We get all the samples in the dataset
  for (i in 1:nrow(samples))
  {
    fileName<-paste(samples$Sample[i],"features.csv",sep = "_")
    urlDownload<-paste(BASE_URL,fileName,sep="")
    fileNameDest<-paste(DEST_DIR,fileName,sep="")
    download.file(url = urlDownload,quiet = TRUE,destfile = fileNameDest)
    
    print(paste("File",fileName,"processed OK."))
  }
}

#This function uses the csv files downloaded by downloadFeatures. The goal is to get only the 3.5M rows that we need
#and forget about the rest. This function produces two results:
#
#IFCB_SAMPLE_SIZE.RData actual sample size vs classified sample size. Useful to know which samples are complete and which are not
#IFCB_FEATURES.RData features for the 3.5M rows that we have annotated.
combineFeatures<-function() 
{
  #Load libraries
  library(doMC)
  library(foreach)
  library(itertools)
  
  registerDoMC(cores = 10) 
  
  logFile = "combineFeatures.txt"
  cat(file = logFile ,append = FALSE,sep="\n","Starting process")
  
  FEATURES_DIR<-"sample_features/"
  ifcb<-readRDS('IFCB.RData')
  ifcb_samples<-readRDS('IFCB_SAMPLES.RData')
  
  #Compute the actual size of the sample and the classified sample
  ifcb_sample_size<-foreach (i=1:nrow(ifcb_samples),.combine = 'rbind')%dopar%
  {
    fileName<-paste(ifcb_samples$Sample[i],"features.csv",sep = "_")
    features<-read.table(file = paste(FEATURES_DIR,fileName,sep = ''),header = TRUE,sep=',')
    #Maybe we dont have all the images corresponding for all rows in features
    s<-ifcb[ifcb$Sample==ifcb_samples$Sample[i],'roi_number']
    cat(file = logFile ,append = TRUE,sep="\n",paste("Finnished file",i))    
    cbind(Sample=ifcb_samples$Sample[i],total.size=nrow(features),labeled.size=length(s))
  }
  saveRDS(data.frame(ifcb_sample_size),file = 'IFCB_SAMPLE_SIZE.RData')
  cat(file = logFile ,append = TRUE,sep="\n","Saving results, starting second part...")
  
  ifcb_features<-foreach (i=1:nrow(ifcb_samples),.combine = 'rbind')%dopar%
  {
    fileName<-paste(ifcb_samples$Sample[i],"features.csv",sep = "_")
    features<-read.table(file = paste(FEATURES_DIR,fileName,sep = ''),header = TRUE,sep=',')
    #Maybe we dont have all the images corresponding for all rows in features (i have asked by email why...)
    s<-ifcb[ifcb$Sample==ifcb_samples$Sample[i],'roi_number']
    cat(file = logFile ,append = TRUE,sep="\n",paste("Finnished file",i))
    cbind(Sample=ifcb_samples$Sample[i],features[features$roi_number %in% s,])
  }
  
  rownames(ifcb_features)<-NULL
  saveRDS(ifcb_features,file = 'IFCB_FEATURES.RData')
}


computeAutoClass<-function()
{
  library(plyr)
  
}

showStatistics<-function(ifcb)
{
  library(plyr)
  counts <- ddply(ifcb, .(ifcb$Year, ifcb$Day), nrow)
  View(counts)
}
#Interesting for accessing sample statistics
#counts <- ddply(ifcb, .(ifcb$Year, ifcb$Day,ifcb$Time), nrow)
#combineFeatures()

