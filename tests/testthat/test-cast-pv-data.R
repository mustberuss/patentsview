test_that("cast_pv_data casts patent fields as expected", {
  skip_on_cran()

  pv_out <- search_pv(
    query = '{"patent_id":"5116621"}', fields = get_fields("patent")
  )

  dat <- cast_pv_data(data = pv_out$data)

  # patent_date was received as a string and should be cast to a date
  date <- class(dat$patents$patent_date) == "Date"

  # patent_detail_desc_length was recieved as an int and should still be one
  num <- is.numeric(dat$patents$patent_detail_desc_length)

  # assignee type is a string like "3" from the api and gets cast to an integer
  assignee_type <- is.numeric(dat$patents$assignees[[1]]$assignee_type[[1]])

  expect_true(num && date && assignee_type)

  # application.rule_47_flag is received as a boolean and casting should leave it alone
  expect_true(is.logical(dat$patents$application[[1]]$rule_47_flag))
})

test_that("cast_pv_data casts assignee fields as expected", {
  skip_on_cran()
  skip_on_ci()

  pv_out <- search_pv(
    query = '{"_text_phrase":{"assignee_individual_name_last": "Clinton"}}',
    endpoint = "assignee",
    fields = get_fields("assignee")
  )

  dat <- cast_pv_data(data = pv_out$data)

  # latitude comes from the api as numeric and is left as is by casting
  lat <- is.numeric(dat$assignees$assignee_lastknown_latitude[[1]])

  # here we have the same funky conversion mentioned above
  # on the field "assigneee_type"
  assignee_type <- is.numeric(dat$assignees$assignee_type[[1]])

  # was first seen date cast properly?
  cast_date <- class(dat$assignees$assignee_first_seen_date[[1]]) == "Date"

  # integer from the API should remain an integer
  years_active <- is.numeric(dat$assignees$assignee_years_active[[1]])

  expect_true(lat)
  expect_true(assignee_type)
  expect_true(cast_date)
  expect_true(years_active)

  #  expect_true(date && assignee_type && years_active)
})

# rats, the util method would have to be public - maybe special local run?
# iterate through the helper queries, make the call and see
# if the return of endpoint_from_entity matches the helper endpoint
