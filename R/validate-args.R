#' @noRd
validate_endpoint <- function(endpoint) {
  ok_ends <- get_endpoints()
  asrt(
    all(endpoint %in% ok_ends, length(endpoint) == 1),
    "endpoint must be one of the following: ", paste(ok_ends, collapse = ", ")
  )
}

#' @noRd
validate_args <- function(api_key, fields, endpoint, method, 
                          sort, after, size, all_pages) {
  asrt(
    !identical(api_key, ""),
    "The new version of the API requires an API key"
  )

  flds_flt <- fieldsdf[fieldsdf$endpoint == endpoint, "field"]

  # Now the API allows the group name to be requested to get all of its nested fields
  # ex.: "assignees" on the patent endpoint gets you all of the assignee fields
  # twist: in fieldsdef top level/unnested fields have an empty string as their group,
  # which wouldn't be valid here
  groups <- unique(fieldsdf[fieldsdf$endpoint == endpoint, c("group")])
  flds_flt <- append(flds_flt, groups[!(groups %in% c(""))])

  asrt(
    all(fields %in% flds_flt),
    "Bad field(s): ", paste(fields[!(fields %in% flds_flt)], collapse = ", ")
  )

  validate_endpoint(endpoint)

  asrt(
    all(method %in% c("GET", "POST"), length(method) == 1),
    "method must be either 'GET' or 'POST'"
  )

  asrt(
    all(is.numeric(size), length(size) == 1, size <= 1000),
    "size must be a numeric value less than or equal to 1,000"
  )
  if (!is.null(sort)) {
    asrt(
      all(
        all(names(sort) %in% fields), all(sort %in% c("asc", "desc")),
        !is.list(sort)
      ),
      "sort has to be a named character vector and each name has to be ",
      "specified in the field argument. See examples"
    )
  }

  asrt(
    any(after == "", !all_pages),
    "after cannot be set when all_pages = TRUE"
  )
}

#' @noRd
validate_groups <- function(endpoint, groups) {
  ok_grps <- unique(fieldsdf[fieldsdf$endpoint == endpoint, c("group")])

  asrt(
    all(groups %in% ok_grps),
    "groups for the ", endpoint, " endpoint must be one or more of the following: ",
    paste(error_groups(ok_grps), collapse = ", ")
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
deprecate_warn_all <- function(error_browser, subent_cnts, mtchd_subent_only, page, per_page) {
  if (!is.null(error_browser)) {
    lifecycle::deprecate_warn(when = "0.2.0", what = "search_pv(error_browser)")
  }
  # Was previously defaulting to FALSE and we're still defaulting to FALSE to
  # mirror the fact that the API doesn't support subent_cnts. Warn only if user
  # tries to set subent_cnts to anything other than FALSE (test cases try NULL and 7)
  if (!(is.logical(subent_cnts) && isFALSE(subent_cnts))) {
    lifecycle::deprecate_warn(
      when = "1.0.0",
      what = "search_pv(subent_cnts)",
      details = "The new version of the API does not support subentity counts."
    )
  }
  # Was previously defaulting to TRUE and now we're defaulting to FALSE, hence
  # we're being more chatty here than with subent_cnts.
  if (lifecycle::is_present(mtchd_subent_only)) {
    lifecycle::deprecate_warn(
      when = "1.0.0",
      what = "search_pv(mtchd_subent_only)",
      details = "Non-matched subentities will always be returned under the new
      version of the API"
    )
  }

  if (lifecycle::is_present(per_page)) {
    lifecycle::deprecate_warn(
      when = "0.3.0",
      what = "search_pv(per_page)",
      details = "The new version of the API uses 'size' instead of 'per_page'"
    )
  }

  if (lifecycle::is_present(page)) {
    lifecycle::deprecate_warn(
      when = "0.3.0",
      what = "search_pv(page)",
      details = "The new version of the API does not support the page parameter"
    )
  }
}

#' @noRd
error_groups <- function(groups) {
  # on an error explain the empty string is for top level attributes
  # throw a different error if there aren't any nested groups?

  error_grps <- replace(groups, groups == "", '"" (for top level attributes)')
}
