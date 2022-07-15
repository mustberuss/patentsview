context("api-returns")

# Test to see if all the requested fields come back - to test the new
# version of the api more than to test the r packge!

eps <- (get_endpoints())
eps <-eps[eps != "locations"]

# TODO:
# Add a test to see if we get back all the requested fields

# need to figure out how to match names
# names(dl$assignees_at_grant)# could check plain_names in fieldsdf for this group and endpoint

test_that("API returns all requested groups", {
  skip_on_cran()
  skip_on_ci()

  # can we traverse the return building a list of fields?
  # sort both requested fields and returned ones to see if they are equal

  eps <-eps[eps != "assignees"]  # currently not getting "assignee_years" back from the api
  eps <-eps[eps != "inventors"]  # currently not getting "inventor_years" back from the api

  z <- lapply(eps, function(x) {
    Sys.sleep(1)
    print(x)
    res <- search_pv(
      query = get_test_query(x),
      endpoint = x,
      fields = get_fields(x)
    )

   dl <- unnest_pv_data(res$data)

   actual_groups <- sort(names(dl))
   expected_groups <- sort(unique(fieldsdf[fieldsdf$endpoint == x, "group"]))

   if(length(actual_groups) != length(expected_groups))
      print(paste("trouble",x))

   expect_equal(expected_groups, actual_groups)

  })


})
