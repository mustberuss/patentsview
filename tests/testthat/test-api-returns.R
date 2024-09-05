# Test to see if all the requested fields come back - more to test the new
# version of the api than to test the r packge!  test-search-pv.R tests that we
# get the df names back, here we're checking that all the groups and eventually
# all the fields come back properly

eps <- (get_endpoints())

test_that("API returns all requested groups", {
  skip_on_cran()
  skip_on_ci()

  # can we traverse the return building a list of fields?
  # sort both requested fields and returned ones to see if they are equal

  # TODO: remove the trickery to get this test to pass, once the API is fixed
  bad_eps <- c("cpc_subclasses"
    , "location"        # Error: Invalid field: location_latitude
    , "uspc_subclasse"  # Error: Internal Server Error
    , "uspc_mainclass" # Error: Internal Server Error
    , "wipo"             # Error: Internal Server Error
    , "claim"           # Error: Invalid field: claim_dependent
    , "draw_desc_text"  # Error: Invalid field: description_sequence
    , "cpc_subclass"    # 404?  check the test query
    , "uspc_subclass"   # 404
   )

  mismatched_returns <- c(
     "patent",
     "publication",
     "patent/us_application_citation",
     "patent/us_patent_citation",
     "patent/attorney",
     "patent/foreign_citation",
     "patent/rel_app_text",  # check these?
     "publication/rel_app_text"
  ) 

  good_eps <- eps[!eps %in% bad_eps]
  good_eps <- good_eps[!good_eps %in% mismatched_returns]

  z <- lapply(good_eps, function(x) {
    print(x)
    res <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )

    dl <- unnest_pv_data(res$data)

    actual_groups <- names(dl)

    expected_groups <- unique(fieldsdf[fieldsdf$endpoint == x, "group"])

    # we now need to unnest the endpoints for the comparison to work
    expected_groups <- gsub("^(patent|publication)/","", expected_groups)

    # the endpoint's group is singular in expected_groups, it needs to be plural
    # for the comparison to work
    expected_groups <- replace(expected_groups, expected_groups==x, to_plural(x))

    expect_setequal(actual_groups, expected_groups)
    show_failure(expect_setequal(actual_groups, expected_groups))
  })

  # this will fail when the api is fixed
  z <- lapply(bad_eps, function(x) {
    print(x)
    expect_error(
       j <- search_pv(query = TEST_QUERIES[[x]], endpoint = x, fields = get_fields(x))
    )
  })

  # this will fail when the API is fixed
  z <- lapply(mismatched_returns, function(x) {
    print(x)
    res <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )

    dl <- unnest_pv_data(res$data)

    actual_groups <- names(dl)
    expected_groups <- unique(fieldsdf[fieldsdf$endpoint == x, "group"])

    # we now need to unnest the endpoints for the comparison to work
    expected_groups <- gsub("^(patent|publication)/","", expected_groups)

    # in the expected groups, the endpoint's group is singular in, it needs to be plural
    # for the comparison to work
    expected_groups <- replace(expected_groups, expected_groups==x, to_plural(x))

    # better way to do this?  want to expect_set_not_equal
    expect_error(
       expect_setequal(actual_groups, expected_groups)
    )
  })

  # make it noticeable that all is not right with the API
  skip("Skip for API bugs") # TODO: remove when the API is fixed

})
