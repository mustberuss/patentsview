if (requireNamespace("vcr", quietly = TRUE)) {
  vcr::vcr_configure(
    dir = "_vcr",
    filter_request_headers = list("X-Api-Key")
  )

  # Set a fake API key for tests so validation passes
  # VCR will intercept HTTP requests and use recorded cassettes
  if (Sys.getenv("PATENTSVIEW_API_KEY") == "") {
    Sys.setenv(PATENTSVIEW_API_KEY = "test-api-key")
  }
}
