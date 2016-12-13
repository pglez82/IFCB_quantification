#This function process all the downloaded images from http://dx.doi.org/10.1575/1912/7341
#We have all the information in the file and folder name. The folder name has the class
#while the file name we have: IFCB1_2006_270_170728_02023.png (unknown_year_day_time_secuencenumber
#A sample is identified by unknown_year_day_time
#Results: a file IFCB with all the information for the 3.5M images.
buildBaseData<-function()
{
  DATA_DIR<-"../data"
  files <- list.files(path=DATA_DIR, pattern="*.png", full.names=T, recursive=TRUE)
  print(paste("Read files:",length(files),". Processing..."))
  ifcb<-data.frame(matrix(NA,nrow=length(files),ncol=8))
  colnames(ifcb) <- c("Id","Year","Unknown","Day","Time","SecuenceNumber","OriginalClass","FileName")
  split<-strsplit(files, "/")
  ifcb$Year<-as.integer(sapply(split, "[[", 3))
  ifcb$OriginalClass<-factor(sapply(split, "[[", 4))
  ifcb$Id<-sapply(split, "[[", 5)
  ifcb$FileName<-files
  
  #We parse the filename because we have usefull information there
  split<-strsplit(ifcb$Id,"_")
  ifcb$Unknown<-sapply(split, "[[", 1)
  ifcb$Day<-as.integer(sapply(split, "[[", 3))
  ifcb$Time<-sapply(split, "[[", 4)
  ifcb$SecuenceNumber<-as.integer(tools::file_path_sans_ext(sapply(split, "[[", 5)))
  saveRDS(ifcb,"IFCB.RData")
  return(ifcb)
}

#This function downloads all the csv files from http://ifcb-data.whoi.edu/mvco
#The 3.5M images are part of much larger dataset (over 700M images).
#The csv contain the features already computed. Note that the samples sometimes are
#not completely classified so in the csv we will have more information than needed
downloadFeatures<-function()
{ 
  BASE_URL<-"http://ifcb-data.whoi.edu/mvco/"
  DEST_DIR<-"sample_features/"
  ifcb<-readRDS('IFCB.RData')
  #We get all the samples in the dataset
  samples<-unique(ifcb[c("Unknown","Year","Day","Time")])
  for (i in 1:nrow(samples))
  {
    fileName<-paste(samples[i,1],samples[i,2],sprintf("%03d",samples[i,3]),samples[i,4],"features.csv",sep = "_")
    urlDownload<-paste(BASE_URL,fileName,sep="")
    fileNameDest<-paste(DEST_DIR,fileName,sep="")
    download.file(url = urlDownload,quiet = TRUE,destfile = fileNameDest)
    #Check if number of examples is ok and shows progress
    data<-read.table(file = fileNameDest,sep=",",header=TRUE)
    subset<-ifcb[ifcb$Unknown==samples[i,1] & ifcb$Year==samples[i,2] & ifcb$Day==samples[i,3] & ifcb$Time==samples[i,4],]
    if (nrow(data) < nrow(subset))
      print(paste("File",fileName,"does have less number of files than images in disk.",nrow(data),"vs",nrow(subset)))
    else
      print(paste("File",fileName,"processed OK. (",nrow(data),"vs",nrow(subset),"). [",i,"of",nrow(samples),"]"))
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
  #We get all the samples in the dataset
  samples<-unique(ifcb[c("Unknown","Year","Day","Time")])
  ifcb_features<-data.frame()
  ifcb_sample_size <- data.frame()
  
  #ifcb_sample_size<-foreach (i=1:nrow(samples),.combine = 'rbind')%dopar%
  #{
  #  fileName<-paste(samples[i,1],samples[i,2],sprintf("%03d", samples[i,3]),samples[i,4],"features.csv",sep = "_")
  #  features<-read.table(file = paste(FEATURES_DIR,fileName,sep = ''),header = TRUE,sep=',')
    #Maybe we dont have all the images corresponding for all rows in features (i have asked by email why...)
  #  s<-ifcb[ifcb$Unknown==samples[i,1] & ifcb$Year==samples[i,2] & ifcb$Day == samples[i,3] & ifcb$Time == samples[i,4],'SecuenceNumber']
  #  cat(file = logFile ,append = TRUE,sep="\n",paste("Finnished file",i))    
  #  cbind(Unknown=samples[i,1],Year=samples[i,2],Day=samples[i,3],Time=samples[i,4],total.size=nrow(features),labeled.size=length(s))
  #}
  #saveRDS(ifcb_sample_size,file = 'IFCB_SAMPLE_SIZE.RData')
  #cat(file = logFile ,append = TRUE,sep="\n","Saving results, starting second part...")
  
  ifcb_features<-foreach (i=1:nrow(samples),.combine = 'rbind')%dopar%
  {
    fileName<-paste(samples[i,1],samples[i,2],sprintf("%03d", samples[i,3]),samples[i,4],"features.csv",sep = "_")
    features<-read.table(file = paste(FEATURES_DIR,fileName,sep = ''),header = TRUE,sep=',')
    #Maybe we dont have all the images corresponding for all rows in features (i have asked by email why...)
    s<-ifcb[ifcb$Unknown==samples[i,1] & ifcb$Year==samples[i,2] & ifcb$Day == samples[i,3] & ifcb$Time == samples[i,4],'SecuenceNumber']
    cat(file = logFile ,append = TRUE,sep="\n",paste("Finnished file",i))
    cbind(Unknown=samples[i,1],Year=samples[i,2],Day=samples[i,3],Time=samples[i,4],features[features$roi_number %in% s,])
  }
  
  rownames(ifcb_features)<-NULL
  saveRDS(ifcb_features,file = 'IFCB_FEATURES.RData')
}

#We compute a new column from the OriginalClass to the Auto.class following this table:
#https://beagle.whoi.edu/redmine/projects/ifcb-man/wiki/Table_of_annotation_classes
computeAutoClass<-function()
{
  library(plyr)
  classes<-read.table(file = 'classes.csv',header = TRUE,sep = ',')
  ifcb$AutoClass<-factor(mapvalues(ifcb$OriginalClass,as.character(classes$Current.Manual.Class),as.character(classes$Auto.class)))
  saveRDS(ifcb,"IFCB.RData")
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

