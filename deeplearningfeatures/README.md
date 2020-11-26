# Deep learning feature extraction

This part of the project consists on using deep learning for feature extraction on the IFCB dataset. We will try to improve the features downloaded from the IFCB DashBoard. We have tested two aproaches.

## Building an autoencoder
For this approach, we have to preprocess the images and feed them to a neural network. This image is then given to the NN as the input and also as the desired output. The idea is that the network has to learn how to representate the images without losing to much information. All the functions related with this approach are in the file autoencoder.R. We couldn't make this approach work because the innability to train a big NN.

## Transfer learning
The idea is to use a CNN already trained (for instance in the ImageNet Dataset). We feed the images to this CNN and get the outputs of a fully connected layer. These outputs are then used as features. This approach is in files **deepfeatures.R**, **finetuning.R** and **subsetdataset.R**. The steps are the following:

1. Prepare the images for being fed to the CNN. Here we have to options: 1) make a subset of 36918 images (this number can be configured) using the function `extractSmallerDataset()` in the file **subsetdataset.R** or use all the training images `extractFullDataSet()`. In either case, all the images selected here are from the years 2006, 2007 and 2008 and only from samples used for training. These images will be used after in the full experiments as training set, never for testing as results might be biased.
2. These images are processed by the function `prepareImagesForFineTunning()` in file **finetuning.R**. Here the images are squared and resized. We separate the images into training (80%) and testing (20%). This will be useful later for finetune the CNN. We want to finetune the network using only the training set and use the test set only for testing.
3. [Optional] We train an RF in order to have a baseline using the dashboard features. For that we have function `trainRF` in file **deepfeatures.R**.
4. Use a deep neural network as resnet or inception to evaluate the images. We will take the output of one of the last layers in the CNN, a fully connected one. This output will be saved as the features of the image. All this computation is done in the function `computeDeepFeatures()`. This can be done without or with finetuning involved (see next section).
5. Compare the strongness of this feature set with the traditional features obtained from the IFCB DashBoard.

We have found this approach to work quite well in a subset of the data.

An atempt to improve the former could be done adjusting the CNN to our data prior to computing deep features (fine-tuning). The steps here are the following:

1. Make the rec files for mxnet. For this we use the output of the function `prepareImagesForFineTunning()`. The commands are the following:
```bash
python ~/mxnet/tools/im2rec.py ifcb resized/train --list True --recursive True --train-ratio .8 --exts .png
python ~/mxnet/tools/im2rec.py ifcb_train.lst resized/train --pass-through True --num-thread 2
python ~/mxnet/tools/im2rec.py ifcb_val.lst resized/train --pass-through True --num-thread 2
```
Another option (when we want to use all the data) is to use all the images in train as trainset and all the images in
test as valset
```bash
python ~/mxnet/tools/im2rec.py ifcb_train resized/train --list True --recursive True --exts .png
python ~/mxnet/tools/im2rec.py ifcb_val resized/test --list True --recursive True --exts .png
python ~/mxnet/tools/im2rec.py ifcb_train.lst resized/train --pass-through True --num-thread 2
python ~/mxnet/tools/im2rec.py ifcb_val.lst resized/test --pass-through True --num-thread 2
```

2. With the rec files, we finetune the network. This is done in python, via the following command:
```bash
python ~/mxnet/example/image-classification/fine-tune.py --pretrained-model models/resnet-18/resnet-18 --gpus 0 --data-train ../../ifcb_train.rec --data-val ../../ifcb_val.rec --load-epoch 0 --random-crop 0 --random-mirror 0 --num-epochs 10 --rgb-mean 0,0,0 --num-classes 24 --model-prefix models/resnet-18-10/resnet-18-10 --batch-size 32 --num-examples 23624 --layer-before-fullc 'flatten0'
```
We have to be careful with num-classes and num-examples as they vary depending on the size of our finetuning image set. If we have used only the smaller (36918 examples), we only have 24 classes. If you have used the full training set (`extractFullDataSet()`), we will have 49 classes and 432203 examples.
3. Compute the new features using the finetuned CNN (function `computeDeepFeatures()`).
4. Test the new CNN and compare it against the off-the-shelf CNN. For that I have implemented two methods *trainRF()* and *trainDeepFeatures()*. For these methods we can use the 20% examples left appart in order to make a quick test on them.
We have seen that this method outperforms traditional features (dashboard) and of-the-shelf CNN features by 2-3% accuracy in classification. Using this new network we can now compute the features for all the examples in the dataset in order to test them in our quantification algorithms.
5. After verifying that they work, we can use the quantification library to make a full experiment.
