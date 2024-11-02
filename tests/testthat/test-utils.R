test_that("we can convert endpoints to their plural form and back", {
  skip_on_cran()

  eps <- get_endpoints()
  z <- vapply(eps, function(x) {
    to_singular(to_plural(x))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  # we now need to unnest the endpoints for the comparison to work
  unnested_eps <- gsub("^(patent|publication)/", "", eps)

  expect_equal(unnested_eps, z)
})

test_that("coverage todo: move", {
  skip_on_cran()

  qry <- qry_funs$eq(patent_id = "11530080")

  expect_error(
    cast_pv_data(qry),
    "Wrong input type for data"
  )
})

test_that("we can cast some of the new endpoints", {
  skip_on_cran()

  endpoints <- c("patent/rel_app_text", "publication/rel_app_text")

  nul <- lapply(endpoints, function(endpoint) {
    results <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint)
    cast <- cast_pv_data(results$data)
  })

  expect_true(TRUE)
})
