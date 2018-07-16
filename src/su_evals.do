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
	cd "/Users/Jacklyn/Desktop/Speak Up Git Hub/SpeakUp_performance_evals/"
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
		- Average - done, excel
		- Supervisor rating - done, excel
		- Leadership quality bar graph, done
		- Leadership  needed improvement bar graph, done
		- Flag anyone enumerators wouldn't want to work with again, done w/ comments
********************************************************************************
*******************************************************************************/

//Average Ratings of Traits

preserve

keep super* 
drop if super_yn == 1

bysort super_name: egen avgsuper_goodexample = mean(super_goodexample)
bysort super_name: egen avgsuper_helpful = mean(super_helpful)
bysort super_name: egen avgsuper_anticipate = mean(super_anticipate)
bysort super_name: egen avgsuper_approach = mean(super_approach)
bysort super_name: egen avgsuper_communication = mean(super_communication)
bysort super_name: egen avgsuper_logistics = mean(super_logistics)
bysort super_name: egen avgsuper_environment = mean(super_environment)
bysort super_name: egen avgsuper_empowerment = mean(super_empowerment)
bysort super_name: egen avgsuper_constructive = mean(super_constructive)
bysort super_name: egen avgsuper_rate = mean(super_rate)

putexcel set "$OutputFolder/SpeakUpEvals.xlsx", modify sheet ("Ratings")
	putexcel A2 = ("Supervisor") B2 = ("Good Example Rating") /// 
		C2= ("Helpful Rating") D2=("Anticipate Rating") ///
		E2=("Approach Rating") F2=("Communication Rating") G2=("Logistics Rating") H2=("Team Environment Rating") ///
		I2=("Empowerment Rating") J2=("Constructive Rating") ///
		K2=("Overal Satisfication Rating") /// 
		B3= (" My supervisor sets a good example for us working in the field.") /// 
		C3= ("When I needed help and support from my supervisor I received it.") ///
		D3=("My supervisor anticipated my concerns and checked in with me when needed.") ///
		E3=("My supervisor was easily approachable and I felt comfortable discussing any issues or problems I encountered with them.") ///
		F3=("My supervisor responded to my concerns about field work quickly and their communication style was clear.") /// 
		G3=("My supervisor responded to my concerns about logistics, transport, and accommodation quickly.") /// 
		H3=("My supervisor was an integral part of the team and promoted a positive, collaborative environment.") ///
		I3=(" I felt empowered by my supervisor while in the field.") /// 
		J3=("My supervisor was patient with me if I made a mistake and helped me learn from the mistake.") ///
		K3=("How would you rate your supervisor for Round 4 Speak Up Data Collection overall?")
	
	/*export to excel*/ 
	collapse super_goodexample super_helpful super_anticipate super_approach ///
		super_communication super_logistics super_environment super_empowerment ///
		super_constructive super_rate, by(super_name)
	export excel using "$OutputFolder/SpeakUpEvals.xlsx",  ///
		cell(A5) sheet ("Ratings", modify)
	levelsof super_name

restore

//Super work again

preserve 

sort super_name
keep if super_workagain == 1
keep super_name super_workagain_why
sort super_name

putexcel set "$OutputFolder/SpeakUpEvals.xlsx", modify sheet ("Work Again")
	putexcel A1 = ("Supervisor") B1 = ("Why Work Again?") /// 

	/*export to excel*/ 
	export excel using "$OutputFolder/SpeakUpEvals.xlsx",  ///
		cell(A2) sheet ("Work Again", modify)
	levelsof super_name
restore


//Super not work again

preserve 

sort super_name
keep if super_workagain == 0
keep super_name super_workagain_whynot


putexcel set "$OutputFolder/SpeakUpEvals.xlsx", modify sheet ("Work Again")
	putexcel A30 = ("Supervisor") B30 = ("Why Not Work Again?") /// 

	/*export to excel*/ 
	export excel using "$OutputFolder/SpeakUpEvals.xlsx",  ///
		cell(A31) sheet ("Work Again", modify)
	levelsof super_name
restore


//Super absent

preserve 

