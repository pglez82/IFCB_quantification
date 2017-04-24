# Deep learning feature extraction

This part of the project consists on using deep learning for feature extraction on the IFCB dataset. We will try to improve the features downloaded from the IFCB DashBoard. We have tested two aproaches.

#Building an autoencoder
For this approach, we have to preprocess the images and feed them to a neural network. This image is then given to the NN as the input and also as the desired output. The idea is that the network has to learn how to representate the images without losing to much information. All the functions related with this approach are in the file autoencoder.R. We couldn't make this approach work because the innability to train a big NN.

#Transfer learning
The idea is to use a CNN already trained (for instance in the ImageNet Dataset). We feed the images to this CNN and get the outputs of a fully connected layer. This outputs are then used as features. This approach is in the file deepfeatures.R. The steps are the following:

1. Extract a percentage of the examples in the dataset and make a CV using a classification algorithm (RF for instance), using the dashboard features.
2. Use a deep neural network as resnet or inception to compute evaluate the images. We will take the output of one of the last layers in the CNN, a fully connected one. This output will be saved as the features of the image. All this computation is done in the function #computeDeepFeatures()
3. Compare the strongness of this feature set with the traditional features obtained from the IFCB DashBoard.