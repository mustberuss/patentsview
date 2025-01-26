test_that("we can unnest all entities", {
  skip_on_cran()

  overloaded_entities <- c("patent/rel_app_text", "publication/rel_app_text")
  good_eps <- EPS[!EPS %in% c(GENERALLY_BAD_EPS, overloaded_entities)]

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

})
