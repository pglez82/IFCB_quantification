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
  DATA_DIR<-"../data"
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

#Function to compute the sample size as we get it from the IFCB Dashboard (http://ifcb-data.whoi.edu/mvco/)
#Result: a file with 3 columns: the first is the sample name, the second the actual size and the third
#        the annotated file size.
#Update: I got from Emily an email with the fully annotated files (FULLY_ANNOTATED.RData). If we match
#        this file with the number of examples computed by this function we get that sometimes
#        there are a few examples excluded. This examples should be put in the others category
computeSampleSizes<-function()
{
  #Load libraries for parallelizing
  library(doMC)
  library(foreach)
  library(itertools)
  
  registerDoMC(cores = 12) 
  
  #Log file
  logFile = "log_computeSampleSizes.txt"
  cat(file = logFile ,append = FALSE,sep="\n","Starting process")
  
  FEATURES_DIR<-"sample_features/"
  ifcb<-readRDS('IFCB.RData')
  ifcb_samples<-readRDS('IFCB_SAMPLES.RData')
  
  #Compute the actual size of the sample and the classified sample
  ifcb_sample_size<-foreach (i=1:nrow(ifcb_samples),.combine = 'rbind')%dopar%
  {
    fileName<-paste(ifcb_samples$Sample[i],"features.csv",sep = "_")
    features<-read.table(paste(FEATURES_DIR,fileName,sep = ''),sep=",",header=TRUE)
    #Maybe we dont have all the images corresponding for all rows in features
    s<-ifcb[ifcb$Sample==ifcb_samples$Sample[i],'roi_number']
    cat(file = logFile ,append = TRUE,sep="\n",paste("Finnished file",i))    
    data.frame(Sample=as.character(ifcb_samples$Sample[i]),total.size=nrow(features),labeled.size=length(s))
  }
  saveRDS(data.frame(ifcb_sample_size),file = 'IFCB_SAMPLE_SIZE.RData')
  cat(file = logFile ,append = TRUE,sep="\n","Saving results, starting second part...")
}

#This function is used to compute a mega file with all the examples from the fully annotated
#samples list. The result would be a file with 237 columns. The identifier of each example will be
#the sample name and the roi number.
#Note that there would be a few examples not present in IFCB.RData. This examples should be processed
#after and put into the 'other' category. #see updateIFCBFile()
combineFeatures<-function() 
{
  #Load libraries for parallelizing
  library(doMC)
  library(foreach)
  library(itertools)
  
  registerDoMC(cores = 12) 
  
  logFile = "log_combineFeatures.txt"
  cat(file = logFile ,append = FALSE,sep="\n","Starting process")
  
  FEATURES_DIR<-"sample_features/"
  ifcb_fully_annotated<-readRDS('FULLY_ANNOTATED.RData')
  
  ifcb_features<-foreach (i=1:nrow(ifcb_fully_annotated),.combine = 'rbind')%dopar%
  {
    fileName<-paste(ifcb_fully_annotated$Sample[i],"features.csv",sep = "_")
    features<-read.table(paste(FEATURES_DIR,fileName,sep = ''),sep=",",header=TRUE)
    #We have to erase this feature as there some files that have it and others that don't
    features<-features[,!names(features) %in% "summedBiovolume"]

    cat(file = logFile ,append = TRUE,sep="\n",paste("Finnished file",i))
    data.frame(Sample=as.character(ifcb_fully_annotated$Sample[i]),features)
  }
  
  cat(file = logFile ,append = TRUE,sep="\n",paste("Saving",nrow(ifcb_features)))
  saveRDS(ifcb_features,file = 'IFCB_FEATURES.RData')
}

#At this point, after calling combineFeatures, we have the final list of examples in ICBF_FEATURES.
#The problem is that IFCB file does not have the same number of examples.
#We can have examples that are in IFCB_FEATURES but not in IFCB. This examples are examples discarded
#when WHOI people were annotating. They should be placed in the 'Other' category.
updateIFCBFile<-function()
{
  library(plyr)
  #load the IFCB annotated data
  IFCB<-readRDS('IFCB.RData')
  #load the features
  IFCB_FEATURES<-readRDS('IFCB_FEATURES.RData')
  FULLY_ANNOTATED<-readRDS('FULLY_ANNOTATED.RData')
  
  #Delete the examples that do not belong from fully annotated samples
  IFCB<-IFCB[IFCB$Sample %in% FULLY_ANNOTATED$Sample,]
  #Rebuild the factor to delete the unused levels
  IFCB$Sample <- factor(IFCB$Sample)
  
  #We have to find examples in the file IFCB_FEATURES that are not in IFCB. Once, found
  #we should add them to the IFCB under the others category
  ifcb_ids<-paste(IFCB$Sample,IFCB$roi_number,sep="_")
  ifcb_features_ids<-paste(IFCB_FEATURES$Sample,IFCB_FEATURES$roi_number,sep="_")
  
  new_examples<-IFCB_FEATURES[!(ifcb_features_ids %in% ifcb_ids),c("Sample","roi_number")]
  new_examples$OriginalClass<-'Other'
  new_examples$AutoClass<-'na'
  
  #Rebuild the data.frame so it rebuilds the factors
  #We use the same sample levels for both files and rearrange the sets using this levels.
  IFCB<-data.frame(rbind(IFCB,new_examples))
  rownames(IFCB)<-NULL
  
  IFCB$Sample<-factor(IFCB$Sample,levels = FULLY_ANNOTATED$Sample)
  IFCB<-arrange(IFCB,Sample,roi_number)
  
  #Finally  save the data to a file
  saveRDS(file = "IFCB.RData",IFCB)
}

