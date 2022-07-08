context("unnest_pv_data")

eps <- get_endpoints()

test_that("", {
  skip_on_cran()
  skip_on_ci()

  #eps_no_loc <- eps[eps != "location"]
  # with the new version of the api we can only search by patent_number on few 
  # of the endpoints
  testable_eps = get_patent_num_searchable_endpoints()

  z <- lapply(testable_eps, function(x) {
    Sys.sleep(1)
    print(x)
    pv_out <- search_pv(
      "{\"patent_number\":\"10966293\"}",
      endpoint = x,
      fields = get_fields(x)
    )
    unnest_pv_data(pv_out[["data"]])
  })

  expect_true(TRUE)
})
