context("search_pv")

# In the new version of the api, only three of the endpoints are searchable 
# by patent number.  query_for_endpoint provides a sample query for each 
# endpoint, except for locations, which isn't on the test server yet

# TODO: add a test to see if all the requested fields come back - to test the new
# version of the api more than to test the r packge!

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

test_that("API returns expected df names for all endpoints", {
  skip_on_cran()
  skip_on_ci()

  z <- vapply(eps, function(x) {
    Sys.sleep(2)
    j <- search_pv(query_for_endpoint[[x]], endpoint = x)
    names(j[[1]])
    print(names(j[[1]]))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  expect_equal(eps, z)
})

test_that("DSL-based query returns expected results", {
  skip_on_cran()
  skip_on_ci()

  query <- with_qfuns(
    and(
      or(
        gte(patent_date = "2014-01-01"),
        lte(patent_date = "1978-01-01")
      ),
      text_phrase(patent_abstract = c("computer program", "dog leash"))
    )
  )

  out <- search_pv(query)

  expect_gt(out$query_results$total_hits, 1000)
})

test_that("search_pv can pull all fields for all endpoints", {
  skip_on_cran()
  skip_on_ci()

  eps_no_loc <- eps[eps != "locations"]

  z <- lapply(eps_no_loc, function(x) {
    Sys.sleep(2)
    print(x)
    search_pv(
      query_for_endpoint[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
  })

  expect_true(TRUE)
})

# TODO: rework or remove this, subent_cnts aren't in the new version of the api
# what did the old test do?
test_that("search_pv can return subent_cnts", {
  # ...Though note this issue: https://github.com/CSSIP-AIR/PatentsView-API/issues/26
  skip_on_cran()
  skip_on_ci()

  out_spv <- search_pv(
    "{\"patent_number\":\"5116621\"}",
    fields = get_fields("patents", c("patents", "inventors")),
    subent_cnts = TRUE
  )
  expect_true(out_spv$query_results == 1)
})

test_that("Sort option works as expected", {
  skip_on_cran()
  skip_on_ci()

  # now only the assignee endpoint has lastknown_latitude

  out_spv <- search_pv(
    qry_funs$neq(assignee_id = 1),
    fields = get_fields("assignees"),
    endpoint = "assignees",
    sort = c("lastknown_latitude" = "desc"),
    per_page = 100
  )

  lat <- as.numeric(out_spv$data$assignees$lastknown_latitude)

  expect_true(lat[1] >= lat[100])
})

# TODO: remove / rework this test - locations endpoint isn't on the test server
test_that("search_pv can pull all fields by group for the locations endpoint", {
  skip_on_cran()
  skip_on_ci()

  groups <- unique(fieldsdf[fieldsdf$endpoint == "locations", "group"])

  z <- lapply(groups, function(x) {
    Sys.sleep(2)

    # the locations endpoint isn't on the test server yet and probably won't be 
    # queryable by patent number
    expect_error(
       search_pv(
         '{"patent_number":"5116621"}',
         endpoint = "inventors",
         fields = get_fields("inventors", x)
       )
    )
  })

#   expect_true(TRUE)
})

test_that("search_pv properly encodes queries", {
  skip_on_cran()
  skip_on_ci()

  # Covers https://github.com/ropensci/patentsview/issues/24
  # need to use the assignee endpoint now and the field is full_text
  result <- search_pv(
    query = with_qfuns(
      text_phrase(organization = "Johnson & Johnson")
    ), endpoint = "assignees"
  )

  expect_true(TRUE)
})
