#' @noRd
parse_resp <- function(resp) {
  j <- httr2::resp_body_string(resp, encoding = "UTF-8")
  jsonlite::fromJSON(
    j,
    simplifyVector = TRUE, simplifyDataFrame = TRUE, simplifyMatrix = TRUE
  )
}

#' @noRd
get_request <- function(resp) {
  structure(
    list(method = resp$request$method, url = resp$request$url),
    class = c("list", "pv_request")
  )
}

#' @noRd
get_data <- function(prsd_resp) {
  structure(
    list(prsd_resp[[4]]),
    names = names(prsd_resp[4]),
    class = c("list", "pv_data_result")
  )
}

#' @noRd
get_query_results <- function(prsd_resp) {
  structure(
    prsd_resp["total_hits"],
    class = c("list", "pv_query_result")
  )
}

#' @noRd
process_resp <- function(resp) {
  prsd_resp <- parse_resp(resp)
  request <- get_request(resp)
  data <- get_data(prsd_resp)

  query_results <- get_query_results(prsd_resp)

  structure(
    list(
      data = data,
      query_results = query_results,
      request = request
    ),
    class = c("list", "pv_result")
  )
}

#' @noRd
repair_resp <- function(data, requested_fields) {

  # hopefully temporary code to cover a new API bug
  # were it returns extra/unnrequested fields, potentially
  # breaking paging and producing unexpected results in existing code

  if(!is.null(requested_fields) && !is.null(nrow(data[[1]]))) {
    # not trying to handle fully qualified fields gracefully
    # though we could?  if nested objects are coming back fully populated
    requested_fields <- unique(sub("\\..*", "", requested_fields))

    # potential problem here: may request columns that aren't returned
    # like botanic at patent endpoint.  we want to remove columns
    # that were returned but not requested
    returned <- names(data[[1]])
    keep_columns <- intersect(returned, requested_fields)
    if(!setequal(returned, requested_fields))
      data[[1]] <- subset(data[[1]], select = keep_columns)
  }

  data
}
