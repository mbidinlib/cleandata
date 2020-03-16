
*! Innovations for Poverty Action March 2020

*****************************************************
*This program reads an xlx form and                 *
*Eports a dataset containing variables that ate PII *
*************************************************** *

cap program drop ctoimportpii  //drop program if exists

program define ctoimportpii

    syntax using/ , [Long] [Wide] [dta] [xlsx] [xls] [PIIvar(name)]
	
	qui{
			* give an arror if Long or wide is not specified
		if "`wide'" != "wide" && "`long'" != "long"  {
			noi di as err "SPecify long or wide"
			exit
		}
		
			* Check if the using file is excel
		if !regexm(`"`using'"', ".xls$|.xlsx$|.xlsm$") {
			noi di as err "File extention error: the using file should be a .xls or .xlsx or .xlms file"
			exit
		}
			*sets local for piivariable	
		if mi("`piivar'")  loc piivar = "sensitive"
				
			*import xls form and set the pii column as local
		import excel using "`using'" , clear first
			
			*Check if pii column exists
		cap confirm variable `piivar'
		if _rc{
			noi di as err "Error in xls form: sensitive/pii variable expected not found in data"
			noi di as err "Specify the column for pii variable [piivar(varname)]"
			exit
		}
		
		* saves xls form into a temporary file
		gen question_order =_n    // order of question
		tempfile xlsdata
		save `xlsdata', replace
		
				* keep relevant and sensitive rows
		drop if (mi(type) | regexm(type, " group") | type == "note") | ///
				 (`piivar' != "yes" && `piivar' != "Yes" ///
				 && `piivar' != "YES"  && !regexm(type," repeat"))
		
			* Export For long format dataset
		if "`long'" == "long" {
			noi di "Importing PII variables for long format dataset"
			noi di "{hline}"
			gen new_name = name
		}
		
		
		* Export for wide format dataset
		if "`wide'" == "wide"{
			noi di "Importing PII variables for Wide format dataset"
			noi di "{hline}"
			
			* Preserve dataset and save repeat groups into a local
			preserve
			keep if regexm(type, "repeat")
			levelsof name, loc(repeat_names)
			restore
			gen new_name = name		 // New variable name
			
			* Loop through all repeat groups and add a wild card to their names
			foreach j of loc repeat_names{
				*di `"`j'"'
				qui sum question_order if regexm(type, "begin") & name == `"`j'"'
				loc start_rep = `r(min)'
				qui sum question_order if regexm(type, "end") & name == `"`j'"'
				loc end_rep = `r(min)'
				di `start_rep' _column(10) `end_rep'
				* Adds _* to the repeats
				replace new_name = new_name + "_*" if _n > `start_rep' & _n < `end_rep'
				*replace name = new_name
			}
			
		}
		
		* Export and save output
		drop if regexm(type, "repeat")
		levelsof name, local(pii_vars) 	// keeps the pii vars as local
		
		tempfile pii_data
		save `pii_data', replace
		ren new_name pii_var_name
			
		if "`xls'" == "xls" | "`xlsx'" == "xlsx"{
			noi di "Exporting sheet with suspected pii variables"
			noi export excel pii_var_name label using "pii_variables.xlsx", ///
				sheet(pii_variable) sheetreplace firstrow(variables)
		}
		else {
			keep pii_var_name label
			noi di "Saving dataset of PII variables"
			noi save  "pii_variables.dta", replace
		}
		
		* Loook up into clculate fields	
		use `xlsdata', clear
		gen suspected = .
		
		* loop up and see if any pii variable is matched
		foreach j of loc pii_vars{
			di `"`j'"'
			replace suspected = 1 if regexm(calculation, "`j'") 
		}
		
		merge 1:1 question_order using `pii_data'
		drop if _merge ==3 | mi(suspected)
		ren name var_name
			
		* Save suspected pii variables
		if "`xls'" == "xls" | "`xlsx'" == "xlsx"{
			noi di "Exporting sheet with suspected pii variables"
			noi export excel var_name label using "pii_variables.xlsx", ///
				sheet(suspected_pii) sheetreplace firstrow(variables)
		}
		else {
			keep var_name label
			noi di "Saving dataset of suspected pii variables"
			noi save  "suspected_pii.dta", replace
		}
		
	
	}
	
end




 
