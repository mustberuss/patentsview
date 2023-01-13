context("validate_args")

test_that("validate_args throws errors for all bad args", {
  skip_on_cran()

  # make sure deprecated warnings are always thrown- bypass 8 hour suppression
  rlang::local_options(lifecycle_verbosity = "warning")

  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', endpoint = "patent"),
    "endpoint"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', method = "Post"),
    "method"
  )
  expect_warning(
    search_pv('{"patent_date":["1976-01-06"]}', subent_cnts = TRUE),
    "subent_cnts"
  )
  expect_warning(
    search_pv('{"patent_date":["1976-01-06"]}', subent_cnts = 7),
    "subent_cnts"
  )
   expect_warning(
     search_pv('{"patent_date":["1976-01-06"]}', mtchd_subent_only = NULL),
     "mtchd_subent_only"  # deprecation warning
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', per_page = "50"),
    "per_page"
  )
  expect_warning(
    search_pv('{"patent_date":["1976-01-06"]}', page = NA),
    "page" # unsupported page parameter
  )
  expect_error(
    search_pv(
      '{"patent_date":["1976-01-06"]}',
      fields = "patent_date",
      sort = c("patent_id" = "asc")
    ),
    "sort"
  )
})
