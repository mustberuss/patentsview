#' @noRd
get_base <- function(endpoint) {
  sprintf("https://search.patentsview.org/api/v1/%s/", endpoint)
}

#' @noRd
tojson_2 <- function(x, ...) {
  json <- jsonlite::toJSON(x, ...)
  if (!grepl("[[:alnum:]]", json, ignore.case = TRUE)) json <- ""
  json
}

#' @noRd
to_arglist <- function(fields, size, sort, after) {
  opts = list(size = size)
  if(after != "") {
     opts$after = after
  }

  list(
    fields = fields,
    sort = list(as.list(sort)),
    opts = opts
  )
}

#' @noRd
get_get_url <- function(query, base_url, arg_list) {
  j <- paste0(
    base_url,
    "?q=", utils::URLencode(query, reserved = TRUE),
    "&f=", tojson_2(arg_list$fields),
    "&s=", tojson_2(arg_list$sort, auto_unbox = TRUE),
    "&o=", tojson_2(arg_list$opts, auto_unbox = TRUE)
  )

  utils::URLencode(j)
}

#' @noRd
get_post_body <- function(query, arg_list) {
  body <- paste0(
    "{",
    '"q":', query, ",",
    '"f":', tojson_2(arg_list$fields), ",",
    '"s":', tojson_2(arg_list$sort, auto_unbox = TRUE), ",",
    '"o":', tojson_2(arg_list$opts, auto_unbox = TRUE),
    "}"
  )
  # The API can now act weirdly if we pass f:{},s:{} as we did in the past.
  # (Weirdly in that the post results may not equal the get results or posts error out)
  # Now we'd remove "f":, and "s":,  We're guaranteed to have q: and at least "size":1000 as o:
  gsub('("[fs]":,)', "", body)
}

#' @noRd
patentsview_error_body <- function(resp) {
  if (httr2::resp_status(resp) == 400) c(httr2::resp_header(resp, "X-Status-Reason")) else NULL
}

#' @noRd
one_request <- function(method, query, base_url, arg_list, api_key, ...) {
  if (method == "GET") {
    get_url <- get_get_url(query, base_url, arg_list)
    req <- httr2::request(get_url) |>
      httr2::req_method("GET")
  } else {
    body <- get_post_body(query, arg_list)
    req <- httr2::request(base_url) |>
      httr2::req_body_raw(body) |>
      httr2::req_headers("Content-Type" = "application/json") |>
      httr2::req_method("POST")
  }

  resp <- req |>
    httr2::req_user_agent("https://github.com/ropensci/patentsview") |>
    httr2::req_options(...) |>
    httr2::req_retry(max_tries = 2) |> # automatic 429 Retry-After
    httr2::req_headers("X-Api-Key" = api_key, .redact = "X-Api-Key") |>
    httr2::req_error(body = patentsview_error_body) |>
    httr2::req_perform()

  resp
}

#' @noRd
request_apply <- function(ex_res, method, query, base_url, arg_list, api_key, ...) {
  matched_records <- ex_res$query_results[[1]]
  req_pages <- ceiling(matched_records / arg_list$opts$size)
  if (req_pages < 1) {
    stop2("No records matched your query...Can't download multiple pages")
  }

  tmp <- lapply(seq_len(req_pages), function(i) {
    x <- one_request(method, query, base_url, arg_list, api_key, ...)
    x <- process_resp(x)

    # now to page we need set the "after" attribute to where we left off
    # we want the value of the primary sort field
    s <- names(arg_list$sort[[1]])[[1]]
    if (arg_list$sort[[1]][[1]] == "asc") {
      index <- nrow(x$data[[1]])
    } else {
      index <- 1
    }

    arg_list$opts$after <<- x$data[[1]][[s]][[index]]

    x$data[[1]]
  })

  do.call("rbind", c(tmp, make.row.names = FALSE))
}

#' @noRd
get_default_sort <- function(endpoint) {
  default <- c("asc")
  names(default) <- get_ok_pk(endpoint)
  default
}

