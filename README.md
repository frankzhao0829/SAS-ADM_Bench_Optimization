# A&DM Bench Optimization
Positions Extention.sas: This program is used to build Logistic Regression model on Likelihood of project extension using at least 1 year of data.

Extension Scoring.sas: This program is to score the likelihood of extension of current ongoing projects based on the modelling file created in Positions Extention.sas.

### Prerequisites: 

Need to install SAS Clients (e.g. Enterprise Guide, putty) to access SAS Server.

### Data:
Combined at least 1 year Rolloff data from Bench Outlook file (Monthly data). Use the combined file as input for Positions Extention.sas code. Upload the combined data to your SAS working directory.

Use “Expected to Extend” as dependent variable. 

### Installing:

Save SAS code to your working directory to run

### Running the modelling code: 

1. Change the Bench libname before running the code.

2. Petition the input data into Training and Testing sample. Use Training sample to build the model.

3. Combine categorical variables if there is quasi-complete separation after running the model. 

4. Apply the modelling to Testing sample using PROC SCORE procedure. 
5. Adjust the variables if needed to increase the model’s predictive power. Save the final modelling data to your working directory. 

### Running the scoring code: 

1. Change the Bench libname before running the code.

2. Use latest Bench Outlook data as input. 

### Deployment:

Export the scored Bench Outlook file to view the Extension probabilities results.

### Built with:

SAS

### Authors: 

Frank (Chunyou) Zhao
