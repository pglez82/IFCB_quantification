# WHOIResultsPlotter
The aim of this project is to provide a simple visualization tool for plotting the results of quantification methods. This tools shows a chart for each class, plotting the true prevalence compared with the estimated prevalence for different methods over all the files used in the experiment (764 in this case).

The tool has been build using HTML and JavaScript with the AngularJS framework. For the plots, the library Plotly has been used.

This tool needs a data directory in which we will have a csv file for each class. Each csv file will have a column for the testing file number and extracolumns for each method.

The tool hasn't been built in order to work for other datasets. It has been built specificallly for this one. Anyway, It would be quite easy to adapt it to other problems or data.

Demo site: https://pglez82.github.io/IFCB_quantification/

There is an extra script in the folder autoclass_prevalence. This script downloads all the prevalences computed in the IFCB Dashboard for the files that we use in our experiment. After that, this prevalences are plotted in the charts beside the other methods.
