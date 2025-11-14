test_that("Queries returning non-utility patents well", {
  skip_on_cran()
  only_utility_qry <- with_qfuns(
    and(
      gte(patent_date = "2021-12-13"),
      lte(patent_date = "2021-12-23"),
      eq(patent_type = "utility")
    )
  )
  only_utility_res <- search_pv(only_utility_qry, all_pages = TRUE)
  expect_equal(
    nrow(only_utility_res$data$patents),
    only_utility_res$query_results$total_hits
  )

  # Drop eq(patent_type = "utility") from query:
  only_utility_qry[[1]][3] <- NULL

  all_types_res <- search_pv(only_utility_qry, all_pages = TRUE)

  expect_true(
    nrow(all_types_res$data$patents) == all_types_res$query_results$total_hits
  )

  # if would be a problem if the second query didn't return more rows than the first one
  expect_gt(all_types_res$query_results$total_hits, only_utility_res$query_results$total_hits)

})

test_that("inventors.inventor_id and assignees.assignee_id are returned
          from patent endpoint when specified exactly", {
  skip_on_cran()
  query <- TEST_QUERIES[["patent"]]
  fields <- c("inventors.inventor_id", "assignees.assignee_id")

  # Should return just inventors and assignees
  results <- search_pv(
    query, fields = fields
  )

  # now the API returns more data than we asked - inventors and
  # assignees are fully populated.  here we'll check that we
  # got back the two high level attributes
  high_level <- unique(sub("\\..*", "", fields))
  expect_true(setequal(high_level,colnames(results$data$patents)))

  # Good result when not specifying nested-level fields explicitly
  good_res <- search_pv(
    query, fields = get_fields("patent", c("inventors", "assignees"))
  )
  expect_no_error(good_res$data$patents$inventors[[1]]$inventor)
  expect_no_error(good_res$data$patents$assignees[[1]]$assignee)
})


# Reported to the API team PVS-1147
# Not sure if this is a bug or feature - original API was case insensitive
# using both forms of equals, implied and explicit
test_that("There is case sensitivity on string equals", {
  skip_on_cran()

  assignee <- "Johnson & Johnson International"
  query1 <- sprintf('{"assignee_organization": \"%s\"}', assignee)
  a <- search_pv(query1, endpoint = "assignee")
  query2 <- qry_funs$eq(assignee_organization = assignee)
  b <- search_pv(query2, endpoint = "assignee")
  expect_equal(a$query_results$total_hits, 1)
  expect_equal(b$query_results$total_hits, 1)

  assignee <- tolower(assignee)
  query1 <- sprintf('{"assignee_organization": \"%s\"}', assignee)
  c <- search_pv(query1, endpoint = "assignee")
  query2 <- qry_funs$eq(assignee_organization = assignee)
  d <- search_pv(query2, endpoint = "assignee")
  expect_equal(c$query_results$total_hits, 0)
  expect_equal(d$query_results$total_hits, 0)
})

test_that("We can call all the legitimate HATEOAS endpoints", {
  skip_on_cran()

  # these currently throw Error: Internal Server Error
  broken_single_item_queries <- c(
    "cpc_subclass/A01B/",
    "uspc_mainclass/30/",
    "uspc_subclass/30:100/",
    "wipo/1/"
  )

  dev_null <- lapply(broken_single_item_queries, function(q) {
    expect_error(
      # TODO
      j <- retrieve_linked_data()
    )
  })
})

# PVS-1377
test_that("We can't sort by all fields", {
  skip_on_cran()

  sorts_to_try <- c(
    assignee = "assignee_lastknown_city",
    cpc_class = "cpc_class_title",
    cpc_group = "cpc_group_title",
    cpc_subclass = "cpc_subclass",
    g_brf_sum_text = "summary_text",
    g_claim = "claim_text",
    g_detail_desc_text = "description_text",
    g_draw_desc_text = "draw_desc_text",
    inventor = "inventor_lastknown_city",
    patent = "patent_id" # good pair to show that the code works
  )

  results <- lapply(names(sorts_to_try), function(endpoint) {
    field <- sorts_to_try[[endpoint]]
    print(paste(endpoint, field))

    tryCatch({
      sort <- "asc"
      names(sort) <- field
      j <- search_pv(
        query = TEST_QUERIES[[endpoint]],
        endpoint = endpoint, sort = sort
      )
      NA
    },
    error = function(e) {
      paste(endpoint, field)
    })
  })

  results <- results[!is.na(results)]
  expect_gt(length(results), 0)
  # assert that at least one sort worked:
  expect_lt(length(results), length(sorts_to_try))
})

# this is fixed, w/d patents only come back if option exclude_withdrawn is false