sort super_name

keep if super_absent == 1
keep super_name super_absent_num


putexcel set "$OutputFolder/SpeakUpEvals.xlsx", modify sheet ("Absent")
	putexcel B4 = ("Supervisor") C4 = ("How Many Times Absent") /// 
	A1 = ("Are you aware of any incidents in which you had difficulty reaching out to your supervisor?") ///
	A2 = ("How many times was your supervisor difficult to reach?")

	/*export to excel*/ 
	export excel using "$OutputFolder/SpeakUpEvals.xlsx",  ///
		cell(B5) sheet ("Absent", modify)
	levelsof super_name
restore



//Super Add Comments

preserve 

keep super* 
sort super_name
drop if super_yn == 1
drop if super_addcomments == "None" | super_addcomments == "No" | super_addcomments == "No." | super_addcomments == "" 
keep super_name super_addcomments


putexcel set "$OutputFolder/SpeakUpEvals.xlsx", modify sheet ("Additional Comments")
	putexcel A1 = ("Supervisor") B1 = ("Additional Comments") /// 

	/*export to excel*/ 
	export excel using "$OutputFolder/SpeakUpEvals.xlsx",  ///
		cell(A2) sheet ("Additional Comments", modify)
	levelsof super_name
restore


// Past Supervisor Work Again

preserve

keep pastsuper* 
drop if pastsuper_yn == 0 | pastsuper_yn == .

local n "1 2 3 4 5 6"
foreach i in `n'{
	egen numpastsuperworkagain`i' = count(pastsuper_workagain_`i') if pastsuper_workagain_`i' == 1
}

egen Blaise_pastworkagain = mean(numpastsuperworkagain1)
egen Honda_pastworkagain = mean(numpastsuperworkagain2)
egen Isaac_pastworkagain = mean(numpastsuperworkagain3)
egen Joseline_pastworkagain = mean(numpastsuperworkagain4)
egen Julie_pastworkagain = mean(numpastsuperworkagain5)
egen Rosemary_pastworkagain = mean(numpastsuperworkagain6)
gen Lawrence_pastworkagain = 2
gen Godfrey_pastworkagain = 1

keep if _n == 1
 
replace Honda_pastworkagain = Honda_pastworkagain + 1
collapse Blaise_pastworkagain Honda_pastworkagain Isaac_pastworkagain /// 
			Joseline_pastworkagain Julie_pastworkagain Rosemary_pastworkagain /// 
			Lawrence_pastworkagain Godfrey_pastworkagain
			

putexcel set "$OutputFolder/SpeakUpEvals.xlsx", modify sheet ("Past Supervisors")
	putexcel A1 = ("Which supervisors would you want to work under again?") A2 = ("Supervisor") /// 
		A3 = ("Blaise") A4 = ("Honda") 	A5 = ("Isaac") 	A6 = ("Joseline") /// 
		A7 = ("Julie") 	A8 = ("Rosemary") A9 = ("Lawrence") A10 = ("Godfrey") /// 
		B2 = ("How many people said they would want to work under the supervisor.") ///
		B3 = (Blaise_pastworkagain) B4 = (Honda_pastworkagain) B5 = (Isaac_pastworkagain) /// 
		B6 = (Joseline_pastworkagain) B7 = (Julie_pastworkagain) B8 = (Rosemary_pastworkagain) /// 
		B9 = (Lawrence_pastworkagain) B10 = (Godfrey_pastworkagain)
		
restore 


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

///Graphs of Leadership Qualities
keep super* 
drop if super_yn == 1

local n "1 2 3 4 5 6 7 8 9 10 11"
foreach i in `n'{
	bysort super_name: egen numleaderqual`i' = count(super_leaderqual_`i') if super_leaderqual_`i' == 1
}



///local super_name 
// Blaise
preserve  

keep if super_name == "Blaise"

