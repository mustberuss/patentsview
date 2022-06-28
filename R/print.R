#' @export
print.pv_request <- function(x, ...) {
  cat(
    "#### An HTTP request where:\n\n",
    "Method: ", x$method, "\n",
    "URL: ", x$url,
    ifelse("body" %in% names(x), paste0("\nBody: ", x$body), ""),
    sep = ""
  )
}

#' @export
print.pv_data_result <- function(x, ...) {
  df <- x[[1]]

  k <- vapply(names(df), function(y) class(df[, y]), FUN.VALUE = character(1))

  dat_level <- c(
    assignees = "an assignee",
    application_citations = "an application citation",
    cpc_group = "a CPC group", 
    cpc_subgroup = "a CPC sub group", 
    cpc_subsections = "a CPC subsection", 
    inventors = "an inventor", 
    locations = "a location",
    nber_categories = "a NBER category", 
    nber_subcategories = "a NBER subcategory",
    patent = "a patent", 
    patents = "a patent",
    patent_citations = "a patent citation",
    uspc_mainclasses = "a USPC main class",
    uspc_subclasses = "a USPC sub class"
  )

  lst <- ifelse("list" %in% k, " (with list column(s) inside) ", " ")
  print(names(x)[1])

  cat(
    "#### A list with a single data frame", lst, "on ",
    dat_level[[names(x)[1]]], " level:\n\n",
    sep = ""
  )

  utils::str(
    x, vec.len = 1, max.level = 2, give.attr = FALSE, strict.width = "cut"
  )
}

#' @export
print.pv_relay_db <- function(x, ...) {
  utils::str(
    x, vec.len = 1, max.level = 2, give.attr = FALSE, strict.width = "cut"
  )
}

#' @export
print.pv_query_result <- function(x, ...) {
  res_vec <- unlist(x)
  cat(
    "#### Distinct entity counts across all downloadable pages of output:\n\n",
    paste0(names(res_vec), " = ", format_num(res_vec), collapse = ", "),
    sep = ""
  )
}

#' @export
print.pv_result <- function(x, ...) {
  print(x[1])
  print(x[2])
}

#' @export
print.pv_query <- function(x, ...) cat(jsonlite::toJSON(x, auto_unbox = TRUE))
