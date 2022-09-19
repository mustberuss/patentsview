---
title: "patentsview"
output: github_document
---



# pkgdown <img src="man/figures/logo.png" align="right" height="134.5" />
> An R client to the PatentsView API

[![](http://badges.ropensci.org/112_status.svg)](https://github.com/ropensci/software-review/issues/112)
[![R-CMD-check](https://github.com/ropensci/patentsview/workflows/R-CMD-check/badge.svg)](https://github.com/ropensci/patentsview/actions)
[![CRAN version](http://www.r-pkg.org/badges/version/patentsview)](https://cran.r-project.org/package=patentsview)
[![](https://mustberuss.r-universe.dev/badges/patentsview)](https://mustberuss.r-universe.dev/ui#package:patentsview)

## Installation

You can get the stable version for the original version of the API from CRAN:


```r
install.packages("patentsview")
```

Or the development version from GitHub:


```r
if (!"devtools" %in% rownames(installed.packages())) {
  install.packages("devtools")
}

devtools::install_github("ropensci/patentsview")
```
Or the R package for the new version of the API from github:
```
if (!"devtools" %in% rownames(installed.packages())) {
  devtools::install_github("ropensci/patentsview@api-redesign")
}
```
Or the R package for the new version of the API from r-universe:


```r
options(repos = c(
   patentsview = 'https://mustberuss.r-universe.dev/',
   CRAN = 'https://cloud.r-project.org'))

install.packages('patentsview')
```
## Important API Change

The new version of the API requires an api key, or all of your requests will be blocked.  An API key can be optained [here](https://patentsview.org/apis/keyrequest).  The updated R package will look for an environmental variable PATENTSVIEW_API_KEY set to the value of your key. For windows it would be
```
set PATENTSVIEW_API_KEY=my_keys_value_without quotes
```

See [this page](https://mustberuss.github.io/patentsview/articles/api-changes.html) about the change. The navigation there will get you to the updated vignettes and reference pages.

## Basic usage

The [PatentsView API](https://patentsview.org/apis/api-endpoints) provides an interface to a disambiguated version of USPTO. The `patentsview` R package provides one main function, `search_pv()`, to make it easy to interact with the API:


```r
library(patentsview)

search_pv(query = '{"_gte":{"patent_date":"2007-01-01"}}')
#> $data
#> [1] "patents"
#> #### A list with a single data frame (with list column(s) inside) on a patent level:
#> 
#> List of 1
#>  $ patents:'data.frame':	1000 obs. of  5 variables:
#>   ..$ patent_number     : chr [1:1000] "10000000" ...
#>   ..$ patent_title      : chr [1:1000] "Coherent LADAR using intra-pixel quad"..
#>   ..$ patent_date       : chr [1:1000] "2018-06-19" ...
#>   ..$ assignees_at_grant:List of 1000
#>   ..$ inventors_at_grant:List of 1000
#> 
#> $query_results
#> #### Distinct entity counts across all downloadable pages of output:
#> 
#> total_hits = 4,019,907
```

## Learning more

Head over to the package's [webpage](https://docs.ropensci.org/patentsview/index.html) for more info, including:

* A [getting started vignette](https://docs.ropensci.org/patentsview/articles/getting-started.html) for first-time users. The package was also introduced in an [rOpenSci blog post](https://ropensci.org/blog/2017/09/19/patentsview/).
* An in-depth tutorial on [writing queries](https://docs.ropensci.org/patentsview/articles/writing-queries.html)
* A list of [basic examples](https://docs.ropensci.org/patentsview/articles/examples.html)
* Two examples of data applications (e.g., a brief analysis of the [top assignees](https://docs.ropensci.org/patentsview/articles/top-assignees.html) in the field of databases)