graph bar (mean) numleaderqual1 (mean) numleaderqual2 (mean) numleaderqual3 /// 
(mean) numleaderqual4 (mean)  numleaderqual5 (mean) numleaderqual6 (mean) numleaderqual7 /// 
(mean) numleaderqual8 (mean) numleaderqual9 (mean) numleaderqual10 ///
,blabel(bar) ytitle(Number of Responses) title(Blaise's Leadership Qualities) legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Seven Respondents") ylabel(#7)

graph save "$OutputFolder/BlaiseLeaderQual", replace

restore

// Isaac
preserve  

keep if super_name == "Isaac"

graph bar (mean) numleaderqual1 (mean) numleaderqual2 (mean) numleaderqual3 /// 
(mean) numleaderqual4 (mean)  numleaderqual5 (mean) numleaderqual6 (mean) numleaderqual7 /// 
(mean) numleaderqual8 (mean) numleaderqual9 (mean) numleaderqual10 ///
,blabel(bar) ytitle(Number of Responses) title(Isaac's Leadership Qualities) legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Three Respondents") ylabel(#2)

graph save "$OutputFolder/IsaacLeaderQual", replace

restore

// Honda

preserve  

keep if super_name == "Honda"

graph bar (mean) numleaderqual1 (mean) numleaderqual2 (mean) numleaderqual3 /// 
(mean) numleaderqual4 (mean)  numleaderqual5 (mean) numleaderqual6 (mean) numleaderqual7 /// 
(mean) numleaderqual8 (mean) numleaderqual9 (mean) numleaderqual10 (mean) numleaderqual11 ///
,blabel(bar) ytitle(Number of Responses) title(Honda's Leadership Qualities) legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
legend(label( 11 "Open Minded")) note("Four Respondents") ylabel(#4)

graph save "$OutputFolder/HondaLeaderQual", replace

restore

// Joseline

preserve  

keep if super_name == "Joseline"

graph bar (mean) numleaderqual1 (mean) numleaderqual2 (mean) numleaderqual3 /// 
(mean) numleaderqual4 (mean)  numleaderqual5 (mean) numleaderqual6 (mean) numleaderqual7 /// 
(mean) numleaderqual8 (mean) numleaderqual9 (mean) numleaderqual10  ///
,blabel(bar) ytitle(Number of Responses) title(Joseline's Leadership Qualities) legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Seven Respondents") ylabel(#6)

graph save "$OutputFolder/JoselineLeaderQual", replace

restore


// Julie

preserve  

keep if super_name == "Julie"

graph bar (mean) numleaderqual1 (mean) numleaderqual2 (mean) numleaderqual3 /// 
(mean) numleaderqual4 (mean)  numleaderqual5 (mean) numleaderqual6 (mean) numleaderqual7 /// 
(mean) numleaderqual8 (mean) numleaderqual9 (mean) numleaderqual10 (mean) numleaderqual11 ///
,blabel(bar) ytitle(Number of Responses) title(Julie's Leadership Qualities) legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
legend(label( 11 "Motivator/Team Player")) note("Four Respondents") ylabel(#3)

graph save "$OutputFolder/JulieLeaderQual", replace

restore

// Rosemary

preserve  

keep if super_name == "Rosemary"

graph bar (mean) numleaderqual1 (mean) numleaderqual2 (mean) numleaderqual3 /// 
(mean) numleaderqual4 (mean)  numleaderqual5 (mean) numleaderqual6 (mean) numleaderqual7 /// 
(mean) numleaderqual8 (mean) numleaderqual9 (mean) numleaderqual10  ///
,blabel(bar) ytitle(Number of Responses) title(Rosemary's Leadership Qualities) legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("3 Respondents") ylabel(minmax)

graph save "$OutputFolder/RosemaryLeaderQual", replace

restore


// Graphs of Need Improvement Leadership Qualities 

local n "1 2 3 4 5 6 7 8 9 10"
foreach i in `n'{
	bysort super_name: egen numimproveleader`i' = count(super_improve_`i') if super_improve_`i' == 1
}

///Blaise
preserve  

keep if super_name == "Blaise"

graph bar (mean) numimproveleader1 (mean) numimproveleader2 (mean) numimproveleader3 /// 
(mean) numimproveleader4 (mean)  numimproveleader5 (mean) numimproveleader6 (mean) numimproveleader7 /// 
(mean) numimproveleader8 (mean) numimproveleader9 (mean) numimproveleader10 ///
,blabel(bar) ytitle(Number of Responses) title(Blaise's Need Improvement Leadership Qualities) ///
legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Seven Respondents") ylabel(#2)

graph save "$OutputFolder/BlaiseImproveLeaderQual", replace

restore

///Isaac
preserve  

keep if super_name == "Isaac"

graph bar (mean) numimproveleader1 (mean) numimproveleader2 (mean) numimproveleader3 /// 
(mean) numimproveleader4 (mean)  numimproveleader5 (mean) numimproveleader6 (mean) numimproveleader7 /// 
(mean) numimproveleader8 (mean) numimproveleader9 (mean) numimproveleader10 ///
,blabel(bar) ytitle(Number of Responses) title(Isaac's Need Improvement Leadership Qualities) ///
legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Three Respondents") ylabel(#2)

graph save "$OutputFolder/IsaacImproveLeaderQual", replace

restore

///Honda
preserve  

keep if super_name == "Honda"

graph bar (mean) numimproveleader1 (mean) numimproveleader2 (mean) numimproveleader3 /// 
(mean) numimproveleader4 (mean)  numimproveleader5 (mean) numimproveleader6 (mean) numimproveleader7 /// 
(mean) numimproveleader8 (mean) numimproveleader9 (mean) numimproveleader10 ///
,blabel(bar) ytitle(Number of Responses) title(Honda's Need Improvement Leadership Qualities) ///
legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Four Respondents") ylabel(#2)

graph save "$OutputFolder/HondaImproveLeaderQual", replace

restore



///Joseline
preserve  

keep if super_name == "Joseline"

graph bar (mean) numimproveleader1 (mean) numimproveleader2 (mean) numimproveleader3 /// 
(mean) numimproveleader4 (mean)  numimproveleader5 (mean) numimproveleader6 (mean) numimproveleader7 /// 
(mean) numimproveleader8 (mean) numimproveleader9 (mean) numimproveleader10 ///
,blabel(bar) ytitle(Number of Responses) title(Joseline's Need Improvement Leadership Qualities) ///
legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Seven Respondents") ylabel(#1)

graph save "$OutputFolder/JoselineImproveLeaderQual", replace

restore

///Julie
preserve  

keep if super_name == "Julie"

graph bar (mean) numimproveleader1 (mean) numimproveleader2 (mean) numimproveleader3 /// 
(mean) numimproveleader4 (mean)  numimproveleader5 (mean) numimproveleader6 (mean) numimproveleader7 /// 
(mean) numimproveleader8 (mean) numimproveleader9 (mean) numimproveleader10 ///
,blabel(bar) ytitle(Number of Responses) title(Julie's Need Improvement Leadership Qualities) ///
legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Four Respondents") ylabel(#2)

graph save "$OutputFolder/JulieImproveLeaderQual", replace

restore

///Rosemary
preserve  

keep if super_name == "Rosemary"

graph bar (mean) numimproveleader1 (mean) numimproveleader2 (mean) numimproveleader3 /// 
(mean) numimproveleader4 (mean)  numimproveleader5 (mean) numimproveleader6 (mean) numimproveleader7 /// 
(mean) numimproveleader8 (mean) numimproveleader9 (mean) numimproveleader10 ///
,blabel(bar) ytitle(Number of Responses) title(Rosemary's Need Improvement Leadership Qualities) ///
legend(label( 1 "Patience")) /// 
legend(label( 2 "Fairness")) legend(label( 3 "Honesty")) legend(label( 4 "Problem Solving Skills")) /// 
legend(label( 5 "Communication")) legend(label( 6 "Approachability")) legend(label( 7 "Empowering")) /// 
legend(label( 8 "Trustworthiness")) legend(label( 9 "Responsible")) legend(label( 10 "Good mentor/teacher")) ///
note("Three Respondents") ylabel(#2)

graph save "$OutputFolder/RosemaryImproveLeaderQual", replace

restore




	
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



