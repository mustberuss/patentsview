% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/search-pv.R
\name{search_pv}
\alias{search_pv}
\title{Search PatentsView}
\usage{
search_pv(
  query,
  fields = NULL,
  endpoint = "patent",
  subent_cnts = FALSE,
  mtchd_subent_only = lifecycle::deprecated(),
  page = lifecycle::deprecated(),
  per_page = lifecycle::deprecated(),
  size = 1000,
  after = NULL,
  all_pages = FALSE,
  sort = NULL,
  method = "GET",
  error_browser = NULL,
  api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
  ...
)
}
\arguments{
\item{query}{The query that the API will use to filter records. \code{query}
can come in any one of the following forms:
\itemize{
\item A character string with valid JSON. \cr
E.g., \code{'{"_gte":{"patent_date":"2007-01-04"}}'}

\item A list which will be converted to JSON by \code{search_pv}. \cr
E.g., \code{list("_gte" = list("patent_date" = "2007-01-04"))}

\item An object of class \code{pv_query}, which you create by calling one
of the functions found in the \code{\link{qry_funs}} list...See the
\href{../articles/writing-queries.html}{writing
queries vignette} for details.\cr
E.g., \code{qry_funs$gte(patent_date = "2007-01-04")}
}}

\item{fields}{A character vector of the fields that you want returned to you.
A value of \code{NULL} indicates to the API that it should return the default fields
for that endpoint. Acceptable fields for a given endpoint can be found at the API's
online documentation (e.g., check out the field list for the
\href{https://search.patentsview.org/docs/docs/Search\%20API/SearchAPIReference#patent}{patents
endpoint}) or by viewing the \code{fieldsdf} data frame
(\code{View(fieldsdf)}). You can also use \code{\link{get_fields}} to list
out the fields available for a given endpoint.

Nested fields can be fully qualified, e.g., "application.filing_date" or the
group name can be used to retrieve all of its nested fields, E.g. "application".
The latter would be similar to passing \code{get_fields("patent", group = "application")}
except it's the API that decides what fields to return.}

\item{endpoint}{The web service resource you wish to search. Use
\code{get_endpoints()} to list the available endpoints.}

\item{subent_cnts}{\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} This is always FALSE in the
new version of the API as the total counts of unique subentities is no longer available.}

\item{mtchd_subent_only}{\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} This is always
FALSE in the new version of the API as non-matched subentities
will always be returned.}

\item{page}{\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} The new version of the API does not use
\code{page} as a parameter for paging, it uses \code{after}.}

\item{per_page}{\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} The API now uses \code{size}}

\item{size}{The number of records that should be returned per page. This
value can be as high as 1,000 (e.g., \code{size = 1000}).}

\item{after}{A list of sort key values that defaults to NULL.  This
exposes the API's paging parameter for users who want to implement their own
paging. It cannot be set when \code{all_pages = TRUE} as the R package manipulates it
for users automatically. See \href{../articles/result-set-paging.html}{result set paging}}

\item{all_pages}{Do you want to download all possible pages of output? If
\code{all_pages = TRUE}, the value of \code{size} is ignored.}

\item{sort}{A named character vector where the name indicates the field to
sort by and the value indicates the direction of sorting (direction should
be either "asc" or "desc"). For example, \code{sort = c("patent_id" =
 "asc")} or \cr\code{sort = c("patent_id" = "asc", "patent_date" =
 "desc")}. \code{sort = NULL} (the default) means do not sort the results.
You must include any fields that you wish to sort by in \code{fields}.}

\item{method}{The HTTP method that you want to use to send the request.
Possible values include "GET" or "POST". Use the POST method when
your query is very long (say, over 2,000 characters in length).}

\item{error_browser}{\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}}}

\item{api_key}{API key, it defaults to Sys.getenv("PATENTSVIEW_API_KEY"). Request a key
\href{https://patentsview.org/apis/keyrequest}{here}.}

\item{...}{Curl options passed along to httr2's \code{\link[httr2]{req_options}}
when we do GETs or POSTs.}
}
\value{
A list with the following three elements:
\describe{
\item{data}{A list with one element - a named data frame containing the
data returned by the server. Each row in the data frame corresponds to a
single value for the primary entity. For example, if you search the
assignee endpoint, then the data frame will be on the assignee-level,
where each row corresponds to a single assignee. Fields that are not on
the assignee-level would be returned in list columns.}

\item{query_results}{Entity counts across all pages of output (not just
the page returned to you).}

\item{request}{Details of the HTTP request that was sent to the server.
When you set \code{all_pages = TRUE}, you will only get a sample request.
In other words, you will not be given multiple requests for the multiple
calls that were made to the server (one for each page of results).}
}
}
\description{
This function makes an HTTP request to the PatentsView API for data matching
the user's query.
}
\examples{
\dontrun{

search_pv(query = '{"_gt":{"patent_year":2010}}')

search_pv(
  query = qry_funs$gt(patent_year = 2010),
  fields = get_fields("patent", c("patents", "assignees"))
)

search_pv(
  query = qry_funs$gt(patent_year = 2010),
  method = "POST",
  fields = "patent_id",
  sort = c("patent_id" = "asc")
)

search_pv(
  query = qry_funs$eq(inventor_name_last = "Crew"),
  endpoint = "inventor",
  all_pages = TRUE
)

search_pv(
  query = qry_funs$contains(assignee_individual_name_last = "Smith"),
  endpoint = "assignee"
)

search_pv(
  query = qry_funs$contains(inventors.inventor_name_last = "Smith"),
  endpoint = "patent",
  timeout = 40
)

search_pv(
  query = qry_funs$eq(patent_id = "11530080"),
  fields = "application"
)
}

}
