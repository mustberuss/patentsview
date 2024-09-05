#' @noRd
stop2 <- function(...) stop(..., call. = FALSE)

#' @noRd
asrt <- function(expr, ...) if (!expr) stop2(...)

#' @noRd
parse_resp <- function(resp) {
  j <- httr::content(resp, as = "text", encoding = "UTF-8")
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
to_singular <- function(plural) {
  # assignees is an exception, singular isn't assigne
  # wipo endpoint returns singluar wipo as the entity
  # attorneys accidently works

  if(plural == "wipo") {
     singular = plural
  } else if (endsWith(plural, "ies")) {
    singular <- sub("ies$", "y", plural)
  } else if (endsWith(plural, "es") && !endsWith(plural, "ees")) {
    singular <- sub("es$", "", plural)
  } else {
    singular <- sub("s$", "", plural)
  }
}


#' @noRd
to_plural <- function(singular) {
  # wipo endpoint returns singluar wipo as the entity
  # attorneys not attorneies

  # remove the patent/ and publication/ from nested endpoints when present
  singular <- sub("^patent/", "", singular)
  singular <- sub("^publication/", "", singular)

  if(singular  == "wipo") {
     plural = singular
  } 
  else if (singular == "attorney") {
     plural <- "attorneys"
  } else if (endsWith(singular, "y")) {
    plural <- sub("y$", "ies", singular)
  } else if (endsWith(singular, "s")) {
    plural <- paste0(singular, "es")
  } else {
    plural <- paste0(singular, "s")
  }
}

#' @noRd
endpoint_from_entity <- function(entity) {
   # needed for casting to work with singular endpoints and mostly plural entities

   if(entity == "rel_app_text_publications") {
      "publication/rel_app_texts"
   } else if (entity == "rel_app_text") {
      "publication/rel_app_text"
   } else if (entity == "other_reference") {
      "patent/otherreference"
   } else {
      singular <- to_singular(entity)

      # figure out if the endpoint is nested
      nested <- c("attorney", "foreign_citation", "us_application_citation",
                  "us_patent_citation", "rel_app_text")

      if(singular %in% nested) paste0("patent/", singular) else singular
   }
}

