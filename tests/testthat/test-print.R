context("printing")

test_that("We can print the returns from all endpoints ", {
  skip_on_cran()
  skip_on_ci()

  eps <- (get_endpoints())
  eps <- eps[eps != "locations"]

  lapply(eps, function(x) {
    Sys.sleep(2)
    print(x)
    j <- search_pv(query = get_test_query(x), endpoint = x)
    print(j)
    j
  })

  expect_true(TRUE)
})