#' Search PatentsView
#'
#' This function makes an HTTP request to the PatentsView API for data matching
#' the user's query.
#'
#' @param query The query that the API will use to filter records. \code{query}
#'  can come in any one of the following forms:
#'  \itemize{
#'    \item A character string with valid JSON. \cr
#'    E.g., \code{'{"_gte":{"patent_date":"2007-01-04"}}'}
#'
#'    \item A list which will be converted to JSON by \code{search_pv}. \cr
#'    E.g., \code{list("_gte" = list("patent_date" = "2007-01-04"))}
#'
#'    \item An object of class \code{pv_query}, which you create by calling one
#'    of the functions found in the \code{\link{qry_funs}} list...See the
#'    \href{../articles/writing-queries.html}{writing
#'    queries vignette} for details.\cr
#'    E.g., \code{qry_funs$gte(patent_date = "2007-01-04")}
#'  }
#' @param fields A character vector of the fields that you want returned to you.
#'  A value of \code{NULL} indicates to the API that it should return the default fields
#'  for that endpoint. Acceptable fields for a given endpoint can be found at the API's
#'  online documentation (e.g., check out the field list for the
#'  \href{https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference#patent}{patents
#'  endpoint}) or by viewing the \code{fieldsdf} data frame
#'  (\code{View(fieldsdf)}). You can also use \code{\link{get_fields}} to list
#'  out the fields available for a given endpoint.
#'
#'  Nested fields can be fully qualified, e.g., "application.filing_date" or the
#'  group name can be used to retrieve all of its nested fields, E.g. "application".
#'  The latter would be similar to passing \code{get_fields("patent", group = "application")}
#'  except it's the API that decides what fields to return.
#' @param endpoint The web service resource you wish to search. Use
#'  \code{get_endpoints()} to list the available endpoints.
#' @param subent_cnts `r lifecycle::badge("deprecated")` This is always FALSE in the
#' new version of the API as the total counts of unique subentities is no longer available.
#' @param mtchd_subent_only `r lifecycle::badge("deprecated")` This is always
#' FALSE in the new version of the API as non-matched subentities
#' will always be returned.
#' @param page `r lifecycle::badge("deprecated")` The new version of the API does not use 
#' \code{page} as a parameter for paging, it uses \code{after}.
#' @param per_page `r lifecycle::badge("deprecated")` The API now uses \code{size}
#' @param size The number of records that should be returned per page. This
#'  value can be as high as 1,000 (e.g., \code{size = 1000}).
#' @param after Exposes the API's paging parameter for users who want to implement their own
#' custom paging. It cannot be set when \code{all_pages = TRUE} as the R package manipulates it 
#' for users automatically.
#' @param all_pages Do you want to download all possible pages of output? If
#'  \code{all_pages = TRUE}, the value of \code{size} is ignored.
#' @param sort A named character vector where the name indicates the field to
#'  sort by and the value indicates the direction of sorting (direction should
#'  be either "asc" or "desc"). For example, \code{sort = c("patent_id" =
#'  "asc")} or \cr\code{sort = c("patent_id" = "asc", "patent_date" =
#'  "desc")}. \code{sort = NULL} (the default) means do not sort the results.
#'  You must include any fields that you wish to sort by in \code{fields}.
#' @param method The HTTP method that you want to use to send the request.
#'  Possible values include "GET" or "POST". Use the POST method when
#'  your query is very long (say, over 2,000 characters in length).
#' @param error_browser `r lifecycle::badge("deprecated")`
#' @param api_key API key, it defaults to Sys.getenv("PATENTSVIEW_API_KEY"). Request a key 
#' \href{https://patentsview.org/apis/keyrequest}{here}.
#' @param ... Curl options passed along to httr2's \code{\link[httr2]{req_options}}
#'  when we do GETs or POSTs.
#'
#' @return A list with the following three elements:
#'  \describe{
#'    \item{data}{A list with one element - a named data frame containing the
#'    data returned by the server. Each row in the data frame corresponds to a
#'    single value for the primary entity. For example, if you search the
#'    assignee endpoint, then the data frame will be on the assignee-level,
#'    where each row corresponds to a single assignee. Fields that are not on
#'    the assignee-level would be returned in list columns.}
#'
#'    \item{query_results}{Entity counts across all pages of output (not just
#'    the page returned to you).}
#'
#'    \item{request}{Details of the HTTP request that was sent to the server.
#'    When you set \code{all_pages = TRUE}, you will only get a sample request.
#'    In other words, you will not be given multiple requests for the multiple
#'    calls that were made to the server (one for each page of results).}
#'  }
#'
#' @examples
#' \dontrun{
#'
#' search_pv(query = '{"_gt":{"patent_year":2010}}')
#'
#' search_pv(
#'   query = qry_funs$gt(patent_year = 2010),
#'   fields = get_fields("patent", c("", "assignees"))
#' )
#'
#' search_pv(
#'   query = qry_funs$gt(patent_year = 2010),
#'   method = "POST",
#'   fields = "patent_id",
#'   sort = c("patent_id" = "asc")
#' )
#'
#' search_pv(
#'   query = qry_funs$eq(inventor_name_last = "Crew"),
#'   endpoint = "inventor",
#'   all_pages = TRUE
#' )
#'
#' search_pv(
#'   query = qry_funs$contains(assignee_individual_name_last = "Smith"),
#'   endpoint = "assignee"
#' )
#'
#' search_pv(
#'   query = qry_funs$contains(inventors.inventor_name_last = "Smith"),
#'   endpoint = "patent",
#'   timeout = 40
#' )
#'
#' search_pv(
#'   query = qry_funs$eq(patent_id = "11530080"),
#'   fields = "application"
#' )
#' }
#'
#' @export
search_pv <- function(query,
                      fields = NULL,
                      endpoint = "patent",
                      subent_cnts = FALSE,
                      mtchd_subent_only,
                      page,
                      per_page,
                      size = 1000,
                      after = "",
                      all_pages = FALSE,
                      sort = NULL,
                      method = "GET",
                      error_browser = NULL,
                      api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
                      ...) {
  validate_args(api_key, fields, endpoint, method, sort, after, size, all_pages)
  deprecate_warn_all(error_browser, subent_cnts, mtchd_subent_only, page, per_page)

  if (is.list(query)) {
    # check_query(query, endpoint)
    query <- jsonlite::toJSON(query, auto_unbox = TRUE)
  }

  # now for paging to work there needs to be a sort field
  if (all_pages && is.null(sort)) {
    sort <- get_default_sort(endpoint)
    # insure we'll have the value of the sort field
    if (!names(sort) %in% fields) fields <- c(fields, names(sort))
  }

  arg_list <- to_arglist(fields, size, sort, after)
  base_url <- get_base(endpoint)

  result <- one_request(method, query, base_url, arg_list, api_key, ...)
  result <- process_resp(result)
  if (!all_pages) {
    return(result)
  }

  # Here we ignore the user's sort and instead have the API sort by the primary
  # key for the requested endpoint.  This simplifies the paging's after parameter.
  # If we call the API with more than a primary sort, the after parameter would
  # have to be an array of all the sort fields' last values.
  # After we've retrieved all the data we'll sort in R using the sort the user requested

  # Doing this also protects users from needing to know the peculiarities
  # of the API's paging.  Example: if a user requests a sort of
  # {"patent_date":"asc"}, on paging the after parameter may skip
  # to the next issue date before having retured all the data for the last
  # patent_date in the previous request - depending on where the
  # patent_dates change relative to the API's page breaks.
  # (Say the last patent in a retrieved page is the first patent
  # of a particular date, we wouldn't want the after parameter to
  # to begin the next page of data after this date.)

  # We also need to insure we have the value of the primary sort field.
  # We'll throw an error if the sort field is not present in the fields list
  # Remember if we added the primary_sort_key to fields and remove it from the
  # API's return before returning data to the user- even if the user didn't
  # pass any fields?
  primary_sort_key <- get_default_sort(endpoint)

  if (!names(primary_sort_key) %in% fields) {
    fields <- c(fields, names(primary_sort_key))
    need_remove <- TRUE
  } else {
    need_remove <- FALSE
  }

  arg_list <- to_arglist(fields, size, primary_sort_key, after)
  paged_data <- request_apply(result, method, query, base_url, arg_list, api_key, ...)

  # apply the user's sort
  data.table::setorderv(paged_data, names(sort), ifelse(as.vector(sort) == "asc", 1, -1))
  result$data[[1]] <- paged_data

  if (need_remove) result$data[[1]][[names(primary_sort_key)]] <- NULL

  result
}

