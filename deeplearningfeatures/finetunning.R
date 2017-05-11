dimx<-224
dimy<-224

#Neural network to be used. Must exist a directory inside 'models' with this name.
modelName<-"resnet-18"

prepareImagesForFineTunning<-function()
{
  require(data.table)
  require(caTools)
  require(EBImage)
  require(itertools)
  require(doMC)
  #We need the function computeFileNames to process the images
  source('utils.R')
  nCores<-8
  registerDoMC(cores = nCores)
  IFCB_SMALL<-fread('export/IFCB_SMALL.csv')
  
  fileNames<-data.frame(fn=computeImageFileNames(IFCB_SMALL),stringsAsFactors=FALSE)
  fileNames$Class<-IFCB_SMALL$Class
  set.seed(7)
  fileNames$spl<-sample.split(fileNames$Class,SplitRatio=0.8)  
  
  print("Starting processing...")
  foreach(fs=isplitRows(fileNames, chunks=nCores)) %dopar%
  {
    for (i in 1:nrow(fs))
    {
      if (fs[i,3])
        path<-paste0("../../resized/train/",as.character(fs[i,2]),"/",basename(fs[i,1]))
      else
        path<-paste0("../../resized/test/",as.character(fs[i,2]),"/",basename(fs[i,1]))
      dir.create(dirname(path), showWarnings = FALSE)	
      #We have to keep the directory with the class because the program im2rec needs it.
      writeImage(preproc.image(readImage(fs[i,1]),dimx,dimy,returnImage = TRUE),path)
    }
  }
}

packFilesForMxNet<-function()
{
  #create the list (we executed this in console eventhough it could be embedded inside R.
  #We need to have mxnet compiled for python. It takes a while.
  #python ~/mxnet/tools/im2rec.py ifcb resized/train --list True --recursive True --train-ratio .8 --exts .png
  #python ~/mxnet/tools/im2rec.py ifcb_train.lst resized/train --pass-through True --num-thread 2
  #python ~/mxnet/tools/im2rec.py ifcb_val.lst resized/train --pass-through True --num-thread 2
  
}

#batch size: how many examples are used to train the CNN
get_iterator <- function(train_data, val_data, batch_size = 128) {
  data_shape = c(dimx, dimy, 3)
  train <- mx.io.ImageRecordIter(path.imgrec=train_data,batch_size=batch_size,data.shape=data_shape)
  val <- mx.io.ImageRecordIter(path.imgrec=val_data,batch_size=batch_size,data.shape=data_shape)
  return(list(train = train, val = val))
}

fineTuneCNN<-function()
{
  require(mxnet)
  #Load the data
  data  <- get_iterator("../../ifcb_train.rec","../../ifcb_val.rec",8)
  train <- data$train
  val   <- data$val
  
  #Load the CNN
  model = mx.model.load(paste("models/",modelName,"/",modelName,sep=""), iteration=0)
  
  symbol <- model$symbol
  # check symbol$arguments for layer names
  internals <- symbol$get.internals()
  outputs <- internals$outputs
  
  flatten <- internals$get.output(which(outputs == "flatten0_output"))
  
  #Num of neurons equal to num of classes in our problem (ifcb_small has 30 classes)
  new_fc <- mx.symbol.FullyConnected(data = flatten,num_hidden = 30,name = "fc1") 
  # set name to original name in symbol$arguments
  new_soft <- mx.symbol.SoftmaxOutput(data = new_fc, name = "softmax")
  # set name to original name in symbol$arguments
  
  arg_params_new <- mxnet:::mx.model.init.params(symbol = new_soft, input.shape = c(dimx, dimy, 3,8), initializer = mxnet:::mx.init.uniform(0.1), 
    ctx = mx.cpu())$arg.params
  fc1_weights_new <- arg_params_new[["fc1_weight"]]
  fc1_bias_new <- arg_params_new[["fc1_bias"]]
  
  arg_params_new <- model$arg.params
  
  arg_params_new[["fc1_weight"]] <- fc1_weights_new 
  arg_params_new[["fc1_bias"]] <- fc1_bias_new 
  
  model <- mx.model.FeedForward.create(
    symbol             = new_soft,
    X                  = train,
    eval.data          = val,
    ctx                = mx.cpu(),
    eval.metric        = mx.metric.accuracy,
    num.round          = 1,
    learning.rate      = 0.05,
    momentum           = 0.9,
    wd                 = 0.00001,
    kvstore            = "local",
    array.batch.size   = 128,
    epoch.end.callback = mx.callback.save.checkpoint("resnet-18"),
    batch.end.callback = mx.callback.log.train.metric(150),
    initializer        = mx.init.Xavier(factor_type = "in", magnitude = 2.34),
    optimizer          = "sgd",
    arg.params         = arg_params_new,
    aux.params         = model$aux.params
  )
  
  
  
}
