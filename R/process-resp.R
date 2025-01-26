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
