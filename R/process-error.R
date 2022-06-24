#' @noRd
throw_er <- function(resp) {
  throw_if_loc_error(resp)
  xheader_er_or_status(resp)
}

#' @noRd
throw_if_loc_error <- function(resp) {
  if (hit_locations_ep(resp$url) && httr::status_code(resp) == 500) {
    num_grps <- get_num_groups(resp$url)
    if (num_grps > 2) {
      stop2(
        "Your request resulted in a 500 error, likely because you have ",
        "requested too many fields in your request (the locations endpoint ",
        "currently has restrictions on the number of fields/groups you can ",
        "request). Try slimming down your field list and trying again."
      )
    }
  }
}

#' @noRd
hit_locations_ep <- function(url) {
  grepl(
    "^https://search.patentsview.org/api/v1/location/",
    url,
    ignore.case = TRUE
  )
}

#' @noRd
get_num_groups <- function(url) {
  prsd_json_filds <- gsub(".*&f=([^&]*).*", "\\1", utils::URLdecode(url))
  fields <- jsonlite::fromJSON(prsd_json_filds)
  grps <- fieldsdf[fieldsdf$endpoint == "location" &
                     fieldsdf$field %in% fields, "group"]
  length(unique(grps))
}

#' @noRd
xheader_er_or_status <- function(resp) {

  # look for the api's ultra-helpful X-Status-Reason header
  xhdr <- httr::headers(resp)['X-Status-Reason']

  if (length(xhdr) != 1)
    httr::stop_for_status(resp)
  else
    stop(xhdr[[1]], call. = FALSE)
}


