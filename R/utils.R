#' @noRd
stop2 <- function(...) stop(..., call. = FALSE)

#' @noRd
asrt <- function(expr, ...) if (!expr) stop2(...)

#' @noRd
parse_resp <- function(resp) {
  j <- resp |> httr2::resp_body_string(encoding = "UTF-8")

  jsonlite::fromJSON(
    j,
    simplifyVector = TRUE, simplifyDataFrame = TRUE, simplifyMatrix = TRUE
  )
}

#' @noRd
format_num <- function(x) {
  format(
    x,
    big.mark = ",", scientific = FALSE, trim = TRUE
  )
}

#' @noRd
validate_endpoint <- function(endpoint) {
  ok_ends <- get_endpoints()

  asrt(
    all(endpoint %in% ok_ends, length(endpoint) == 1),
    "endpoint must be one of the following: ", paste(ok_ends, collapse = ", ")
  )
}

#' @noRd
validate_pv_data <- function(data) {
  asrt(
    "pv_data_result" %in% class(data),
    "Wrong input type for data...See example for correct input type"
  )
}
