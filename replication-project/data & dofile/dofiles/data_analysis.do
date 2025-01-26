*********************** Replication Project_Analysis ***************************

clear all
set more off
cd "D:\Study\MSc ECON-PSU\2. 2nd academic year\1. Fall 2024\EC575 - Applied Advance Econometrics\0. HWs and Assignments\0. Final project\Submission"
use Trang_Nguyen_cleandata, clear

******** SUMMARY STATISTICS
*** Pseudo-panels size for each cohort of interest
// Generate a summary table for sample size
tab bcohort year, missing
asdoc tab bcohort year, missing title(Pseudo-panels size in the ACS) ///
	save(sample_size_summary.doc) replace

*** Summary statistic table disaggregated for cohorts of interest
table () (bcohort), ///
	stat(mean nchild age) ///
	stat(fvpercent childless marst educ empstatd) ///
	nformat(%8.2f mean) ///
	sformat("%s%%" fvpercent) name(sumtable) replace ///
	style(table-1)

collect set sumtable
collect style cell, halign(left)
collect style cell, border( right, pattern(nil) )
collect style cell, border( left, pattern(nil) )
collect preview
collect export sumtable.docx, replace

*** Draw the graph to depict the trend for childlessness
// Recleaning the data for graph drawing
clear all
use replication_data_ipums, clear

keep if inrange(birthyr, 1965, 1973) // Keep the cohort of interest for 3 groups: P, C, T
keep if race == 1 // Keep observations of white women
drop if gq == 3 | gq == 4 // Keep non instititionalized women
keep if inrange(age, 31, 39) // Keep the age range of interest
keep year statefip nchild sex age marst birthyr race educ educd empstat empstatd 

gen childless = (nchild == 0)
label var childless "Childlessness status"

// Create birth cohort variables
gen bcohort =.
replace bcohort = 1 if inrange(birthyr, 1965, 1967)
replace bcohort = 2 if inrange(birthyr, 1968, 1970)
replace bcohort = 3 if inrange(birthyr, 1971, 1973)

// Label the birth cohorts (P, C, T)
label define bcohort_lbl 1 "1965-1967 (P)"
label define bcohort_lbl 2 "1968-1970 (C)", add
label define bcohort_lbl 3 "1971-1973 (T)", add
label values bcohort bcohort_lbl
label var bcohort "Birth cohort"

// Calculate childlessness proportion by age group and birth cohort
collapse (mean) childless, by(bcohort age)
gen clprop = childless * 100

twoway (line clprop age if bcohort == 1, lpattern(solid) lcolor(black) lwidth(medium) ///
           mcolor(black) msize(medium) msymbol(diamond)) ///
       (line clprop age if bcohort == 2, lpattern(dash) lcolor(black) lwidth(medium) ///
           mcolor(black) msize(medium) msymbol(square)) ///
       (line clprop age if bcohort == 3, lpattern(solid) lcolor(black) lwidth(medium) ///
           mcolor(black) msize(medium) msymbol(triangle)) ///
    , ylabel(22(2)34, angle(0) format(%2.0f) labsize(small)) ///
      xtitle("Age") ytitle("%") ///
      legend(order(1 "P" 2 "C" 3 "T") label(1 "P") label(2 "C") label(3 "T")) ///
      title("Childless Proportion: Parallel Trends") 

******** DIFFERENCE-IN-DIFFERENCE ANALYSIS
clear all
use Trang_Nguyen_cleandata, clear

*** Generate new variables to prepare for the final analysis
// Generate the dummy variable "Age37-39"
gen age37_39 = (age>=37 & age<=39)
label variable age37_39 "Age 37-39"

// Generate variable "Treatment"
gen treatment = (bcohort == 3) 
label variable treatment "Treatment cohort"

// Generate the interaction term for causal analysis
gen dd = age37_39*treatment
label variable dd "DD (Age 37-39*Treatment cohort)"


*** Difference-in-difference estimation (Treatment vs. Control group) - Table 2
global ylist childless
global xlist age37_39 treatment dd
global education hscomplete collegend associate bachelor master
global marital marriednp separated divorced widowed nmarried
global employment jobnw armedaw armedwj unemp nlabor

