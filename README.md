# TestExamGenerator
Simple multiple choice exam generator. It integrates with the MCTest Corrector (https://play.google.com/store/apps/details?id=com.corretordetestes).
The idea behind this proyect is to build an automatic multichoice exam generator that is able to create an exam from a question list. 
This question list is classified in different units and when you generate an exam, you can choose from which units you want to take the questions.
This program generates three things:
* A PDF file with the exam
* A PDF file with the exam included the correct responses.
* An ODT template that can be used to automatically correct the exam using the MCTest Corrector

MCTest Corrector is a free android app that can be downloaded from Google Play. It allows you to correct multiple choice exams using your smartphone camera.

Under the template directory, you have the template used for generating the exam. This template is an IReports jrxml file that can be changed. I suggest you to
duplicate the existing one before trying to modify it. The jrxml can be changed with a text editor or you can use the [IReports Designer from JasperResports](https://sourceforge.net/projects/ireport/files/iReport/iReport-5.6.0/) which is visual and quite easy to use. 
