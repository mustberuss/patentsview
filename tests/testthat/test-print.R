test_that("We can print the returns from all endpoints ", {
  skip_on_cran()

  eps <- get_endpoints()
  lapply(eps, function(x) {
    Sys.sleep(1)
    print(x)
    j <- search_pv(query = TEST_QUERIES[[x]], endpoint = x)
    print(j)
    j
  })

  expect_true(TRUE)
})
