context("unnest_pv_data")

# In the new version of the api, only three of the endpoints are searchable 
# by patent number.  query_for_endpoint provides a sample query for each 
# endpoint, except for locations, which isn't on the test server yet

eps <- (get_endpoints())
eps <-eps[eps != "locations"]

query_for_endpoint <- c(
      "application_citations" = '{"patent_number": "10966293"}',  # still searchable by pn
      "assignees" = '{"_text_phrase":{"name_last": "Clinton"}}',
      "cpc_groups" = '{"cpc_group_id": "A01B"}',
      "cpc_subgroups" = '{"cpc_subgroup_id": "A01B1/00"}',
      "cpc_subsections" = '{"cpc_subsection_id": "A01"}',
      "inventors" = '{"_text_phrase":{"name_last":"Quack"}}',
      "locations" = NA,
      "nber_categories" = '{"nber_category_id": "1"}',
      "nber_subcategories" = '{"nber_subcategory_id": "11"}',
      "patents" = '{"patent_number":"5116621"}',           # still searchable by pn
      "patent_citations" = '{"patent_number":"5116621"}',  # still searchable by pn
      "uspc_mainclasses" = '{"uspc_mainclass_id":"30"}',
      "uspc_subclasses" = '{"uspc_subclass_id": "100/1"}')

test_that("api return can be unnested", {
  skip_on_cran()
  skip_on_ci()

  z <- lapply(eps, function(x) {
    Sys.sleep(1)
    print(x)
    pv_out <- search_pv(
      query_for_endpoint[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
    unnest_pv_data(pv_out[["data"]])
  })

  expect_true(TRUE)
})
