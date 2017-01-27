# IFCB_quantification 

This project aims to use the [Annotated WHOI-Plankton Dataset](https://github.com/hsosik/WHOI-Plankton) for quantification.

The steps that have been followed in order to adapt this dataset for quantification are described in the next section.

##Data preparation

All functions needed to process the data are in the file buildRData.R. The steps are the following:

1. Read the images and from the download directory and process them (see function *buildBaseData()*)
2. For quantification we need only the complete samples. In total we have more than 5000 samples but only 964 are complete (the list is in FULLY_ANNOTATED.RData). In this step we download the features of each image in the complete samples. The features are downloaded as CSV files from the IFCB Dashboard (see function *downloadFeatures()*)
3. In this step we take all the csv downloaded in step 2 and we merge them, combining all the features in a RData file. (see function *combineFeatures()*)
4. In this step, we match the features (computed in step 3) with the examples extracted from step 1. We only take the examples from complete samples. The final result is a dataset with 3,4 million images over 964 samples and annotated in 51 different classes.
5. In this fifth step we compute the functional group of each example. There are five functional groups. This attribute can be used to reduce the number of classes from 51 to just 5. For this, we have to use the function *combineClassesInFunctionalGroups()*.
6. [Optional] There are seven columns with missing values. With the function *fixNanValues()* it is possible to set them to 0.
7. Data export. With the function *exportToCSV()* we build a file IFCB.csv were the columns are: Sample, roi_number, Class,...features...


