context("unnest_pv_data")

# In the new version of the api, only three of the endpoints are searchable 
# by patent number.  get_test_query() provides a sample query for each 
# endpoint, except for locations, which isn't on the test server yet

eps <- (get_endpoints())
eps <-eps[eps != "locations"]

test_that("api return can be unnested", {
  skip_on_cran()
  skip_on_ci()

  z <- lapply(eps, function(x) {
    Sys.sleep(1)
    print(x)
    pv_out <- search_pv(
      query = get_test_query(x),
      endpoint = x,
      fields = get_fields(x)
    )
    unnest_pv_data(pv_out[["data"]])
  })

  expect_true(TRUE)
})
