#We have to download all the autoclass results from the IFCB dashboard for the
#testing samples

#We should generate one csv for each class with the prevalence for each
#file in columns

downloadAutoClassPrevs<-function()
{
  #First we compute the samples used for testing
  training<-read.table('../../deeplearningfeatures/training_samples.csv')
  IFCB<-readRDS('../../IFCB.RData')
  samples<-data.frame(as.character(unique(IFCB$Sample)),stringsAsFactors = FALSE)
  testing<-setdiff(samples[,1],training[,1])
  base_url<-'http://ifcb-data.whoi.edu/mvco/'
  
  #Create data.table for the results
  classes<-as.character(unique(IFCB$AutoClass))
  prevs<-data.frame(matrix(0,nrow=length(testing),ncol=length(classes)))
  colnames(prevs)<-classes
  rownames(prevs)<-testing[order(testing)]
  
  for (s in 1:length(testing))
  {
    sample<-testing[s]
    print(paste0("Downloading file for: ",sample," [",s," of ",length(testing),"]"))
    csv_url<-paste0(base_url,sample,"_class_scores.csv")
    results<-read.csv(url(csv_url))
    print("Done. Processing...")
    cm<-results[,2:ncol(results)]
    for (i in 1:nrow(results))
    {
      winner<-which.max(cm[i,])
      cm[i,]<-0
      cm[i,winner]<-1
    }
    v<-colSums(cm)
    v<-v/sum(v)
    prevs[sample,names(v)]<-v
    saveRDS(prevs,file = "prevs.RData")
  }
}

downloadAutoClassPrevs()