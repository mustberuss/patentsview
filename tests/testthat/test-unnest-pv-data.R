test_that("we can unnest all entities", {
  skip_on_cran()

  locally_bad_eps <- c("publication", "cpc_subclass", "location",
    "uspc_mainclass", "uspc_subclass", "wipo", "pg_claim"
  )

  overloaded_entities <- c("patent/rel_app_text", "publication/rel_app_text")
  good_eps <- EPS[!EPS %in% c(locally_bad_eps, overloaded_entities)]

  dev_null <- lapply(good_eps, function(x) {
    print(x)

    pv_out <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )

    unnested <- unnest_pv_data(pv_out[["data"]])
    expect_type(unnested, "list")
  })
})
