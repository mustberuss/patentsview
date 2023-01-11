#' Get list of retrievable fields
#'
#' This function returns a vector of fields that you can retrieve from a given
#' API endpoint (i.e., the fields you can pass to the \code{fields} argument in
#' \code{\link{search_pv}}). You can limit these fields to only cover certain
#' entity group(s) as well (which is recommended, given the large number of
#' possible fields for each endpoint).
#'
#' @param endpoint The API endpoint whose field list you want to get. See
#'   \code{\link{get_endpoints}} for a list of the 7 endpoints.
#' @param groups A character vector giving the group(s) whose fields you want
#'   returned. A value of \code{NULL} indicates that you want all of the
#'   endpoint's fields (i.e., do not filter the field list based on group
#'   membership). See the field tables located online to see which groups you
#'   can specify for a given endpoint (e.g., the
#'   \href{https://patentsview.org/apis/api-endpoints/patents}{patents
#'   endpoint table}), or use the \code{fieldsdf} table
#'   (e.g., \code{unique(fieldsdf[fieldsdf$endpoint == "patents", "group"])}).
#'
#' @return A character vector with field names.
#'
#' @examples
#' # Get all assignee-level fields for the patents endpoint:
#' fields <- get_fields(endpoint = "patents", groups = "assignees")
#'
#' # ...Then pass to search_pv:
#' \dontrun{
#'
#' search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' }
#' # Get all patent and assignee-level fields for the patents endpoint:
#' fields <- get_fields(endpoint = "patents", groups = c("assignees_at_grant", "patents"))
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
    validate_groups(groups = groups)
    fieldsdf[fieldsdf$endpoint == endpoint & fieldsdf$group %in% groups, "field"]
  }
}

#' Get endpoints
#'
#' This function reminds the user what the possible PatentsView API endpoints
#' are.
#'
#' @return A character vector with the names of each endpoint.
#' @export
get_endpoints <- function() {
  c(
    "patent/us_application_citations", "assignees", "cpc_classes", "cpc_subclasses",
    "cpc_groups", "inventors", "nber_categories",
    "nber_subcategories", "patent/us_patent_citations", "patents",
    "uspc_subclasses", "uspc_mainclasses",
    "patent/attorneys", "patent/foreign_citations", "patent/rel_app_texts",
    "locations", "wipo", "ipcs" #, patent/otherreference
  )
}

# Now for paging there has to be a sort field.  Here we'll provide defaults
# for each endpoint if the user does not specify one

# most of the nested endpoints use patent_id, patent/attorneys is the exception
USE_PATENT_ID <- c("patent/us_application_citations", "patent/us_patent_citations", 
"patent/rel_app_texts", "patent/foreign_citations")

#' @noRd
get_default_sort <- function(endpoint) {

   if(endpoint %in% USE_PATENT_ID) {
      key <- "patent_id"
   }
   else
   {
      key <- sub("^patent/", "", endpoint)
      key <- to_singular(key)
      key <- paste0(key,"_id")
   }

   default <- c("asc")
   names(default) = key
   default
}
