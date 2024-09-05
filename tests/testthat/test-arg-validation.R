test_that("validate_args throws errors for all bad args", {
  skip_on_cran()

  # make sure deprecated warnings are always thrown- bypass 8 hour suppression
  rlang::local_options(lifecycle_verbosity = "warning")

  # TODO(any): Remove:
  # skip("Temp skip for API redesign PR")

  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', endpoint = "patents"),
    "endpoint"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', method = "Post"),
    "method"
  )
  expect_warning(
    search_pv('{"patent_date":["1976-01-06"]}', subent_cnts = TRUE),
    class = "lifecycle_warning_deprecated"
  )
  expect_warning(
    search_pv('{"patent_date":["1976-01-06"]}', subent_cnts = 7),
    class = "lifecycle_warning_deprecated"
  )
  expect_warning(
     search_pv('{"patent_date":["1976-01-06"]}', mtchd_subent_only = NULL),
     class = "lifecycle_warning_deprecated"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', per_page = "50"),
    "per_page"
  )
  expect_warning(
    search_pv('{"patent_date":["1976-01-06"]}', page = NA),
    class = "lifecycle_warning_deprecated" # unsupported page parameter
  )
  expect_error(
    search_pv(
      '{"patent_date":["1976-01-06"]}',
      fields = "patent_date",
      sort = c("patent_id" = "asc")
    ),
    "sort"
  )

  expect_error(
    get_fields("assignee", groups="cpc_current"),  # valid group for a different endpoint
    "groups"
  )
})
