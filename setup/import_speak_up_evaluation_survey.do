* import_speak_up_evaluation_survey.do
*
* 	Imports and aggregates "Speak Up Staff Performance Evaluation Survey" (ID: speak_up_evaluation_survey) data.
*
*	Inputs: .csv file(s) exported by the SurveyCTO Server
*	Outputs: "Speak Up Staff Performance Evaluation Survey.dta"
*
*	Output by the SurveyCTO Server July 6, 2018 12:49 PM.

* initialize Stata
clear all
set more off
set mem 100m

* *** NOTE ***                                              *** NOTE ***
* If you run this .do file without customizing it, Stata will probably 
* give you errors about not being able to find or open files. If so,
* put all of your downloaded .do and .csv files into a single directory,
* edit the "cd" command just below to point to that directory, and then
* remove the * from the front of that cd line to un-comment it. That
* should resolve the problem.
*
* If you continue to encounter errors, see what filename Stata is trying
* to open, and rename any downloaded files accordingly. (E.g., your 
* browser might have added a (1) or a (2) to a downloaded filename.)

* initialize working directory (TO BE CUSTOMIZED)
if "`c(username)'" == "grahamstubbs" {
	cd "/Users/grahamstubbs/Documents/Summer_2018/stata/SpeakUp_performance_evals/SpeakUp_performance_evals/setup"
}

* initialize workflow-specific parameters
*	Set overwrite_old_data to 1 if you use the review and correction
*	workflow and allow un-approving of submissions. If you do this,
*	incoming data will overwrite old data, so you won't want to make
*	changes to data in your local .dta file (such changes can be
*	overwritten with each new import).
local overwrite_old_data 0

* initialize form-specific parameters
local csvfile "Speak Up Staff Performance Evaluation Survey_WIDE.csv"
local dtafile "Speak Up Staff Performance Evaluation Survey.dta"
local corrfile "Speak Up Staff Performance Evaluation Survey_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid project_name_itext project_name project_type_itext project_type project_round_itext project_round project_pm_itext project_pm"
local text_fields2 "project_po_itext project_po project_fo_itext project_fo project_company_itext project_company project_dates_itext project_dates project_training_itext project_training trainingimprove noskills_learned"
local text_fields3 "skills_learned other_skills skills_improve skills_other learned_story fav_moment field_challenge enum_list enum_amt enum_aspects_count enum_name_* enum_behavioroutside_explain_* enum_workagain_no_*"
local text_fields4 "pastenums_list pastenums_amt pastenum_aspects_count pastenum_name_* pastenum_behavioroutside_explain_* pastenum_workagain_no_* addenum_reviews_count addenum_index_* addenum_name_* addenum_review_*"
local text_fields5 "super_name super_leaderqual super_otherqual super_improve super_improve_other super_learnedfrom super_workagain_why super_workagain_whynot super_addcomments pastsuper_workagain"
local text_fields6 "pastsuper_workagain_other pm_clarity_ex pm_responsive_ex pm_approach_ex pm_effective_ex pm_accountable_ex pm_respect_ex pm_knowledge_ex pm_logistics_ex pm_comments finalendcomments instanceid"
local date_fields1 ""
local datetime_fields1 "submissiondate starttime endtime"

disp
disp "Starting import of: `csvfile'"
disp

* import data from primary .csv file
insheet using "`csvfile'", names clear

* drop extra table-list columns
cap drop reserved_name_for_field_*
cap drop generated_table_list_lab*

