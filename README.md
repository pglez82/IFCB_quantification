# IFCB_quantification 

This project aims to use the plankton dataset https://github.com/hsosik/WHOI-Plankton for quantification.

The steps that have been followed in order to adapt this dataset for quantification are described in the next section.

##Data preparation

All functions needed to process the data are in the file buildRData.R. The steps are the following:

1. Read the images and from the download directory and process them (see function buildBaseData())
2. For quantification we need only the complete samples. In total we have more than 5000 samples but only 964 are complete (the list is in FULLY_ANNOTATED.RData). In this step we download the features of each image in the complete samples. The features are downloaded as CSV files from the IFCB Dashboard (see function downloadFeatres())
3. In this step we take all the csv downloaded in step 2 and we merge them, combining all the features in a RData file. (see function combineFeatures())
4. In the last step, we match the features (computed in step 3) with the examples extracted from step 1. We only take the examples from complete samples. The final result is a dataset with 3,4 million images over 964 samples and annotated in 51 different classes.