// Variable description table 
asdoc describe $ylist $xlist $education $marital $employment, save(variable_description.doc) replace

// Run the estimation
reg $ylist $xlist if bcohort == 2 | bcohort == 3, robust // Model 1 (Base model)
areg $ylist $xlist if bcohort == 2 | bcohort == 3, absorb(statefip) robust // Model 2 (State fixed effects)
reg $ylist $xlist $education if bcohort == 2 | bcohort == 3, robust // Model 3  (Education)
reg $ylist $xlist $education $marital if bcohort == 2 | bcohort == 3, robust // Model 4 (Education & Marital status)
reg $ylist $xlist $education $marital $employment if bcohort == 2 | bcohort == 3, robust // Model 5 (Education, Marital & Employment status)

// Export into table
reg $ylist $xlist if bcohort == 2 | bcohort == 3, robust // Model 1 (Base model)
outreg2 using table2.doc, replace label title("DID estimates (Treatment vs. Control)") ///
	ctitle(Model 1) addtext(State fixed effects, No) alpha(.001, .01, .05)

areg $ylist $xlist if bcohort == 2 | bcohort == 3, absorb(statefip) robust // Model 2 (State fixed effects)
outreg2 using table2.doc, append label ctitle(Model 2) addtext(State fixed effects, Yes)

reg $ylist $xlist $education if bcohort == 2 | bcohort == 3, robust // Model 3  (Education)
outreg2 using table2.doc, append label ctitle(Model 3) addtext(State fixed effects, No)

reg $ylist $xlist $education $marital if bcohort == 2 | bcohort == 3, robust // Model 4 (Education & Marital status)
outreg2 using table2.doc, append label ctitle(Model 4) addtext(State fixed effects, No)

reg $ylist $xlist $education $marital $employment if bcohort == 2 | bcohort == 3, robust // Model 5 (Education, Marital & Employment status)
outreg2 using table2.doc, append label ctitle(Model 5) addtext(State fixed effects, No)

*** Difference-in-difference estimation (Placebo vs. Control group) - Table 3
gen placebo = (bcohort == 1)
label variable placebo "Placebo Cohort"

gen ddplacebo = age37_39*placebo
label variable ddplacebo "DD (Age 37-39*Placebo cohort)"

global xlistrep age37_39 placebo ddplacebo

// Run the estimation
reg $ylist $xlistrep if bcohort == 1 | bcohort == 2, robust // Model 1 (Base model)
areg $ylist $xlistrep if bcohort == 1 | bcohort == 2, absorb(statefip) robust // Model 2 (State fixed effects)
reg $ylist $xlistrep $education if bcohort == 1 | bcohort == 2, robust // Model 3  (Education)
reg $ylist $xlistrep $education $marital if bcohort == 1 | bcohort == 2, robust // Model 4 (Education & Marital status)
reg $ylist $xlistrep $education $marital $employment if bcohort == 1 | bcohort == 2, robust // Model 5 (Education, Marital & Employment status)

// Export into table
reg $ylist $xlistrep if bcohort == 1 | bcohort == 2, robust // Model 1 (Base model)
outreg2 using table3.doc, replace label title("DID estimates (Placebo vs. Control)") ///
	ctitle(Model 1) addtext(State fixed effects, No) alpha(.001, .01, .05)

areg $ylist $xlistrep if bcohort == 1 | bcohort == 2, absorb(statefip) robust // Model 2 (State fixed effects)
outreg2 using table3.doc, append label ctitle(Model 2) addtext(State fixed effects, Yes)

reg $ylist $xlistrep $education if bcohort == 1 | bcohort == 2, robust // Model 3  (Education)
outreg2 using table3.doc, append label ctitle(Model 3) addtext(State fixed effects, No)

reg $ylist $xlistrep $education $marital if bcohort == 1 | bcohort == 2, robust // Model 4 (Education & Marital status)
outreg2 using table3.doc, append label ctitle(Model 4) addtext(State fixed effects, No)

reg $ylist $xlistrep $education $marital $employment if bcohort == 1 | bcohort == 2, robust // Model 5 (Education, Marital & Employment status)
outreg2 using table3.doc, append label ctitle(Model 5) addtext(State fixed effects, No)
