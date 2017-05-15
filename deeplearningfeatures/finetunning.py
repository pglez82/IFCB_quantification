import os
import argparse
import logging
logging.basicConfig(level=logging.DEBUG)
from common import find_mxnet
from common import data, fit, modelzoo
import mxnet as mx

def packFilesForMxnet():
	execfile("~/mxnet/tools/im2rec.py ifcb resized/train --list True --recursive True --train-ratio .8 --exts .png")
	execfile("~/mxnet/tools/im2rec.py ifcb_train.lst resized/train --pass-through True --num-thread 2")
	execfile("~/mxnet/tools/im2rec.py ifcb_val.lst resized/train --pass-through True --num-thread 2")


		
def fineTuneNetwork():
	execfile("~/mxnet/example/image-classification/fine-tune.py --pretrained-model models/resnet-18/resnet-18 --gpus 0 --data-train ../../ifcb_train.rec --data-val ../../ifcb_val.rec --load-epoch 0 --random-crop 0 --random-mirror 0 --rgb-mean 0,0,0 --num-classes 30 --model-prefix models/resnet-18c/resnet-18b --batch-size 32 --num-examples 17664 --layer-before-fullc 'flatten0'")
