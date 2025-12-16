if (requireNamespace("vcr", quietly = TRUE)) {
  vcr::vcr_configure(
    dir = "_vcr",
    filter_request_headers = list("X-Api-Key")
  )
}
