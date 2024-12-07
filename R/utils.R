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

#' @noRd
to_singular <- function(plural) {
  # ipcr and wipo are funky exceptions.  On assignees and other_references
  # we only want to remove the "s", not the "es"

  if (plural == "ipcr") {
    singular <- "ipc"
  } else if (plural == "wipo") {
    singular <- plural
  } else if (endsWith(plural, "classes")) {
    singular <- sub("es$", "", plural)
  } else {
    singular <- sub("s$", "", plural)
  }
  singular
}


#' @noRd
to_plural <- function(singular) {
  # wipo endpoint returns singular wipo as the entity

  # remove the patent/ and publication/ from nested endpoints when present
  singular <- sub("^(patent|publication)/", "", singular)

  if (singular == "ipc") {
    plural <- "ipcr"
  } else if (singular == "wipo") {
    plural <- singular
  } else if (endsWith(singular, "s")) {
    plural <- paste0(singular, "es")
  } else {
    plural <- paste0(singular, "s")
  }
  plural
}

#' @noRd
endpoint_from_entity <- function(entity) {
  # needed for casting to work with singular endpoints and mostly plural entities

  # we can't distinguish rel_app_texts, could be from patent/rel_app_text or
  # publication/rel_app_text
  singular <- to_singular(entity)
  nested <- nrow(fieldsdf[fieldsdf$endpoint == singular, ]) == 0

  if (nested) paste0("patent/", singular) else singular
}
