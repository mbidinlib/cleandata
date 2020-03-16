# shortlist
Stata program that label variables and drops pii using an excel input

## Overview

Data officers/Managers might want to de-identify data and also label variables with the repeat group in mind. 
This stata program de-identify data and labels some variables

## installation(Beta)

```stata
net install shortlist, all replace ///
	from("https://raw.githubusercontent.com/mbidinlib/cleandata/master/ado")
```

## Syntax

* cleandata using "path to xls", [wide] [long] [xls] [dta] pii(name of pii column)


