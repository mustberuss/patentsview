if (requireNamespace("vcr", quietly = TRUE)) {
  vcr::vcr_configure(
    filter_request_headers = list("X-Api-Key")
  )
}
