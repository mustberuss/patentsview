---
output: github_document
---



# patentsview 
> An R client to the PatentsView API, recently renamed the PatentSearch API

[![](http://badges.ropensci.org/112_status.svg)](https://github.com/ropensci/software-review/issues/112)
[![R-CMD-check](https://github.com/ropensci/patentsview/workflows/R-CMD-check/badge.svg)](https://github.com/ropensci/patentsview/actions)
[![CRAN version](http://www.r-pkg.org/badges/version/patentsview)](https://cran.r-project.org/package=patentsview)
[![](https://mustberuss.r-universe.dev/badges/patentsview)](https://mustberuss.r-universe.dev/ui#package:patentsview)

## Installation

You can get the stable version for the original version of the API from CRAN:


``` r
install.packages("patentsview")
```

Or the development version from GitHub (*Currently broken*):


``` r
if (!"devtools" %in% rownames(installed.packages())) {
  install.packages("devtools")
}

devtools::install_github("ropensci/patentsview")
```

Or the R package for the new version of the API from r-universe:


``` r
install.packages("patentsview", repos = c("https://mustberuss.r-universe.dev"))
```

Or the R package for the new version of the API from GitHub:


``` r
if (!"devtools" %in% rownames(installed.packages())) {
  install.packages("devtools")
}

devtools::install_github("mustberuss/patentsview@api-redesign")
```

## Important API Change

The new version of the API requires an API key, or all of your requests will be blocked.  An API key can be obtained [here](https://patentsview.org/apis/keyrequest).  The updated R package will look for an environmental variable PATENTSVIEW_API_KEY set to the value of your key. For windows it would be
```
set PATENTSVIEW_API_KEY=my_keys_value_without quotes
```

See [this page](https://mustberuss.github.io/patentsview/articles/api-changes.html) about 
the change. The navigation there will get you to the updated vignettes and reference pages.

## Basic usage

The [PatentsView API](https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference/#endpoints) provides an interface to a disambiguated version of USPTO. The `patentsview` R package provides one main function, `search_pv()`, to make it easy to interact with the API:


``` r
library(patentsview)

search_pv(query = '{"_gte":{"patent_date":"2007-01-01"}}')
#> Error: The new version of the API requires an API key
```

## Learning more

Head over to the package's [webpage](https://docs.ropensci.org/patentsview/index.html) for more info, including:

* A [getting started vignette](https://mustberuss.github.io/patentsview/articles/getting-started.html) for first-time users. 
* An in-depth tutorial on [writing queries](https://mustberuss.github.io/patentsview/articles/writing-queries.html)
* A list of [basic examples](https://mustberuss.github.io/patentsview/articles/examples.html)
* Two examples of data applications (e.g., a brief analysis of the [top assignees](https://mustberuss.github.io/patentsview/articles/top-assignees.html) in the field of databases)

This package was first introduced in 2017 in an [rOpenSci blog post](https://ropensci.org/blog/2017/09/19/patentsview/) which
used the original version of the API.  The same content, reworked to use the new version 
of the API, is available [here](https://mustberuss.github.io/patentsview/articles/ropensci-blog-post.html).  A draft of a possible Tech Note 
about the new version of the API and R package is [here](https://mustberuss.github.io/patentsview/articles/patentsview-breaking-change.html).