#' Retrieve Linked Data
#'
#' Some of the endpoints now return HATEOAS style links to get more data. E.g.,
#' the patent endpoint may return a link such as:
#' "https://search.patentsview.org/api/v1/inventor/fl:th_ln:jefferson-1/"
#'
#' @param url The link that was returned by the API on a previous call or an example in the documentation.
#'
#' @param ... Curl options passed along to httr2's \code{\link[httr2]{req_options}} function.
#'
#' @return A list with the following three elements:
#'  \describe{
#'    \item{data}{A list with one element - a named data frame containing the
#'    data returned by the server. Each row in the data frame corresponds to a
#'    single value for the primary entity. For example, if you search the
#'    assignee endpoint, then the data frame will be on the assignee-level,
#'    where each row corresponds to a single assignee. Fields that are not on
#'    the assignee-level would be returned in list columns.}
#'
#'    \item{query_results}{Entity counts across all pages of output (not just
#'    the page returned to you).}
#'
#'    \item{request}{Details of the GET HTTP request that was sent to the server.}
#'  }
#'
#' @inheritParams search_pv
#'
#' @examples
#' \dontrun{
#'
#' retrieve_linked_data(
#'   "https://search.patentsview.org/api/v1/cpc_group/G01S7:4811/"
#' )
#'
#' retrieve_linked_data(
#'   'https://search.patentsview.org/api/v1/patent/?q={"_text_any":{"patent_title":"COBOL cotton gin"}}&s=[{"patent_id": "asc" }]&o={"size":50}&f=["inventors.inventor_name_last","patent_id","patent_date","patent_title"]'
#' )
#' }
#'
#' @export
retrieve_linked_data <- function(url,
                                 api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
                                 ...) {
  # There wouldn't be url parameters on a HATEOAS link but we'll also accept
  # example urls from the documentation, where there could be parameters
  url_peices <- httr2::url_parse(url)

  # Only send the API key to subdomains of patentsview.org
  if (!grepl("^.*\\.patentsview.org$", url_peices$hostname)) {
    stop2("retrieve_linked_data is only for patentsview.org urls")
  }

  params <- list()
  query <- ""

  if (!is.null(url_peices$query)) {
    # Need to change f to fields vector, s to sort vector and o to opts
    # There is probably a whizbangy better way to do this in R
    if (!is.null(url_peices$query$f)) {
      params$fields <- unlist(strsplit(gsub("[\\[\\]]", "", url_peices$query$f, perl = TRUE), ",\\s*"))
    }

    if (!is.null(url_peices$query$s)) {
      params$sort <- jsonlite::fromJSON(sub(".*s=([^&]*).*", "\\1", url))
    }

    if (!is.null(url_peices$query$o)) {
       params$opts = jsonlite::fromJSON(sub(".*o=([^&]*).*", "\\1", url))
    }

    query <- if (!is.null(url_peices$query$q)) sub(".*q=([^&]*).*", "\\1", url) else ""
    url <- paste0(url_peices$scheme, "://", url_peices$hostname, url_peices$path)
  }

  # Go through one_request, which handles resend on throttle errors
  # The API doesn't seem to mind ?q=&f=&o=&s= appended to HATEOAS URLs
  res <- one_request("GET", query, url, params, api_key, ...)
  process_resp(res)
}
