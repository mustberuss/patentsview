context("cast_pv_data")

test_that("cast_pv_data casts patent fields as expected", {
  skip_on_cran()
  skip_on_ci()

  pv_out <- search_pv(
    query = "{\"patent_number\":\"5116621\"}", fields = get_fields("patents")
  )

  dat <- cast_pv_data(data = pv_out$data)

  date <- !is.character(dat$patents$patent_date)
  # dat$patents$patent_detail_desc_length isn't being set?

  # num <- is.numeric(dat$patents$patent_detail_desc_length)
  # now we don't get latitude from the patents endpoint
  #num <- is.numeric(dat$patents$assignees_at_grant[[1]]$latitude[1])

  # assignee.type behaves oddly, it can be requested as a string or integer
  # and is returned as a string.  I've raised it as an error - it should be
  # returned as an integer.  The fake doc has it as an integer so we'll 
  # cast it and requesting as an integer should work.
  # could remove all of this if the api team returns it as an integer

  # not sure why this is true- shouldn't it get converted to an integer?
  # oops, we're assuming integers arrived as integers, so 
  # cast is "integer" = as_is.  changed fake doc to type int so this will work
  # (we'll cast the string to an integer now)
  assignee_type <- is.integer(dat$patents$assignees_at_grant[[1]]$type[1])

  expect_true(date && assignee_type)
})

test_that("cast_pv_data casts assignee fields as expected", {
  skip_on_cran()
  skip_on_ci()

   # the assignees endpoint will give us a latitude and longitude
   # as floats so no casting was necessary. we'll assert that here

   pv_out <- search_pv(
    query = '{"_text_phrase":{"name_last": "Clinton"}}', 
    endpoint = "assignees",
    fields = get_fields("assignees")
  )

  dat <- cast_pv_data(data = pv_out$data)

  # ah, failing since it's not currently coming back from the api
  # I feel another test case coming on...

  # lat <- is.numeric(dat$assignees$lastknown_latitude[1])

  # here we have the same funky conversion mentioned above
  # on the field "type",  first one as on the patents endpoint
  # this one is on the assignees endpoint - for consistency I guess!
  assignee_type <- is.integer(dat$assignees$type[1])

  date <- !is.character(dat$assignee$first_seen_date)

  # do integers need casting?
  # years_active <- is.integer(dat$assignee$years_active)

  # logical typeof(dat$assignee$years_active)
  # TRUE is.logical(dat$assignee$years_active)

  expect_true(date && assignee_type)
})

