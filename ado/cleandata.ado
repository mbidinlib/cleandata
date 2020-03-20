*! Innovations for Poverty Action, March 2020

*****************************************************
*This program reads an xlx form and                 *
*Eports a dataset containing variables that ate PII *
*************************************************** *

cap program drop cleandata  //drop program if exists

program define cleandata

    syntax using/ , [XLSForm(string)] [Long] [Wide] [dta] [xlsx] [xls] [PIIvar(name)]
	
	cls 

	qui{
			* give an arror if Long or wide is not specified
		if "`wide'" != "wide" && "`long'" != "long"  {
			noi di as err "SPecify long or wide"
			exit
		}
		
		*noi di "`xlsform'"

			* Check if the using data is in stata format
		if !regexm(`"`using'"', ".dta$") {
			noi di as err "Invalid data format: the using file should be a .dta file"
			exit
		}


		******* De-identify data **************
		***************************************

		if "`piivar'" !="" {
			* Check if the using file is excel
			if !regexm("`xlsform'", ".xls$|.xlsx$|.xlsm$") {
				noi di as err "File extention error: the using file should be a .xls or .xlsx or .xlms file"
				exit
			}
				*sets local for piivariable	
			if mi("`piivar'")  loc piivar = "sensitive"
					
				*import xls form and set the pii column as local
			import excel using "`xlsform'" , clear first
			
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
			
			noi di "{title:De-identifyig Data}"

				* Export For long format dataset
			if "`long'" == "long" {
				noi di "Importing PII variables for long format dataset"
				gen new_name = name
			}
			
			
			* Export for wide format dataset
			if "`wide'" == "wide"{
				noi di "{hline}"
				noi di "Importing PII variables for Wide format dataset"
							
				* Preserve dataset and save repeat groups into a local
				preserve
				keep if regexm(type, "repeat")
				levelsof name, loc(repeat_names)
				restore
				gen new_name = name		 // New variable name
				
				* Loop through all repeat groups and add a wild card to their names
				loc rep  = 0
				foreach j of loc repeat_names{
					loc rep = `rep' + 1
					qui sum question_order if regexm(type, "begin") & name == `"`j'"'
					loc start_rep = `r(min)'
					qui sum question_order if regexm(type, "end") & name == `"`j'"'
					loc end_rep = `r(min)'
					noi di  "Reapeatgroup  `rep'" "   start_row    " `start_rep' _column(10)  "    End_row  " `end_rep'
					* Adds _* to the repeats
					replace new_name = new_name + "_*" if question_order > `start_rep' & question_order < `end_rep'

				}
				
			}
			
			* Export and save output
			drop if regexm(type, "repeat")
			levelsof new_name, local(pii_vars) 	// keeps the pii vars as local
			
			tempfile pii_data
			save `pii_data', replace
			ren new_name pii_var_name
				
			if "`xls'" == "xls" | "`xlsx'" == "xlsx"{
				noi di "Exporting sheet with suspected pii variables"
				export excel pii_var_name label using "pii_variables.xlsx", ///
					sheet(pii_variable) sheetreplace firstrow(variables)
			}
			else {
				keep pii_var_name label
				noi di "Saving dataset of PII variables"
				save  "pii_variables.dta", replace
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
				export excel var_name label using "pii_variables.xlsx", ///
					sheet(suspected_pii) sheetreplace firstrow(variables)
			}
			else {
				keep var_name label
				noi di "Saving dataset of suspected pii variables"
				save  "suspected_pii.dta", replace
			}
			

			********************
			*Drop pii variables*
			********************

			use "`using'", clear
			preserve

			loc drop_num = 0
			foreach k of local  pii_vars{
				*noi di "`k'"
				cap drop `k'
				loc drop_num = `drop_num'  + `r(k_drop)'
				di `drop_num'
			}

			save "de-identified.dta", replace

			restore

			* A report on the dropping
			noi {

				di "{hline}"
				di "Number of Repeat groups" _skip(20) "`rep'"
				di "Number of PII variables droped" _skip(12)  "`drop_num'"

			}
		}
	
		* Save the new data with the drops
		tempfile new_data
		save `new_data', replace
			

		*** Label variables ***
		***********************

		if "`wide'" == "wide"{
			noi di "{hline}"
			noi di "Labeling Variables"
						
			* Preserve dataset and save repeat groups into a local
			use `xlsdata', clear
			drop if mi(name)

			preserve
			keep if regexm(type, "repeat")
			levelsof name, loc(repeat_names)
			restore
			gen new_name = name		 // New variable name
			
			* Loop through all repeat groups and add a wild card to their names
			loc rep  = 0
			foreach j of loc repeat_names{
				loc rep = `rep' + 1
				qui sum question_order if regexm(type, "begin") & name == `"`j'"'
				loc start_rep = `r(min)'
				qui sum question_order if regexm(type, "end") & name == `"`j'"'
				loc end_rep = `r(min)'
				*noi di  "Reapeatgroup  `rep'" "   start_row    " `start_rep' _column(10)  "    End_row  " `end_rep'
				* Adds _* to the repeats
				replace new_name = new_name + "_*" if question_order > `start_rep' & question_order < `end_rep'

			}
			

			*Keep the new variable names and labels for merging
			levelsof new_name, loc(new_names)
			replace name = new_name
			ren label labels__
			ren name name__name
			drop if regexm(type, "repeat|group") | mi(name)
			keep name__name labels__
			gen n_ = _n
			tempfile var_to_label
			save `var_to_label', replace
		
			* Use the data from the drop pii if any
			use "`new_data'", clear
			gen n_ = _n
			merge 1:1  n_ using `var_to_label'


			* rename variables
			loc t_num = _N
			forval val = 1/`t_num' {
							
				loc  var_name =  name__name[`val']
				loc  label_name = labels__[`val']

				*noi di "VName:" "`var_name'"  _column(7) "VLabel: "   `" `label_name'"'

				if "`var_name'" != "" {
					cap label var `var_name' "`label_name'"
						 *label repeat group variables
					if regexm("`k'","_*"){
						loc new_var_name = subinstr("`k'","_*","",4)

						forval j = 1/100{
							cap label var `new_var_name'_`j' "`label_name'"
						}

					} 

				}
			}

			noi di  "Variables labelled successfully"
			* drop program created variables 
			drop if _merge == 2
			drop name__name labels__  _merge

		}

	}
	
end



cleandata using "qp4g_data.dta", xlsform("qp4g_cto.xlsx") wide xls pii(drop_pii)
 