# PVS-1342 Underlying data issues
# There are ~8,000 patents that were in the bulk XML files that PatentsView is
# is based on that were subsequently withdrawn but not removed from the database
test_that("Withdrawn patents are still present in the database", {
  skip_on_cran()
  withdrawn <- c(
    "9978309", "9978406", "9978509", "9978615", "9978659",
    "9978697", "9978830", "9978838", "9978886", "9978906", "9978916",
    "9979255", "9979355", "9979482", "9979700", "9979841", "9979847",
    "9980139", "9980711", "9980782", "9981222", "9981277", "9981423",
    "9981472", "9981603", "9981760", "9981914", "9982126", "9982172",
    "9982670", "9982860", "9982871", "9983588", "9983756", "9984058",
    "9984899", "9984952", "9985340", "9985480", "9985987", "9986046"
  )

  query <- qry_funs$eq("patent_id" = withdrawn)
  results <- search_pv(query, method = "POST")
  expect_equal(results$query_results$total_hits, 0)
})

# PVS-1342 Underlying data issues
# There are ~300 patents that aren't in the bulk XML files that should be
test_that("Missing patents are still missing", {
  skip_on_cran()

  missing <- c(
    "4097517", "4424514", "4480077", "4487876", "4704648", "4704721",
    "4705017", "4705031", "4705032", "4705036", "4705037", "4705097", "4705107",
    "4705125", "4705142", "4705169", "4705170", "4705230", "4705274", "4705328",
    "4705412", "4705416", "4705437", "4705455", "4705462", "5493812", "5509710",
    "5697964", "5922850", "6087542", "6347059", "6680878", "6988922", "7151114",
    "7200832", "7464613", "7488564", "7606803", "8309694", "8455078"
  )
  query <- qry_funs$eq("patent_id" = missing)
  results <- search_pv(query, method = "POST")

  expect_equal(results$query_results$total_hits, 0)
})

# PVS-1884 The publication endpoint's rule_47_flag is always false
test_that("Querying the publication endpoint on rule_47_flag isn't meaningful", {
  skip_on_cran()

  res <- search_pv(qry_funs$eq(rule_47_flag = FALSE), endpoint = "publication")
  expect_equal(res$query_results$total_hits, 0)

  res <- search_pv(qry_funs$eq(rule_47_flag = TRUE), endpoint = "publication")
  expect_gt(res$query_results$total_hits, 8000000)

})

test_that("some endpoints don't return all of their advertised fields", {
  skip_on_cran()

  # these endpoints don't return all their advertised fields
  bad_eps <- c("patent",  "publication")

  dev_null <- lapply(EPS, function(x) {
    print(x)
    pv_out <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
    actual_fields <- colnames(pv_out$data[[1]])

    # we only want the top level fields, not ones in groups
    this_ep_fields <- fieldsdf[fieldsdf$endpoint == x & !grepl("\\.", fieldsdf$field), "field"]

    # also need groups, excluding the top level group like patents
    entity <- names(pv_out$data)
    this_ep_grps <- unique(fieldsdf[fieldsdf$endpoint == x, "group"])
    this_ep_grps <- setdiff(this_ep_grps, c(entity))

    expected_fields <- c(this_ep_fields, this_ep_grps)

    if(x %in% bad_eps)
      expect_false(setequal(actual_fields, expected_fields))
    else
      expect_true(setequal(actual_fields, expected_fields))
  })
})

test_that("some endpoint return unadvertised fields", {
  skip_on_cran()

  # test for endpoints that return extra fields that
  # weren't advertised (not in the openapi json spec) and
  # weren't requested

  # where getting a "patent" attribute back that's the
  # HATEOAS link for "patent_id"
  bad_eps <- c(
    "patent/foreign_citation",
    "patent/us_application_citation",
    "patent/us_patent_citation"
  )

  dev_null <- lapply(bad_eps , function(x) {
    print(x)
    pv_out <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
    expected_fields <- colnames(pv_out$data[[1]])

    # another abuse of retrieve_linked_data()
    url <- httr2::last_request()$url
    pv_out <- retrieve_linked_data(url)

    actual_fields <- colnames(pv_out$data[[1]])
    expect_false(setequal(actual_fields, expected_fields))
  })
})


test_that("HATEOAS links are still coming back wrong", {
  skip_on_cran()

  # the API added a :80 to the https links, causing SSL connect errors
  # this test will fail when that's fixed and the hack in
  # retrieve_linked_data can be removed

  res <- search_pv(
    '{"patent_id":"10000000"}',
    # We have to specify the group names instead of the fully-qualified group
    # names here b/c there's a bug with requesting specific fields for those
    # endpoints
    fields = c("inventors", "assignees")
  )

  bad_url <- res$data$patents$assignees[[1]]$assignee
  expect_true(grepl(':80', bad_url))
  good_url <- sub(':80', '', bad_url)

  # make sure the altered url works
  pv_out = retrieve_linked_data(good_url)
  expect_equal(pv_out$query_results$total_hits, 1)
})

test_that("unrequested fields are still being returned", {
  skip_on_cran()

   query <- TEST_QUERIES[["patent"]]
   fields <- c("patent_id", "patent_date")
   pv_out <- search_pv(query, fields = fields)

   # now we're removing the extra fields in search_pv
   # so we'll abuse retrieve_linked_data() which doesnt remove fields
   url <- httr2::last_request()$url
   pv_out <- retrieve_linked_data(url)

   returned <- colnames(pv_out$data[[1]])
   expect_false(setequal(returned, fields))
})
