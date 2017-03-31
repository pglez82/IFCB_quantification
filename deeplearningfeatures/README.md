# IFCB_quantification 

This part of the project consists on using deep learning for feature extraction on the IFCB dataset. We will try to improve the features downloaded from the IFCB DashBoard. The steps that we will take are:

1. Extract a percentage of the examples in the dataset and make a CV using a classification algorithm (RF for instance), using the dashboard features.
2. Use a deep neural network autoencoder in order to compute a new set of features. This features will be computed by the network. The idea is to train a NN which input layer is the same than the output layer. The NN will try to learn its inputs. In the hidden layers, we will have the information compressed and we will be able to use this information as features.
3. Train a classifier using the NN features and compare the accuracy with the one obtained before.