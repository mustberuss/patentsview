#' @noRd
stop2 <- function(...) stop(..., call. = FALSE)

#' @noRd
asrt <- function(expr, ...) if (!expr) stop2(...)

#' @noRd
parse_resp <- function(resp) {
  j <- httr::content(resp, as = "text", encoding = "UTF-8")
  jsonlite::fromJSON(
    j, simplifyVector = TRUE, simplifyDataFrame = TRUE, simplifyMatrix = TRUE
  )
}

#' @noRd
format_num <- function(x) format(
    x, big.mark = ",", scientific = FALSE, trim = TRUE
  )

#' @noRd
validate_endpoint <- function(endpoint) {
  ok_ends <- get_endpoints()

  asrt(
    all(endpoint %in% ok_ends, length(endpoint) == 1),
    "endpoint must be one of the following: ", paste(ok_ends, collapse = ", ")
  )
}

#' @noRd
validate_groups <- function(groups) {
  ok_grps <- unique(fieldsdf$group)
  asrt(
    all(groups %in% ok_grps),
    "group must be one of the following: ", paste(ok_grps, collapse = ", ")
  )
}

#' @noRd
validate_pv_data <- function(data) {
  asrt(
    "pv_data_result" %in% class(data),
    "Wrong input type for data...See example for correct input type"
  )
}

#' @noRd
to_singular <- function(data) {

   data_to_endpoint <- c(
      "application_citations" = "application_citation",
      "assignees" = "assignee",
      "cpc_groups" = "cpc_group",
      "cpc_subgroups" = "cpc_subgroup",
      "cpc_subsections" = "cpc_subsection",
      "inventors" = "inventor",
      "locations" = "location",
      "nber_categories" = "nber_category",
      "nber_subcategories" = "nber_subcategory",
      "patents" = "patent",
      "patent_citations" = "patent_citation",
      "uspc_mainclasses" = "uspc_mainclass",
      "uspc_subclasses" = "uspc_subclass")

   if(data %in% names(data_to_endpoint))
      data_to_endpoint[[data]]
   else
      NA
}

#' @noRd
to_plural <- function(data) {

   endpoint_to_data <- c(
      "application_citation" = "application_citations",
      "assignee" = "assignees",
      "cpc_group" = "cpc_groups",
      "cpc_subgroup" = "cpc_subgroups",
      "cpc_subsection" = "cpc_subsections",
      "inventor" = "inventors",
      "location" = "locations",
      "nber_category" = "nber_categories",
      "nber_subcategory" = "nber_subcategories",
      "patent" = "patents",
      "patent_citation" = "patent_citations",
      "uspc_mainclass" = "uspc_mainclasses",
      "uspc_subclass" = "uspc_subclasses")

   if(data %in% names(endpoint_to_data))
      endpoint_to_data[[data]]
   else
      NA
}

#' @noRd
is_plural_endpoint <- function(data) {
  
   x = to_singular(data)
   !is.na(to_singular(data))
}

