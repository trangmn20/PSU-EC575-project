************************ Replication Project_Cleaning **************************

clear all
set more off
cd "D:\Study\MSc ECON-PSU\2. 2nd academic year\1. Fall 2024\EC575 - Applied Advance Econometrics\0. HWs and Assignments\0. Final project\Submission"
use replication_data_ipums, clear

********************************************************************************
******** DATA CLEANING FOR ANALYSIS
*** Remove observations and variables that is not needed

keep if inrange(birthyr, 1965, 1973) // Keep the cohort of interest for 3 groups: P, C, T
keep if race == 1 // Keep observations of white women
drop if gq == 3 | gq == 4 // Keep non instititionalized women
keep if inlist(year, 2001, 2004, 2007, 2010) // Keep years of interest
keep if (year == 2001 & inrange(birthyr, 1965, 1967)) ///
	  | (year == 2004 & inrange(birthyr, 1965, 1970)) ///
	  | (year == 2007 & inrange(birthyr, 1968, 1973)) ///
	  | (year == 2010 & inrange(birthyr, 1971, 1973))
keep year statefip nchild sex age marst birthyr race educ educd empstat empstatd 

// Create birth cohort variables
gen bcohort =.
replace bcohort = 1 if inrange(birthyr, 1965, 1967)
replace bcohort = 2 if inrange(birthyr, 1968, 1970)
replace bcohort = 3 if inrange(birthyr, 1971, 1973)

// Label the birth cohorts
label define bcohort_lbl 1 "1965-1967 (P)"
label define bcohort_lbl 2 "1968-1970 (C)", add
label define bcohort_lbl 3 "1971-1973 (T)", add
label values bcohort bcohort_lbl
label var bcohort "Birth cohort"

// Create a dummy variable for childlessness
gen childless = (nchild == 0)
label var childless "Childlessness status"
label define childless_lbl 1 "Childless", replace
label define childless_lbl 0 "Have at least a child", add
label values childless childless_lbl

*** Redefine variable education based on the paper
drop educ 

gen educ =.
replace educ = 1 if inrange(educd, 000, 061)
replace educ = 2 if inlist(educd, 062, 063, 064)
replace educ = 3 if inlist(educd, 065, 070, 071, 080, 090, 100, 110, 111, 112, 113)
replace educ = 4 if inlist(educd, 081, 082, 083)
replace educ = 5 if (educd == 101)
replace educ = 6 if inlist(educd, 114, 115, 116)

label define educ_lbl 1 "Not completed Highschool", replace
label define educ_lbl 2 "Completed Highschool", add
label define educ_lbl 3 "Some college but no degree", add
label define educ_lbl 4 "Associate's degree", add
label define educ_lbl 5 "Bachelor's degree", add
label define educ_lbl 6 "Master's degree or higher", add
label values educ educ_lbl

label var educ "Educational Attainment"
label var nchild "No. of children"
label var empstatd "Employment Status"

*** Generate dummy variables for categorical variables
local catvars marst educ empstatd
foreach var of local catvars {
	quietly tabulate `var', generate(d`var')
} 

// Rename variables for analysis
rename dmarst1 married
rename dmarst2 marriednp
rename dmarst3 separated
rename dmarst4 divorced
rename dmarst5 widowed
rename dmarst6 nmarried
rename deduc1 ncomhs
rename deduc2 hscomplete
rename deduc3 collegend
rename deduc4 associate 
rename deduc5 bachelor
rename deduc6 master
rename dempstatd1 emp
rename dempstatd2 jobnw
rename dempstatd3 armedaw
rename dempstatd4 armedwj
rename dempstatd5 unemp
rename dempstatd6 nlabor

// Label new variables
label var ncomhs "Not completed High school"
label var hscomplete "Completed High school"
label var collegend "Some college but no degree"
label var associate "Associate's degree"
label var bachelor "Bachelor's degree"
label var master "Master's degree or higher"
label var married "Married, spouse present"
label var marriednp "Married, spouse absent"
label var separated "Separated"
label var divorced "Divorced"
label var widowed "Widowed"
label var nmarried "Never married/single"
label var emp "At work"
label var jobnw "Has a job, not working"
label var armedaw "Armed forces, at work"
label var armedwj "Armed forces, not at work but with job"
label var unemp "Unemployed"
label var nlabor "Not in the labor force"

// Save the cleaned data
save Trang_Nguyen_cleandata, replace
