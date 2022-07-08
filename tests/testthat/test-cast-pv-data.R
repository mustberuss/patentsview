context("cast_pv_data")

test_that("cast_pv_data casts data types as expected", {
  skip_on_cran()
  skip_on_ci()

  pv_out <- search_pv(
    query = "{\"patent_number\":\"5116621\"}", fields = get_fields("patents")
  )

  dat <- cast_pv_data(data = pv_out$data)

  date <- !is.character(dat$patents$patent_date)
  # dat$patents$patent_detail_desc_length isn't being set?

  # num <- is.numeric(dat$patents$patent_detail_desc_length)
  #num <- is.numeric(dat$patents$assignees_at_grant[[1]]$latitude[1])

  assignee_type <- is.character(dat$patents$assignees_at_grant[[1]]$type[1])

  expect_true(date && assignee_type)
})
