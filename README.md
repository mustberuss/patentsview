patentsview
================

> An R client to the PatentsView API

[![](http://badges.ropensci.org/112_status.svg)](https://github.com/ropensci/software-review/issues/112)
[![R-CMD-check](https://github.com/ropensci/patentsview/workflows/R-CMD-check/badge.svg)](https://github.com/ropensci/patentsview/actions)
[![CRAN version](http://www.r-pkg.org/badges/version/patentsview)](https://cran.r-project.org/package=patentsview)
[![patentsview status badge](https://ropensci.r-universe.dev/patentsview/badges/version)](https://ropensci.r-universe.dev/patentsview)

## Installation

You can get the stable version from CRAN:


``` r
install.packages("patentsview")
```

Or the development version from GitHub:


``` r
if (!"devtools" %in% rownames(installed.packages())) 
  install.packages("devtools")

devtools::install_github("ropensci/patentsview")
```

Or the latest from r-universe:

``` r
install.packages("patentsview", repos = c("https://ropensci.r-universe.dev", "https://cloud.r-project.org"))
```
## Basic usage

The [PatentsView API](https://patentsview.org/apis/api-endpoints) provides an interface to a disambiguated version of USPTO. The `patentsview` R package provides one main function, `search_pv()`, to make it easy to interact with the API:


``` r
library(patentsview)

search_pv(query = '{"_gte":{"patent_date":"2007-01-01"}}')
#> $data
#> #### A list with a single data frame on patents level:
#> 
#> List of 1
#>  $ patents:'data.frame':	1000 obs. of  3 variables:
#>   ..$ patent_id   : chr [1:1000] "10631087" ...
#>   ..$ patent_title: chr [1:1000] "Method and device for voice operated contro"..
#>   ..$ patent_date : chr [1:1000] "2020-04-21" ...
#> 
#> $query_results
#> #### Distinct entity counts across all downloadable pages of output:
#> 
#> total_hits = 5,452,372
```

## Learning more

Head over to the package's [webpage](https://docs.ropensci.org/patentsview/index.html) for more info, including:

* A [getting started vignette](https://docs.ropensci.org/patentsview/articles/getting-started.html) for first-time users. The package was also introduced in an [rOpenSci blog post](https://ropensci.org/blog/2017/09/19/patentsview/).
* An in-depth tutorial on [writing queries](https://docs.ropensci.org/patentsview/articles/writing-queries.html)
* A list of [basic examples](https://docs.ropensci.org/patentsview/articles/examples.html)
* Two examples of data applications (e.g., a brief analysis of the [top assignees](https://docs.ropensci.org/patentsview/articles/top-assignees.html) in the field of databases)
