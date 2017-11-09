#launch deeplearning training
source('deepfeatures.R')
args <- commandArgs(trailingOnly = TRUE)
print("Imprimiendo argumentos...")
print(args[1])
print(args[2])
print(args[3])
computeDeepFeatures(args[1],strtoi(args[2]),imgPath=args[3],chunkSize=10000)
