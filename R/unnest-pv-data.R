#' @noRd
infer_endpoint <- function(data) {
  potential_eps <- unique(fieldsdf[fieldsdf$group == names(data), "endpoint"])
  returned_fields <- colnames(data[[1]])

  all_matches <- lapply(potential_eps, function(ep) {
    this_ep_fields <- fieldsdf[fieldsdf$endpoint == ep, "field"]
    this_ep_grps <- unique(fieldsdf[fieldsdf$endpoint == ep, "group"])
    this_ep_pk <- get_ok_pk(ep)
    # Column names match retrievable col names for endpoint:
    all_good_cols <- all(returned_fields %in% c(this_ep_fields, this_ep_grps))
    # And we have the PKs in the data. Pretty sure this check isn't needed
    # if we have all_good_cols, but including it anyway.
    pks_in_cols <-  all(this_ep_pk %in% returned_fields)
    potential_match <- all_good_cols && pks_in_cols
    if (potential_match) ep else NULL
  })

  matching_eps <- unlist(all_matches)
  if (length(matching_eps) > 1) {
    warning("Infer endpoint issue")
  }
  matching_eps[1]
}

#' Unnest PatentsView data
#'
#' This function converts a single data frame that has subentity-level list
#' columns in it into multiple data frames, one for each entity/subentity.
#' The multiple data frames can be merged together using the primary key
#' variable specified by the user (see the
#' \href{https://r4ds.had.co.nz/relational-data.html}{relational data} chapter
#' in "R for Data Science" for an in-depth introduction to joining tabular data).
#'
#' @param data The data returned by \code{\link{search_pv}}. This is the first
#'   element of the three-element result object you got back from
#'   \code{search_pv}. It should be a list of length 1, with one data frame
#'   inside it. See examples.
#' @param pk `r lifecycle::badge("deprecated")`.
#'   should be the unique identifier for the primary entity. For example, if you
#'   used the patent endpoint in your call to \code{search_pv}, you could
#'   specify \code{pk = "patent_id"}. \strong{This identifier has to have
#'   been included in your \code{fields} vector when you called
#'   \code{search_pv}}. You can use \code{\link{get_ok_pk}} to suggest a
#'   potential primary key for your data.
#'
#' @return A list with multiple data frames, one for each entity/subentity.
#'   Each data frame will have the \code{pk} column in it, so you can link the
#'   tables together as needed.
#'
#' @examples
#' \dontrun{
#'
#' fields <- c(
#'   "patent_id", "patent_title",
#'   "inventors.inventor_city", "inventors.inventor_country"
#' )
#' res <- search_pv(query = '{"_gte":{"patent_year":2015}}', fields = fields)
#' unnest_pv_data(data = res$data)
#' }
#'
#' @export
unnest_pv_data <- function(data, pk = lifecycle::deprecated()) {
  validate_pv_data(data)

  df <- data[[1]]


  # Handle empty results
  if (!is.data.frame(df) || nrow(df) == 0) {
    return(structure(
      list(),
      class = c("list", "pv_relay_db")
    ))
  }

  endpoint <- infer_endpoint(data)
  prim_ent_var <- !vapply(df, is.list, logical(1))

  sub_ent_df <- df[, !prim_ent_var, drop = FALSE]
  sub_ents <- colnames(sub_ent_df)

  pk <- get_ok_pk(endpoint)
  out_sub_ent <- lapply2(sub_ents, function(x) {
    temp <- sub_ent_df[[x]]
    names(temp) <- df[, pk]
    xn <- do.call("rbind", temp)
    xn[, pk] <- gsub("\\.[0-9]*$", "", rownames(xn))
    rownames(xn) <- NULL
    xn
  })

  prim_ent <- names(data)
  out_sub_ent[[prim_ent]] <- df[, prim_ent_var, drop = FALSE]

  out_sub_ent_reord <- lapply(out_sub_ent, function(x) {
    coln <- colnames(x)
    x[, unique(c(pk, colnames(x))), drop = FALSE]
  })

  structure(
    out_sub_ent_reord,
    class = c("list", "pv_relay_db")
  )
}
