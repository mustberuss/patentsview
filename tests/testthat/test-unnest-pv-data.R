test_that("we can unnest all entities", {
  skip_on_cran()

  overloaded_entities <- c("patent/rel_app_text", "publication/rel_app_text")
  # API bug actual returns does not match fieldsdf
  troubled_endpoints <- c("patent/foreign_citation", "patent/us_application_citation", "patent/us_patent_citation", "pg_detail_desc_text", "pg_draw_desc_text")
  good_eps <- EPS[!EPS %in% c(troubled_endpoints, overloaded_entities)]

  dev_null <- lapply(good_eps, function(x) {
    print(x)

    pv_out <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
    unnested <- unnest_pv_data(pv_out[["data"]])
    expect_is(unnested, "list")
  })

  # mismatch in actually returned fields vs expected fields
  dev_null <- lapply(troubled_endpoints, function(x) {
    print(x)
    pv_out <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
    actual_fields <- colnames(pv_out$data[[1]])

    this_ep_fields <- fieldsdf[fieldsdf$endpoint == x, "field"]
    this_ep_grps <- unique(fieldsdf[fieldsdf$endpoint == x, "group"])
    expected_fields = c(this_ep_fields, this_ep_grps)
    left <- all(actual_fields %in% expected_fields)
    right <- all(expected_fields %in% actual_fields)
    expect_false(all(left, right))
  })

})
