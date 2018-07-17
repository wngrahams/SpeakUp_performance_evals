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
	cd 
}
// Graham:
else if "`c(username)'" == "grahamstubbs" {
	cd "/Users/grahamstubbs/Documents/Summer_2018/stata/SpeakUp_performance_evals/SpeakUp_performance_evals/"
}
// Yuou:
else if "`c(username)'" == "yuouwu" {
	cd "/Users/yuouwu/Documents/github/gui2de/SpeakUp_performance_evals/"
}

*File paths
global RawFolder "data/raw"
global TempFolder "data/temp"
global FinalFolder "data/final"
global OutputFolder "output"

use "$RawFolder/Speak Up Staff Performance Evaluation Survey.dta", clear

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
Yuou-	Project Management/Training: 
		TODO:
		- Overall average score
		- Training weighted score
		- Skills learned bar graph
		- Skills improved bar graph
********************************************************************************
*******************************************************************************/ 
// pre chleaning //
gen sup=1 if super_passcode==31415
replace sup=0 if sup==.
label var sup "supervisor"
keep training* learning* skills* pm* sup
tempfile tempdata
save "`tempdata'"
use `tempdata', clear
local pmquality "clarity respect responsive approach effective accountable knowledge logistics overall"
foreach i in `pmquality' {
	label var pm_`i' `i'
	label values pm_`i' .
}
label define enumerator_lb 0 "enumerator" 1 "supervisor"
label values sup enumerator_lb

// PM overall average score // 
tabout pm_clarity pm_respect pm_responsive pm_approach pm_effective pm_accountable ///
 	pm_knowledge pm_logistics pm_overall sup using staff_eval.xls, replace c(freq col) ///
	f(0c 1) font(bold) style(xlsx) ptotal(none)
tabcount pm_clarity sup, v1(1/5) v2(0/1) replace
bysort sup: egen su = total(_freq)
bysort sup: gen pcsup = _freq /su
tabdisp pm_clarity sup, c(_freq pcsup)
matrix tabdisp = e(b)
matlist tabdisp
// rename sheet //
preserve
insheet using "staff_eval.xls", clear 
export excel using "staff_eval.xlsx", sheetreplace sheet("pm_eval") 
rm "staff_eval.xls" 
restore

// sum average //
tabstat pm_clarity pm_respect pm_responsive pm_approach pm_effective pm_accountable ///
 	pm_knowledge pm_logistics pm_overall, stat(mean) save
matrix results = r(StatTotal)
matrix colnames results = `pmquality'
matlist results
putexcel set staff_eval.xlsx, sheet(pm_eval) modify
putexcel J2=matrix(results), names nformat(number_d2)
// percentage // 
matrix percentage = results/5*100
matrix rownames percentage=Percentage
putexcel J7=matrix(percentage), names nformat(number_d2)
matlist percentage


// skills learned // 
local number "2 3 4 5 6 7 8 9 10 11"
local skills "Leadership_skills Organization_skills Public_speaking Time_management Tech_skills Working_with_others Problem_solving Attention_to_detail Communication_skills Conflict_resolution Other"
// matrix totalskills = r(StatTotal)
tabstat skills_learned_1 if (skills_learned_1==1), stat(count) save
matrix skillslearned=r(StatTotal)
foreach i in `number'{
	capture tabstat skills_learned_`i' if (skills_learned_`i'==1), stat(count) save
	matrix skillslearn`i'=r(StatTotal)
	matrix skillslearned=skillslearned,skillslearn`i'
	count if skills_learned_`i'==1 
	gen skill`i'=r(N)
 }
matrix colnames skillslearned = `skills'
matrix rownames skillslearned = count
matlist skillslearned
putexcel set staff_eval.xlsx, sheet(skills) modify
putexcel A2=matrix(skillslearned), names
// graph bar skill1 skill2 skill3 skill4 skill5 skill6 skill7 
// graph export skilllearned.png, replace
drop skill? skill??

// skills improved //
local skills "Leadership_skills Organization_skills Public_speaking Time_management Tech_skills Working_with_others Problem_solving Attention_to_detail Communication_skills Conflict_resolution Other"
tabstat skills_improve_1 if (skills_improve_1==1), stat(count) save
matrix skillsimproved=r(StatTotal)
foreach i in `number'{
	capture tabstat skills_improve_`i' if (skills_improve_`i'==1), stat(count) save
	matrix skillsimprove`i'=r(StatTotal)
	matrix skillsimproved=skillsimproved,skillsimprove`i'
	count if skills_improve_`i'==1 
	gen skill`i'=r(N)
 }
// install with command dm79/matselrc.ado //
// matselrc skillsimproved improved, c(2 3)
matrix colnames skillsimproved = `skills'
capture matrix rownames skillsimproved = count
matlist skillsimproved
putexcel set staff_eval.xlsx, sheet(skills) modify
putexcel A8=matrix(skillsimproved), names
// graph bar skill1 skill2 skill3 skill4 skill5 skill6 skill7 
// graph export skillimproved.png, replace
drop skill? skill??

// excel lookup lable//
putexcel A1="Skills learned" A7="Skills improved" 

// training aspects //
label var training_intro Introduction
label var training_surveyoverview "Survey Overview"
label var training_surveypractice "Survey Practice"
label var training_field "Field Challenge"
tabout training_tests training_intro training_surveyoverview training_surveypractice ///
	training_field using training.xls, one replace c(freq col) f(0c 1) font(bold) style(xlsx) ptotal(none)
	
preserve
insheet using "training.xls", clear 
export excel using "staff_eval.xlsx", sheetreplace sheet("training") 
rm "training.xls" 
restore

// learning aspects // 
local learning "roleplaying presentation study game"
foreach i in `learning'{
	label values learning_`i' .
}

tabout learning_roleplaying learning_presentation learning_study learning_game ///
	using learning.xls, one replace c(freq col) f(0c 1) font(bold) style(xlsx) ptotal(none)
	
preserve
insheet using "learning.xls", clear 
export excel using "staff_eval.xlsx", sheetreplace sheet("learning") 
rm "learning.xls" 
restore