#This function creates a new class attribute that combines all the classes from the IFCB set into 6 different groups
combineClassesInFunctionalGroups<-function()
{
  library(plyr)
  ifcb<-readRDS('IFCB.RData')
  fg<-read.table(file = 'functional_groups.csv',header = TRUE,sep = ',')
  ifcb$FunctionalGroup<-factor(mapvalues(ifcb$OriginalClass,as.character(fg$Nombre.Carpeta),as.character(fg$GrupoFinal)))
  saveRDS(ifcb, file = 'IFCB.RData')
}

#We find Nan values as features in the following columns 
#"Area_over_PerimeterSquared", "Area_over_Perimeter","H90_over_Hflip", "H90_over_H180", "Hflip_over_H180", "summedConvexPerimeter_over_Perimeter", "rotated_BoundingBox_solidity"
fixNanValues<-function()
{
  IFCB_FEATURES<-readRDS('IFCB_FEATURES.RData')
  
  #Finding columns with Nan features
  #colnames(IFCB_FEATURES)[colSums(is.na(IFCB_FEATURES)) > 0]
  
  IFCB_FEATURES[is.na(IFCB_FEATURES)]=0
  saveRDS(IFCB_FEATURES, file = 'IFCB_FEATURES.RData')
}
  
#Here we should use the datatable function to quickly export the huge data file into csv
#We need the develpoment version of datatable in order to have the fwrite function
#https://github.com/Rdatatable/data.table/wiki/Installation
exportToCSV<-function()
{
  library(data.table)
  
  #load the data
  IFCB<-readRDS('IFCB.RData')
  IFCB_FEATURES<-readRDS('IFCB_FEATURES.RData')
  IFCB_SAMPLES<-readRDS('IFCB_SAMPLES.RData')
  FULLY_ANNOTATED<-readRDS('FULLY_ANNOTATED.RData')
  
  #Delete the examples that do not belong from fully annotated samples
  IFCB_SAMPLES<-IFCB_SAMPLES[IFCB_SAMPLES$Sample %in% FULLY_ANNOTATED$Sample,]
  #Rebuild the factor to delete the unused levels
  IFCB_SAMPLES$Sample <- factor(IFCB_SAMPLES$Sample)
  
  IFCB_FEATURES<-data.frame(Sample=IFCB_FEATURES$Sample,roi_number=IFCB_FEATURES$roi_number,Class=IFCB$AutoClass,IFCB_FEATURES[3:ncol(IFCB_FEATURES)])
  fwrite(IFCB_FEATURES,"IFCB.csv",nThread=12)
  fwrite(IFCB_SAMPLES,"IFCB_SAMPLES.csv")
  system("zip IFCB.zip IFCB.csv")
  system("rm IFCB.csv")
}

analyzeData<-function()
{
  IFCB<-readRDS('IFCB.RData')
  IFCB_SAMPLES<-readRDS('IFCB_SAMPLES.RData')
  FULLY_ANNOTATED<-readRDS('FULLY_ANNOTATED.RData')
  IFCB_SAMPLES<-IFCB_SAMPLES[IFCB_SAMPLES$Sample %in% FULLY_ANNOTATED$Sample,]
  IFCB_SAMPLES$Sample<-factor(IFCB_SAMPLES$Sample)
  
  
  #Show samples by year and examples
  pdf(file="plots/samplesperyear.pdf",width=6,height=4,paper='special')
  barplot(table(IFCB_SAMPLES$Year),main="Samples per year" ,xlab = "Year",ylim=c(0,200),ylab = "Number of samples")
  dev.off()
  
  #Examples by class
  pdf(file="plots/examplesperclass.pdf",width=15,height=8,paper='special')
  par(mar = c(10,4,4,2) + 0.1)
  gap.barplot(table(IFCB$AutoClass), c(400001,2450000),levels(IFCB$AutoClass),ytics = seq(from = 0,to=2700000,by = 100000),yaxlab = seq(from = 0,to=2700000,by = 100000),las=3,main="Examples per class" ,ylab = "Examples",xlab="")
  dev.off()  
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