* continue only if there's at least one row of data to import
if _N>0 {
	* drop note fields (since they don't contain any real data)
	forvalues i = 1/100 {
		if "`note_fields`i''" ~= "" {
			drop `note_fields`i''
		}
	}
	
	* format date and date/time fields
	forvalues i = 1/100 {
		if "`datetime_fields`i''" ~= "" {
			foreach dtvarlist in `datetime_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=clock(`tempdtvar',"MDYhms",2025)
						* automatically try without seconds, just in case
						cap replace `dtvar'=clock(`tempdtvar',"MDYhm",2025) if `dtvar'==. & `tempdtvar'~=""
						format %tc `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
		if "`date_fields`i''" ~= "" {
			foreach dtvarlist in `date_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=date(`tempdtvar',"MDY",2025)
						format %td `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
	}

	* ensure that text fields are always imported as strings (with "" for missing values)
	* (note that we treat "calculate" fields as text; you can destring later if you wish)
	tempvar ismissingvar
	quietly: gen `ismissingvar'=.
	forvalues i = 1/100 {
		if "`text_fields`i''" ~= "" {
			foreach svarlist in `text_fields`i'' {
				cap unab svarlist : `svarlist'
				if _rc==0 {
					foreach stringvar in `svarlist' {
						quietly: replace `ismissingvar'=.
						quietly: cap replace `ismissingvar'=1 if `stringvar'==.
						cap tostring `stringvar', format(%100.0g) replace
						cap replace `stringvar'="" if `ismissingvar'==1
					}
				}
			}
		}
	}
	quietly: drop `ismissingvar'


	* consolidate unique ID into "key" variable
	replace key=instanceid if key==""
	drop instanceid


	* label variables
	label variable key "Unique submission ID"
	cap label variable submissiondate "Date/time submitted"
	cap label variable formdef_version "Form version used on device"
	cap label variable review_status "Review status"
	cap label variable review_comments "Comments made during review"
	cap label variable review_corrections "Corrections made during review"


	label variable training_label "Please rank aspects of training from 1 - most useful to 5 - least useful."
	note training_label: "Please rank aspects of training from 1 - most useful to 5 - least useful."
	label define training_label 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"
	label values training_label training_label

	label variable training_tests "Pre-test and post-test"
	note training_tests: "Pre-test and post-test"
	label define training_tests 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"
	label values training_tests training_tests

	label variable training_intro "Introduction to \${project_type} and data quality"
	note training_intro: "Introduction to \${project_type} and data quality"
	label define training_intro 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"
	label values training_intro training_intro

	label variable training_surveyoverview "Overview and presentation of survey"
	note training_surveyoverview: "Overview and presentation of survey"
	label define training_surveyoverview 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"
	label values training_surveyoverview training_surveyoverview

	label variable training_surveypractice "Survey practice with the tablet"
	note training_surveypractice: "Survey practice with the tablet"
	label define training_surveypractice 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"
	label values training_surveypractice training_surveypractice

	label variable training_field "Field challenges discussion and presentation"
	note training_field: "Field challenges discussion and presentation"
	label define training_field 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"
	label values training_field training_field

	label variable learning_label "Please rank methods of learning from 1 - most useful to 4 - least useful."
	note learning_label: "Please rank methods of learning from 1 - most useful to 4 - least useful."
	label define learning_label 1 "1" 2 "2" 3 "3" 4 "4"
	label values learning_label learning_label

	label variable learning_roleplaying "Roleplaying"
	note learning_roleplaying: "Roleplaying"
	label define learning_roleplaying 1 "1" 2 "2" 3 "3" 4 "4"
	label values learning_roleplaying learning_roleplaying

	label variable learning_presentation "Presentations"
	note learning_presentation: "Presentations"
	label define learning_presentation 1 "1" 2 "2" 3 "3" 4 "4"
	label values learning_presentation learning_presentation

	label variable learning_study "Independent study"
	note learning_study: "Independent study"
	label define learning_study 1 "Roleplaying" 2 "Presentations" 3 "Independent Study" 4 "Games and Quiz Show"
	label values learning_study learning_study

	label variable learning_game "Games and quiz show"
	note learning_game: "Games and quiz show"
	label define learning_game 1 "1" 2 "2" 3 "3" 4 "4"
	label values learning_game learning_game

	label variable trainingimprove "What improvements can be made to the trainings?"
	note trainingimprove: "What improvements can be made to the trainings?"

	label variable trainingprep "At the completion of training, did you feel prepared to begin field work?"
	note trainingprep: "At the completion of training, did you feel prepared to begin field work?"
	label define trainingprep 1 "Very Unprepared" 2 "Unprepared" 3 "Neutral" 4 "Prepared" 5 "Very Prepared"
	label values trainingprep trainingprep

	label variable skills "Do you feel you've learned any skills from \${project_name}?"
	note skills: "Do you feel you've learned any skills from \${project_name}?"
	label define skills 1 "Yes" 0 "No"
	label values skills skills

	label variable noskills_learned "Why not?"
	note noskills_learned: "Why not?"

	label variable skills_learned "Which skills have you learned or improved upon during your time working in the f"
	note skills_learned: "Which skills have you learned or improved upon during your time working in the field for \${project_name}?"

	label variable other_skills "What other skills have you gained or improved on from your participation in \${p"
	note other_skills: "What other skills have you gained or improved on from your participation in \${project_name}!"

	label variable skills_improve "What skills do you wish to improve upon in the FUTURE?"
	note skills_improve: "What skills do you wish to improve upon in the FUTURE?"

	label variable skills_other "What other skills do you wish to improve upon in the FUTURE?"
	note skills_other: "What other skills do you wish to improve upon in the FUTURE?"

	label variable learned_story "Please share an example of a way in which you’ve learned something from working "
	note learned_story: "Please share an example of a way in which you’ve learned something from working with your team or during field work."

	label variable fav_moment "Please share a favorite moment of yours while working in the field or for \${pro"
	note fav_moment: "Please share a favorite moment of yours while working in the field or for \${project_name}."

	label variable field_challenge "Please share the craziest challenge you faced in the field."
	note field_challenge: "Please share the craziest challenge you faced in the field."

	label variable overall_contribution "Please evaluate your level of contribution to your most recent team (\${project_"
	note overall_contribution: "Please evaluate your level of contribution to your most recent team (\${project_dates})."
	label define overall_contribution 1 "A lot of room for improvement in data quality and level of effort; required a lo" 2 "Some room for improvement in data quality and level of effort; required some gui" 3 "Average contribution in data quality and level of effort; required little guidan" 4 "Good contribution in data quality and level of effort; did not require guidance " 5 "Great contribution in data quality and level of effort; helped other team member"
	label values overall_contribution overall_contribution

	label variable super_yn "Are you a supervisor for this round of \${project_type}?"
	note super_yn: "Are you a supervisor for this round of \${project_type}?"
	label define super_yn 1 "Yes" 0 "No"
	label values super_yn super_yn

	label variable super_passcode "Please enter your 5 digit supervisor code"
	note super_passcode: "Please enter your 5 digit supervisor code"

	label variable enum_list "Please choose the enumerators that were on your team for \${project_round} of \$"
	note enum_list: "Please choose the enumerators that were on your team for \${project_round} of \${project_type}."

	label variable pastenums_yn "Are there any enumerators you'd like to review that you haven't reviewed already"
	note pastenums_yn: "Are there any enumerators you'd like to review that you haven't reviewed already?"
	label define pastenums_yn 1 "Yes" 0 "No"
	label values pastenums_yn pastenums_yn

	label variable pastenums_list "Please select the other enumerators you would like to review."
	note pastenums_list: "Please select the other enumerators you would like to review."

	label variable addenum_yn "Are there any enumerators you'd like to review that were not on the list?"
	note addenum_yn: "Are there any enumerators you'd like to review that were not on the list?"
	label define addenum_yn 1 "Yes" 0 "No"
	label values addenum_yn addenum_yn

	label variable addenum_amt "How many additional enumerators would you like to review?"
	note addenum_amt: "How many additional enumerators would you like to review?"

	label variable super_list "Please choose your supervisor for \${project_round} of \${project_name}\${projec"
	note super_list: "Please choose your supervisor for \${project_round} of \${project_name}\${project_type}."
	label define super_list 1 "Blaise" 2 "Honda" 3 "Isaac" 4 "Joseline" 5 "Julie" 6 "Rosemary"
	label values super_list super_list

	label variable super_goodexample "My supervisor sets a good example for us working in the field."
	note super_goodexample: "My supervisor sets a good example for us working in the field."
	label define super_goodexample 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_goodexample super_goodexample

	label variable super_helpful "When I needed help and support from my supervisor I received it."
	note super_helpful: "When I needed help and support from my supervisor I received it."
	label define super_helpful 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_helpful super_helpful

	label variable super_anticipate "My supervisor anticipated my concerns and checked in with me when needed."
	note super_anticipate: "My supervisor anticipated my concerns and checked in with me when needed."
	label define super_anticipate 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_anticipate super_anticipate

	label variable super_approach "My supervisor was easily approachable and I felt comfortable discussing any issu"
	note super_approach: "My supervisor was easily approachable and I felt comfortable discussing any issues or problems I encountered with them."
	label define super_approach 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_approach super_approach

	label variable super_communication "My supervisor responded to my concerns about field work quickly and their commun"
	note super_communication: "My supervisor responded to my concerns about field work quickly and their communication style was clear."
	label define super_communication 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_communication super_communication

	label variable super_logistics "My supervisor responded to my concerns about logistics, transport, and accommoda"
	note super_logistics: "My supervisor responded to my concerns about logistics, transport, and accommodation quickly."
	label define super_logistics 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_logistics super_logistics

	label variable super_environment "My supervisor was an integral part of the team and promoted a positive, collabor"
	note super_environment: "My supervisor was an integral part of the team and promoted a positive, collaborative environment."
	label define super_environment 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_environment super_environment

	label variable super_empowerment "I felt empowered by my supervisor while in the field."
	note super_empowerment: "I felt empowered by my supervisor while in the field."
	label define super_empowerment 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_empowerment super_empowerment

	label variable super_constructive "My supervisor was patient with me if I made a mistake and helped me learn from t"
	note super_constructive: "My supervisor was patient with me if I made a mistake and helped me learn from the mistake."
	label define super_constructive 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
	label values super_constructive super_constructive

	label variable super_leaderqual "Choose leadership qualities you think your supervisor has or you’ve observed."
	note super_leaderqual: "Choose leadership qualities you think your supervisor has or you’ve observed."

	label variable super_otherqual "What other qualities does your supervisor have?"
	note super_otherqual: "What other qualities does your supervisor have?"

	label variable super_improve "Choose leadership qualities you think your supervisor CAN IMPROVE ON."
	note super_improve: "Choose leadership qualities you think your supervisor CAN IMPROVE ON."

	label variable super_improve_other "What other qualities can your supervisor improve on?"
	note super_improve_other: "What other qualities can your supervisor improve on?"

	label variable super_learnedfrom "Please share if you learned anything else from your supervisor."
	note super_learnedfrom: "Please share if you learned anything else from your supervisor."

	label variable super_workagain "Would you want to work under this supervisor again?"
	note super_workagain: "Would you want to work under this supervisor again?"
	label define super_workagain 1 "Yes" 0 "No"
	label values super_workagain super_workagain

	label variable super_workagain_why "Why?"
	note super_workagain_why: "Why?"

	label variable super_workagain_whynot "Why not?"
	note super_workagain_whynot: "Why not?"

	label variable super_absent "Are you aware of any incidents in which you had difficulty reaching out to your "
	note super_absent: "Are you aware of any incidents in which you had difficulty reaching out to your supervisor and they did not respond in a reasonable amount of time."
	label define super_absent 1 "Yes" 0 "No"
	label values super_absent super_absent

	label variable super_absent_num "How many times was your supervisor difficult to reach?"
	note super_absent_num: "How many times was your supervisor difficult to reach?"

	label variable super_rate "How would you rate \${super_name} for \${project_round} overall?"
	note super_rate: "How would you rate \${super_name} for \${project_round} overall?"
	label define super_rate 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values super_rate super_rate

	label variable super_addcomments "Any additional comments or feedback about your supervisor?"
	note super_addcomments: "Any additional comments or feedback about your supervisor?"

	label variable pastsuper_yn "Would you like to review any of your past supervisors?"
	note pastsuper_yn: "Would you like to review any of your past supervisors?"
	label define pastsuper_yn 1 "Yes" 0 "No"
	label values pastsuper_yn pastsuper_yn

	label variable pastsuper_workagain "Which supervisors would you want to work under again?"
	note pastsuper_workagain: "Which supervisors would you want to work under again?"

	label variable pastsuper_workagain_other "Which other supervisor would you want to work under again?"
	note pastsuper_workagain_other: "Which other supervisor would you want to work under again?"

	label variable pm_clarity "Clarity: The management team gave clear instructions."
	note pm_clarity: "Clarity: The management team gave clear instructions."
	label define pm_clarity 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_clarity pm_clarity

	label variable pm_clarity_ex "You answered unsatisfied or very unsatisfied, please explain what could have bee"
	note pm_clarity_ex: "You answered unsatisfied or very unsatisfied, please explain what could have been done better."

	label variable pm_responsive "Responsiveness: The management team responded quickly and adequately to issues y"
	note pm_responsive: "Responsiveness: The management team responded quickly and adequately to issues you encountered."
	label define pm_responsive 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_responsive pm_responsive

	label variable pm_responsive_ex "You answered unsatisfied or very unsatisfied, please explain what could have bee"
	note pm_responsive_ex: "You answered unsatisfied or very unsatisfied, please explain what could have been done better."

	label variable pm_approach "Approachability: The management team was easily approachable and you felt comfor"
	note pm_approach: "Approachability: The management team was easily approachable and you felt comfortable discussing any problems or issues you’ve encountered."
	label define pm_approach 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_approach pm_approach

	label variable pm_approach_ex "You answered unsatisfied or very unsatisfied, please explain what could have bee"
	note pm_approach_ex: "You answered unsatisfied or very unsatisfied, please explain what could have been done better."

	label variable pm_effective "Effectiveness: The field work was organized and ran smoothly."
	note pm_effective: "Effectiveness: The field work was organized and ran smoothly."
	label define pm_effective 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_effective pm_effective

	label variable pm_effective_ex "You answered unsatisfied or very unsatisfied, please explain what could have bee"
	note pm_effective_ex: "You answered unsatisfied or very unsatisfied, please explain what could have been done better."

	label variable pm_accountable "Accountability: If something didn't work, the project management team handled th"
	note pm_accountable: "Accountability: If something didn't work, the project management team handled the issue appropriately and took responsibility for it."
	label define pm_accountable 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_accountable pm_accountable

	label variable pm_accountable_ex "You answered unsatisfied or very unsatisfied, please explain what could have bee"
	note pm_accountable_ex: "You answered unsatisfied or very unsatisfied, please explain what could have been done better."

	label variable pm_respect "Respect: You felt respected by the project management team and you respected the"
	note pm_respect: "Respect: You felt respected by the project management team and you respected them in turn."
	label define pm_respect 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_respect pm_respect

	label variable pm_respect_ex "You answered unsatisfied or very unsatisfied, please explain what could have bee"
	note pm_respect_ex: "You answered unsatisfied or very unsatisfied, please explain what could have been done better."

	label variable pm_knowledge "Field Knowledge: The project management team had a good understanding of the iss"
	note pm_knowledge: "Field Knowledge: The project management team had a good understanding of the issues and challenges you faced during field work."
	label define pm_knowledge 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_knowledge pm_knowledge

	label variable pm_knowledge_ex "You answered unsatisfied or very unsatisfied, please explain what could have bee"
	note pm_knowledge_ex: "You answered unsatisfied or very unsatisfied, please explain what could have been done better."

	label variable pm_logistics "Logistics: Breakdowns of payments and transport were clear. If there was an issu"
	note pm_logistics: "Logistics: Breakdowns of payments and transport were clear. If there was an issue with the payments, it was properly communicated and handled."
	label define pm_logistics 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_logistics pm_logistics

	label variable pm_logistics_ex "You answered unsatisfied or very unsatisfied, please explain what could have bee"
	note pm_logistics_ex: "You answered unsatisfied or very unsatisfied, please explain what could have been done better."

	label variable pm_overall "Overall, how satisfied are you with the project management team?"
	note pm_overall: "Overall, how satisfied are you with the project management team?"
	label define pm_overall 1 "Very Unsatisfied" 2 "Unsatisfied" 3 "Neutral" 4 "Satisfied" 5 "Very Satisfied"
	label values pm_overall pm_overall

	label variable pm_comments "Please add any additional comments, feedback, or acknowledgements about the mana"
	note pm_comments: "Please add any additional comments, feedback, or acknowledgements about the management team."

	label variable intern_helpful "If you had the interns on your team, were they helpful?"
	note intern_helpful: "If you had the interns on your team, were they helpful?"
	label define intern_helpful 1 "Yes" 0 "No" 2 "There were no interns on my team"
	label values intern_helpful intern_helpful

	label variable intern_matooke "Which intern can eat the most matooke?"
	note intern_matooke: "Which intern can eat the most matooke?"
	label define intern_matooke 1 "Graham" 2 "Jacklyn" 3 "Yuou"
	label values intern_matooke intern_matooke

	label variable finalendcomments "Is there anything else you’d like to say about field work, your supervisor, your"
	note finalendcomments: "Is there anything else you’d like to say about field work, your supervisor, yourself, or \${project_name}?"



	capture {
		foreach rgvar of varlist enum_improve_* {
			label variable `rgvar' "\${enum_name} gave a conscious effort to continually improve their skill sets an"
			note `rgvar': "\${enum_name} gave a conscious effort to continually improve their skill sets and quality of work."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_survey_* {
			label variable `rgvar' "\${enum_name} displayed a strong understanding of the survey during data collect"
			note `rgvar': "\${enum_name} displayed a strong understanding of the survey during data collection/field activities."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_attention_* {
			label variable `rgvar' "\${enum_name} paid strong attention to detail and made sure to minimize errors d"
			note `rgvar': "\${enum_name} paid strong attention to detail and made sure to minimize errors during data collection/field activities."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_ontime_* {
			label variable `rgvar' "\${enum_name} was consistently on time to work."
			note `rgvar': "\${enum_name} was consistently on time to work."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_direction_* {
			label variable `rgvar' "\${enum_name} reasonably followed the supervisor's instructions and directions."
			note `rgvar': "\${enum_name} reasonably followed the supervisor's instructions and directions."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_trust_* {
			label variable `rgvar' "\${enum_name} displayed high levels of trustworthiness."
			note `rgvar': "\${enum_name} displayed high levels of trustworthiness."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_teamwork_* {
			label variable `rgvar' "\${enum_name} worked well with the other team members."
			note `rgvar': "\${enum_name} worked well with the other team members."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_behavioroutside_* {
			label variable `rgvar' "Did \${enum_name}'s behavior outside of work ever jeopardize their quality of wo"
			note `rgvar': "Did \${enum_name}'s behavior outside of work ever jeopardize their quality of work?"
			label define `rgvar' 1 "Yes" 0 "No"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_behavioroutside_explain_* {
			label variable `rgvar' "How so?"
			note `rgvar': "How so?"
		}
	}

	capture {
		foreach rgvar of varlist enum_effective_* {
			label variable `rgvar' "\${enum_name} was an effective enumerator overall."
			note `rgvar': "\${enum_name} was an effective enumerator overall."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_workagain_* {
			label variable `rgvar' "Would you work with \${enum_name} on your team again?"
			note `rgvar': "Would you work with \${enum_name} on your team again?"
			label define `rgvar' 1 "Yes" 0 "No"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist enum_workagain_no_* {
			label variable `rgvar' "Please explain why you would not work with \${enum_name} again on your team."
			note `rgvar': "Please explain why you would not work with \${enum_name} again on your team."
		}
	}

	capture {
		foreach rgvar of varlist pastenum_improve_* {
			label variable `rgvar' "\${pastenum_name} gave a conscious effort to continually improve their skill set"
			note `rgvar': "\${pastenum_name} gave a conscious effort to continually improve their skill sets and quality of work."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_survey_* {
			label variable `rgvar' "\${pastenum_name} displayed a strong understanding of the survey during data col"
			note `rgvar': "\${pastenum_name} displayed a strong understanding of the survey during data collection/field activities."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_attention_* {
			label variable `rgvar' "\${pastenum_name} paid strong attention to detail and made sure to minimize erro"
			note `rgvar': "\${pastenum_name} paid strong attention to detail and made sure to minimize errors during data collection/field activities."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_ontime_* {
			label variable `rgvar' "\${pastenum_name} was consistently on time to work."
			note `rgvar': "\${pastenum_name} was consistently on time to work."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_direction_* {
			label variable `rgvar' "\${pastenum_name} reasonably followed the supervisor's instructions and directio"
			note `rgvar': "\${pastenum_name} reasonably followed the supervisor's instructions and directions."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_trust_* {
			label variable `rgvar' "\${pastenum_name} displayed high levels of trustworthiness."
			note `rgvar': "\${pastenum_name} displayed high levels of trustworthiness."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_teamwork_* {
			label variable `rgvar' "\${pastenum_name} worked well with the other team members."
			note `rgvar': "\${pastenum_name} worked well with the other team members."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_behavioroutside_* {
			label variable `rgvar' "Did \${pastenum_name}'s behavior outside of work ever jeopardize their quality o"
			note `rgvar': "Did \${pastenum_name}'s behavior outside of work ever jeopardize their quality of work?"
			label define `rgvar' 1 "Yes" 0 "No"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_behavioroutside_explain_* {
			label variable `rgvar' "How so?"
			note `rgvar': "How so?"
		}
	}

	capture {
		foreach rgvar of varlist pastenum_effective_* {
			label variable `rgvar' "\${pastenum_name} was an effective enumerator overall."
			note `rgvar': "\${pastenum_name} was an effective enumerator overall."
			label define `rgvar' 1 "Strongly Disagree" 2 "Disagree" 3 "Neutral" 4 "Agree" 5 "Strongly Agree"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_workagain_* {
			label variable `rgvar' "Would you work with \${pastenum_name} on your team again?"
			note `rgvar': "Would you work with \${pastenum_name} on your team again?"
			label define `rgvar' 1 "Yes" 0 "No"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist pastenum_workagain_no_* {
			label variable `rgvar' "Please explain why you would not work with \${pastenum_name} again on your team."
			note `rgvar': "Please explain why you would not work with \${pastenum_name} again on your team."
		}
	}

	capture {
		foreach rgvar of varlist addenum_name_* {
			label variable `rgvar' "Please enter the name of additional enumerator number \${addenum_index} that you"
			note `rgvar': "Please enter the name of additional enumerator number \${addenum_index} that you'd like to review."
		}
	}

	capture {
		foreach rgvar of varlist addenum_review_* {
			label variable `rgvar' "Please descrive additional enumerator number \${addenum_index}'s skills as an en"
			note `rgvar': "Please descrive additional enumerator number \${addenum_index}'s skills as an enumerator and say why or why not you would want to work with them on your team in the future."
		}
	}




	* append old, previously-imported data (if any)
	cap confirm file "`dtafile'"
	if _rc == 0 {
		* mark all new data before merging with old data
		gen new_data_row=1
		
		* pull in old data
		append using "`dtafile'"
		
		* drop duplicates in favor of old, previously-imported data if overwrite_old_data is 0
		* (alternatively drop in favor of new data if overwrite_old_data is 1)
		sort key
		by key: gen num_for_key = _N
		drop if num_for_key > 1 & ((`overwrite_old_data' == 0 & new_data_row == 1) | (`overwrite_old_data' == 1 & new_data_row ~= 1))
		drop num_for_key

		* drop new-data flag
		drop new_data_row
	}
	
	* save data to Stata format
	save "`dtafile'", replace

	* show codebook and notes
	codebook
	notes list
}

disp
disp "Finished import of: `csvfile'"
disp

* apply corrections (if any)
capture confirm file "`corrfile'"
if _rc==0 {
	disp
	disp "Starting application of corrections in: `corrfile'"
	disp

	* save primary data in memory
	preserve

	* load corrections
	insheet using "`corrfile'", names clear
	
	if _N>0 {
		* number all rows (with +1 offset so that it matches row numbers in Excel)
		gen rownum=_n+1
		
		* drop notes field (for information only)
		drop notes
		
		* make sure that all values are in string format to start
		gen origvalue=value
		tostring value, format(%100.0g) replace
		cap replace value="" if origvalue==.
		drop origvalue
		replace value=trim(value)
		
		* correct field names to match Stata field names (lowercase, drop -'s and .'s)
		replace fieldname=lower(subinstr(subinstr(fieldname,"-","",.),".","",.))
		
		* format date and date/time fields (taking account of possible wildcards for repeat groups)
		forvalues i = 1/100 {
			if "`datetime_fields`i''" ~= "" {
				foreach dtvar in `datetime_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						gen origvalue=value
						replace value=string(clock(value,"MDYhms",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
						* allow for cases where seconds haven't been specified
						replace value=string(clock(origvalue,"MDYhm",2025),"%25.0g") if strmatch(fieldname,"`dtvar'") & value=="." & origvalue~="."
						drop origvalue
					}
				}
			}
			if "`date_fields`i''" ~= "" {
				foreach dtvar in `date_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						replace value=string(clock(value,"MDY",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
					}
				}
			}
		}

		* write out a temp file with the commands necessary to apply each correction
		tempfile tempdo
		file open dofile using "`tempdo'", write replace
		local N = _N
		forvalues i = 1/`N' {
			local fieldnameval=fieldname[`i']
			local valueval=value[`i']
			local keyval=key[`i']
			local rownumval=rownum[`i']
			file write dofile `"cap replace `fieldnameval'="`valueval'" if key=="`keyval'""' _n
			file write dofile `"if _rc ~= 0 {"' _n
			if "`valueval'" == "" {
				file write dofile _tab `"cap replace `fieldnameval'=. if key=="`keyval'""' _n
			}
			else {
				file write dofile _tab `"cap replace `fieldnameval'=`valueval' if key=="`keyval'""' _n
			}
			file write dofile _tab `"if _rc ~= 0 {"' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab _tab `"disp "CAN'T APPLY CORRECTION IN ROW #`rownumval'""' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab `"}"' _n
			file write dofile `"}"' _n
		}
		file close dofile
	
		* restore primary data
		restore
		
		* execute the .do file to actually apply all corrections
		do "`tempdo'"

		* re-save data
		save "`dtafile'", replace
	}
	else {
		* restore primary data		
		restore
	}

	disp
	disp "Finished applying corrections in: `corrfile'"
	disp
}
