# Cleandata
Stata program that label variables and drops pii using an excel input

## Overview

Data officers/Managers might want to de-identify data and also label variables with the repeat group in mind. 
This stata program for a last stage data cleaning. labeling and de-identifying data

## installation(Beta)

```stata
net install cleandata, all replace ///
	from("https://raw.githubusercontent.com/mbidinlib/cleandata/master/ado")
```

## Syntax

* cleandata using "path to xls", [wide] [long] [xls] [dta] pii(name of pii column)


