#' Get list of retrievable fields
#'
#' Get a vector of fields that you can retrieve from a given
#' API endpoint (i.e., the fields you can pass to the \code{fields} argument in
#' \code{\link{search_pv}}). You can limit these fields to only cover certain
#' entity group(s) as well (which is recommended, given the large number of
#' possible fields for each endpoint).
#'
#' @param endpoint The API endpoint whose field list you want to get. See
#'   \code{\link{get_endpoints}} for a list of the 27 endpoints.
#' @param groups A character vector giving the group(s) whose fields you want
#'   returned. A value of \code{NULL} indicates that you want all of the
#'   endpoint's fields (i.e., do not filter the field list based on group
#'   membership). Use the \code{fieldsdf} table (e.g.,
#'   \code{unique(fieldsdf[fieldsdf$endpoint == "patent", "group"])}) to see
#'   which groups you can specify for a given endpoint.
#'
#' @return A character vector with field names.
#'
#' @examples
#' # Get all top level (non-nested) fields for the patent endpoint:
#' fields <- get_fields(endpoint = "patent", groups = "patents")
#'
#' # ...Then pass to search_pv:
#' \dontrun{
#'
#' search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' }
#' # Get patent and assignee-level fields for the patent endpoint:
#' fields <- get_fields(endpoint = "patent", groups = c("assignees", "patents"))
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
#' This function reminds the user what the possible PatentsView API endpoints
#' are.
#'
#' @return A character vector with the names of each endpoint.
#' @export
get_endpoints <- function() {
  unique(fieldsdf$endpoint)
}

#' Get OK primary key
#'
#' This function suggests column(s) that you could use for the \code{pk} argument
#' in \code{\link{unnest_pv_data}}, based on the endpoint you searched.
#' It will return a potential primary key - either a single column or a
#' composite set of columns - for the endpoint.
#'
#' @param endpoint The endpoint which you would like to know a potential primary
#'   key for.
#'
#' @return The column names that represent a single row for the given endpoint.
#'
#' @examples
#' get_ok_pk(endpoint = "inventor")
#' get_ok_pk(endpoint = "patent/foreign_citation")
#'
#' @export
get_ok_pk <- function(endpoint) {
  pks <- list(
    "assignee" = "assignee_id",
    "cpc_class" = "cpc_class_id",
    "cpc_group" = "cpc_group_id",
    "cpc_subclass" = "cpc_subclass_id",
    "g_brf_sum_text" = "patent_id",
    "g_claim" = c("patent_id", "claim_sequence"),
    "g_detail_desc_text" = "patent_id",
    "g_draw_desc_text" = c("patent_id", "draw_desc_sequence"),
    "inventor" = "inventor_id",
    "ipc" = "ipc_id",
    "location" = "location_id",
    "patent" = "patent_id",
    "patent/attorney" = "attorney_id",
    "patent/foreign_citation" = c("patent_id", "citation_sequence"),
    "patent/other_reference" = c("patent_id", "reference_sequence"),
    "patent/rel_app_text" = "patent_id",
    "patent/us_application_citation" = c("patent_id", "citation_sequence"),
    "patent/us_patent_citation" = c("patent_id", "citation_sequence"),
    "pg_brf_sum_text" = "document_number",
    "pg_claim" = c("document_number", "claim_sequence"),
    "pg_draw_desc_text" = c("document_number", "draw_desc_sequence"),
    "pg_detail_desc_text" = "document_number",
    "publication" = "document_number",
    "publication/rel_app_text" = "document_number",
    "uspc_mainclass" = "uspc_mainclass_id",
    "uspc_subclass" = "uspc_subclass_id",
    "wipo" = "wipo_id"
  )
  pks[endpoint][[1]]
}
