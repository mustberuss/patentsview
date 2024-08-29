eps <- get_endpoints()

test_that("", {
  skip_on_cran()

  # TODO(any): add back fields = get_fields(x)
  # API throws 500s if some nested fields are included

  # locations endpoint is back but it fails this test
  bad_eps <- c("locations", "cpc_subclasses",
               "uspc_subclasses" , "uspc_mainclasses" , "wipo", 
               "claims","draw_desc_texts"
  )

  good_eps <- eps[!eps %in% bad_eps]

  z <- lapply(good_eps, function(x) {
    print(x)

    # the groups are different for the two rel_app_texts endpoints
    # from the current OpenAPI object
    #      "rel_app_texts": {
    #      "rel_app_text_publications": {

    # group for publication/rel_app_texts is publication/rel_app_text_publications
    # which doesn't match the endpoint as it does for the endpoints
    g <- if (x == "publication/rel_app_texts") "publication/rel_app_text_publications" else x

    pv_out <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x, group = (g)) # requesting non-nested attributes
    )
    unnest_pv_data(pv_out[["data"]])
  })

  expect_true(TRUE)

  # this will fail when the api is fixed
  z <- lapply(bad_eps, function(x) {
    print(x)
    expect_error(
      pv_out <- search_pv(
        query = TEST_QUERIES[[x]],
        endpoint = x,
        fields = get_fields(x, group = (x)) # requesting non-nested attributes
      )
    )
  })

  # make it noticeable that all is not right with the API
  skip("Skip for API bugs") # TODO: remove when the API is fixed/bad_eps removed
})
