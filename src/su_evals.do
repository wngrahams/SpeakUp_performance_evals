/******************************************************************************
  Employee Performance Evaluation for Speakup Round 4 Accident Data Collection
Author: Jacklyn Pi, William Stubbs, Yuou Wu
Email: jcp119@georgetown.edu wgs11@georgetown.edu yw375@georgetown.edu
Date: 09/07/2018
Updated: 09/07/2018
*******************************************************************************/

	/*__________________
	|					|
	|	Preliminaries	|
	|___________________*/

clear all
set more off

*Usernames
// Jacklyn
if "`c(username)'" == "Jacklyn" {
	cd "/Users/Jacklyn/Desktop/Speak Up Git Hub/SpeakUp_performance_evals/src/"
}
// Graham:
else if "`c(username)'" == "grahamstubbs" {
	cd "/Users/grahamstubbs/Documents/Summer_2018/stata/SpeakUp_performance_evals/SpeakUp_performance_evals/"
}
// Yuou:
else if "`c(username)'" == "yuouwu" {
	cd 
}

*File paths
global RawFolder "data/raw"
global TempFolder "data/temp"
global FinalFolder "data/final"
global OutputFolder "output"

using "$RawFolder/Speak Up Staff Performance Evaluation Survey.dta", clear

/*******************************************************************************
********************************************************************************
	Enumerators: 
		TODO:
		- Overall weighted score
		- Effective overall score
		- Flag neutral or below
		- Flag anyone a supervisor wouldn't want to work with agian
********************************************************************************
*******************************************************************************/




/*******************************************************************************
********************************************************************************
	Supervisors: 
		TODO:
		- Average
		- Supervisor rating
		- Leadership quality bar graph
		- Flag anyone enumerators wouldn't want to work with agian
********************************************************************************
*******************************************************************************/




/*******************************************************************************
********************************************************************************
	Project Management: 
		TODO:
		- Overall average score
		- Training weighted score
		- Skills learned bar graph
		- Skills improved bar graph
********************************************************************************
*******************************************************************************/



