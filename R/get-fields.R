#' Get list of retrievable fields
#'
#' This function returns a vector of fields that you can retrieve from a given
#' API endpoint (i.e., the fields you can pass to the \code{fields} argument in
#' \code{\link{search_pv}}). You can limit these fields to only cover certain
#' entity group(s) as well (which is recommended, given the large number of
#' possible fields for each endpoint).
#'
#' @param endpoint The API endpoint whose field list you want to get. See
#'   \code{\link{get_endpoints}} for a list of the 23 endpoints.
#' @param groups A character vector giving the group(s) whose fields you want
#'   returned. A value of \code{NULL} indicates that you want all of the
#'   endpoint's fields (i.e., do not filter the field list based on group
#'   membership). See the Nested Fields listed online to see which groups you
#'   can specify for a given endpoint (e.g., the
#'   \href{https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference/#patent}{patents
#'   endpoint table}), or use the \code{fieldsdf} table
#'   (e.g., \code{unique(fieldsdf[fieldsdf$endpoint == "patent", "group"])}).
#'   An empty string can also be specified to return all top level
#'   (non-nested) fields for the endpoint.
#'
#' @return A character vector with field names.
#'
#' @examples
#' # Get all top level (non-nested) fields for the patent endpoint:
#' fields <- get_fields(endpoint = "patent", groups = c(""))
#'
#' # ...Then pass to search_pv:
#' \dontrun{
#'
#' search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' }
#' # Get all patent and assignee-level fields for the patent endpoint:
#' fields <- get_fields(endpoint = "patent", groups = c("assignees", ""))
#'
#' \dontrun{
#' # ...Then pass to search_pv:
#' search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' }
#'
#' @export
get_fields <- function(endpoint, groups = NULL) {
  validate_endpoint(endpoint)
  if (is.null(groups)) {
    fieldsdf[fieldsdf$endpoint == endpoint, "field"]
  } else {
    validate_groups(endpoint, groups = groups)
    fieldsdf[fieldsdf$endpoint == endpoint & fieldsdf$group %in% groups, "field"]
  }
}

#' Get endpoints
#'
#' This function reminds the user what the possible PatentSearch API endpoints
#' are.  (Note that the API was originally know as the PatentsView API.)
#'
#' @return A character vector with the names of each endpoint.
#' @export
get_endpoints <- function() {
  # now the endpoints are singular
  # note that now there are two rel_app_texts, one under patents and one under publications
  c(
    "assignee",
    "brf_sum_text",
    "claim",
    "cpc_class",
    "cpc_group",
    "cpc_subclass",
    "detail_desc_text",
    "draw_desc_text",
    "inventor",
    "ipc",
    "location",
    "patent",
    "patent/attorney",
    "patent/foreign_citation",
    "patent/rel_app_text",
    "patent/us_application_citation",
    "patent/us_patent_citation",
    "publication",
    "publication/rel_app_text",
    "uspc_mainclass",
    "uspc_subclass",
    "wipo"
  )
}
