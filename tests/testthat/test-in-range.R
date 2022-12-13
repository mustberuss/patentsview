context("validate_args")

test_that("in_range returns the right patents", {
  skip_on_cran()
  skip_on_ci()

   skip("Temp skip for field parsing fix")

  sort <- c("patent_date" = "asc", "patent_id" = "asc")
  fields <- get_fields("patents")

  # get the patents from the first through the third issue dates inclusive
  range_query <- qry_funs$in_range(patent_date = c("1976-01-06", "1976-01-20"))

  range_results <- search_pv(
    query = range_query,
    fields = fields,
    sort = sort,
    all_pages = TRUE
  )

  # query for the first three patent dates
  by_individual_dates <- qry_funs$eq("patent_date" = c("1976-01-06", "1976-01-13", "1976-01-20"))
  individual_results <- search_pv(
    query = by_individual_dates,
    fields = fields,
    sort = sort,
    all_pages = TRUE
  )

  expect_equal(range_results$data, individual_results$data)
})
