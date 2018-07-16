/******************************************************************************
  Employee Performance Evaluation for Speakup Round 4 Accident Data Collection
  
Authors: Jacklyn Pi, William Stubbs, Yuou Wu
Email: jcp119@georgetown.edu wgs11@georgetown.edu yw375@georgetown.edu
Date: 09/07/2018
Updated: 16/07/2018
*******************************************************************************/

quietly {

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
	cd 
}

*File paths
global RawFolder "data/raw"
global TempFolder "data/temp"
global FinalFolder "data/final"
global OutputFolder "output"


/*******************************************************************************
********************************************************************************
	Precleaning: 
		- Remove unneeded calculate variables used in surveyCTO
********************************************************************************
*******************************************************************************/

noisily display _continue "Precleaning data... "

use "$RawFolder/Speak Up Staff Performance Evaluation Survey.dta", clear

// drop variables used in SurveyCTO global calculations
drop project*

rename v291 pastenum_behavioroutside_ex_2

save "$TempFolder/SpeakUp_Round4_Performance_eval_preclean.dta", replace
use "$TempFolder/SpeakUp_Round4_Performance_eval_preclean.dta", clear

noisily display "Done."

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

noisily display "Performing enumerator analysis... "

preserve

// reshape data so that the evaluation of each enumerator is its own record
keep if super_yn == 1 
rename enum_behavioroutside_explain* behavioroutside_enum*
rename enum_workagain_no* workagain_no_enum*
reshape long enum_name enum_improve enum_survey enum_attention enum_ontime ///
	  enum_direction enum_trust enum_teamwork enum_effective enum_workagain ///
	  enum_behavioroutside, i(key) j(enum, string)
	
drop if enum_name == ""
	  
// calculate averages for current enumerators
noisily display _continue _col(5) "Calculating averages for current enumerators... "

egen enum_avgscore = rmean(enum_improve enum_survey enum_attention /// 
	enum_ontime enum_direction enum_trust enum_teamwork)
	
egen enum_teamavg = mean(enum_avgscore), by(key)
egen enum_sd = sd(enum_avgscore), by(key)

gen z1enum_score = (enum_avgscore - enum_teamavg)/enum_sd
replace z1enum_score = 0 if z1enum_score == .
gen enum_adjustedscore = 3 + z1enum_score
replace enum_adjustedscore = 3 if enum_adjustedscore == .

noisily display "Done."

// set labels in preparation for export
gen enum_workagain_str = "No"
replace enum_workagain_str = "Yes" if enum_workagain == 1

label variable enum_name "Enumerator name"
label variable enum_avgscore "Average score"
label variable enum_adjustedscore "Adjusted average score"
label variable enum_effective "Overall effectiveness"
label variable enum_workagain_str "Would you work with this enumerator again?"

label values enum_effective .

// count number of enumerators for pastenums export
count
local enum_amt = r(N)

// export to excel
noisily display _continue _col(5) "Exporting data for current enumerators... "

export excel enum_name enum_avgscore enum_adjustedscore enum_effective ///
	enum_workagain_str using "$OutputFolder/Speak_Up_Staff_Evals.xlsx", ///
	sheetmodify sheet("Enumerators") firstrow(varl) cell(A1)
putexcel set "$OutputFolder/Speak_Up_Staff_Evals.xlsx", modify sheet("Enumerators")
putexcel (A1:E1), bold border(bottom, medium, black) overwritefmt

noisily display "Done."

// reshape back to wide
drop enum_avgscore enum_teamavg enum_sd z1enum_score enum_adjustedscore ///
	enum_workagain_str
reshape wide

rename pastenum_behavioroutside_ex* behavioroutside_pastenum*
rename pastenum_workagain_no* workagain_no_pastenum*
reshape long pastenum_name pastenum_improve pastenum_survey ///
	pastenum_attention pastenum_ontime pastenum_direction pastenum_trust ///
	pastenum_teamwork pastenum_effective pastenum_workagain ///
	workagain_no_pastenum pastenum_behavioroutside behavioroutside_pastenum, ///
	i(key) j(pastenum, string)
	
drop if pastenum_name == ""

// calculate averages for past enumerators
noisily display _continue _col(5) "Calculating averages for past enumerators... "

egen pastenum_avgscore = rmean(pastenum_improve pastenum_survey ///
	pastenum_attention pastenum_ontime pastenum_direction pastenum_trust ///
	pastenum_teamwork)

noisily display "Done."

// set labels in preparation for export
gen pastenum_workagain_str = "No"
replace pastenum_workagain_str = "Yes" if pastenum_workagain == 1

label variable pastenum_name "Enumerator name"
label variable pastenum_avgscore "Average score"
label variable pastenum_effective "Overall effectiveness"
label variable pastenum_workagain_str ///
	"Would you work with this enumerator again?"
label variable workagain_no_pastenum "Why not?"

// export to excel
noisily display _continue _col(5) "Exporting data for past enumerators... "

local pastenum_row = `enum_amt' + 4
export excel pastenum_name pastenum_avgscore pastenum_effective ///
	pastenum_workagain_str workagain_no_pastenum ///
	using "$OutputFolder/Speak_Up_Staff_Evals.xlsx", ///
	sheetmodify sheet("Enumerators") firstrow(varl) cell(A`pastenum_row')
	
local pastenum_title = `pastenum_row' - 1
putexcel (A`pastenum_title') = "Past Enumerators", bold overwritefmt
putexcel (A`pastenum_row':E`pastenum_row'), ///
	bold border(bottom, medium, black) overwritefmt


noisily display "Done."	
	
restore

noisily display "Enumerator analysis complete."

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

} // end quietly

