context("search_pv")

test_that("DSL-based query returns expected results", {
  skip_on_cran()

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

test_that("Iteration through pages works insofar as we can tell", {
  skip_on_cran()

  # Should return 9,000+ rows
  query <- with_qfuns(
    and(
      gte(patent_date = "2021-12-13"),
      lte(patent_date = "2021-12-30"),

      # new API bug: returned fields not consistent
      # when paging hits non utility patents
      # Error in rbind(deparse.level, ...) :
      # numbers of columns of arguments do not match
      eq(patent_type = "utility")
    )
  )

  out <- search_pv(query, all_pages = TRUE)
  expect_gt(out$query_results$total_hits, 9000)
})

test_that("search_pv can pull all fields for all endpoints", {
  skip_on_cran()

  dev_null <- lapply(EPS[!(EPS %in% GENERALLY_BAD_EPS)], function(x) {
    print(x)
    search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
  })
  expect_true(TRUE)
})

test_that("Sort option works as expected", {
  skip_on_cran()

  out <- search_pv(
    qry_funs$neq(assignee_id = ""),
    fields = get_fields("assignee", groups = "assignees"),
    endpoint = "assignee",
    sort = c("assignee_lastknown_latitude" = "desc"),
    size = 100
  )
  lat <- as.numeric(out$data$assignees$assignee_lastknown_latitude)
  expect_true(lat[1] >= lat[100])
})

test_that("search_pv properly URL encodes queries", {
  skip_on_cran()

  # Covers https://github.com/ropensci/patentsview/issues/24
  # need to use the assignee endpoint now
  organization <- "Johnson & Johnson International"
  text_query <- with_qfuns(text_phrase(assignee_organization = organization))
  phrase_search <- search_pv(text_query, endpoint = "assignee")
  expect_true(phrase_search$query_results$total_hits == 1)

  # also test that the string operator does not matter now
  eq_query <- with_qfuns(eq(assignee_organization = organization))
  eq_search <- search_pv(eq_query, endpoint = "assignee")
  expect_identical(eq_search$data, phrase_search$data)

  # text_phrase seems to be case insensitive but equal is not
  organization <- tolower(organization)

  text_query <- with_qfuns(text_phrase(assignee_organization = organization))
  phrase_search <- search_pv(text_query, endpoint = "assignee")
  expect_true(phrase_search$query_results$total_hits == 1)

  eq_query <- with_qfuns(eq(assignee_organization = organization))
  eq_search <- search_pv(eq_query, endpoint = "assignee")
  expect_true(eq_search$query_results$total_hits == 0)
})

test_that("We can call all the legitimate HATEOAS endpoints", {
  skip_on_cran()

  single_item_queries <- c(
    "cpc_subclass/A01B",
    "cpc_class/A01",
    "cpc_group/G01S7:4811",
    "patent/10757852",
    "uspc_mainclass/30",
    "uspc_subclass/30:100",
    "wipo/1",
    "publication/20010000001"
  )

  # these currently throw Error: Internal Server Error
  broken_single_item_queries <- c(
    "cpc_subclass/A01B",
    "uspc_mainclass/30",
    "uspc_subclass/30:100",
    "wipo/1"
  )

  single_item_queries <- single_item_queries[
    !single_item_queries %in% broken_single_item_queries
  ]

  dev_null <- lapply(single_item_queries, function(q) {
    j <- retrieve_linked_data(get_base(q))
    expect_equal(j$query_results$total_hits, 1)
  })

  multi_item_queries <- c(
    "patent/us_application_citation/10966293",
    "patent/us_patent_citation/10966293"
  )
  dev_null <- lapply(multi_item_queries, function(q) {
    j <- retrieve_linked_data(get_base(q))
    expect_true(j$query_results$total_hits > 1)
  })

  # We'll make a call to get an inventor and assignee HATEOAS link
  # in case their ids are not persistent
  # new weirdness: we request inventor_id and assignee_id but the
  # fields come back without the _id
  res <- search_pv(
    '{"patent_id":"10000000"}',
    # We have to specify the group names instead of the fully-qualified group
    # names here b/c there's a bug with requesting specific fields for those
    # endpoints
    fields = c("inventors", "assignees")
  )

  # new api bug: the hateoas links are coming back as search.patentsview.org:80
  bad_url <- res$data$patents$assignees[[1]]$assignee
  expect_true(grepl(':80', bad_url))  # fails on API fix
  good_url <- sub(':80', '', bad_url)

  assignee <- retrieve_linked_data(good_url)
  expect_true(assignee$query_results$total_hits == 1)

  bad_url <- res$data$patents$inventors[[1]]$inventor
  expect_true(grepl(':80', bad_url))  # fails on API fix
  good_url <- sub(':80', '', bad_url)

  inventor <- retrieve_linked_data(good_url)
  expect_true(inventor$query_results$total_hits == 1)

})

test_that("Shorthand specification of fields results in expected results", {
    skip_on_cran()
    query <- TEST_QUERIES[["patent"]]

    # We ask for all of assignee's nested fields (total of 9 fields currently).
    # It gets turned into a shorthand request, however now 11 fields are returned.
    # Returned but not requested:  assignee and assignee_location_id
    # Now the test is really that the shorthand notation was used and
    # that we got back all of the requested fields, ignoring the extras
    all_assn_flds <- get_fields("patent", groups = "assignees")
    full_res <- search_pv(query, fields = all_assn_flds, method = "POST")
    api_request <- httr2::last_request()$body$data
    expect_true(grepl('"f":\\["assignees","patent_id"\\]', api_request))

    unnested_requested_flds <- sub(".*\\.(.*)", "\\1", all_assn_flds)
    returned_flds <- names(full_res$data$patents$assignees[[1]])
    expect_true(all(unnested_requested_flds %in% returned_flds))

    # Here we explicitly request 8 fields but we get 9 back.  We get assignee_id back
    # as well as assignee (that we didn't ask for).  The opposite is not true,
    # asking for just assignee doesn't return assignee or assignee_id
    no_city <- all_assn_flds[all_assn_flds != "assignees.assignee_city"]
    no_city_res <- search_pv(query, fields = no_city)

    unnested_requested_flds <- sub(".*\\.(.*)", "\\1", no_city)
    returned_flds <- names(no_city_res$data$patents$assignees[[1]])
    expect_true(all(unnested_requested_flds %in% returned_flds))

})

test_that("The 'after' parameter works properly", {
  skip_on_cran()

  sort <- c("patent_id" = "asc")
  big_query <- qry_funs$eq(patent_date = "2000-01-04") # 3003 total_hits
  results <- search_pv(big_query, sort = sort)
  expect_gt(results$query_results$total_hits, 1000)

  after <- results$data$patents$patent_id[[nrow(results$data$patents)]]
  subsequent <- search_pv(big_query, after = after, sort = sort)

  expect_equal(nrow(subsequent$data$patents), 1000)
})

# Below we request the same data in built_singly and result_all, with the only
# difference being that we intentionally get throttled in built_singly by
# sending one request per patent_id (instead of all requests at once). If
# the two responses match, then we've correctly handled throttling errors.
test_that("Throttled requests are automatically retried", {
  print("Starting throttling test")
  skip_on_cran()

  # new API behavior:
  # need to specify fields now or patent_id assignees
  # cpc_current inventors wipo are returned 
  # and bind fails Error in rbind(deparse.level, ...) :
  # numbers of columns of arguments do not match
  # doesnt seem to be honoring the requested fields?
  fields <- c("patent_id", "patent_title", "patent_date")

  res <- search_pv('{"_gte":{"patent_date":"2007-01-04"}}', fields = fields, size = 60)
  built_batch <- res$data$patents$patent_id

  built_singly <- lapply(built_batch, function(patent_id) {
    one_res <- search_pv(qry_funs$eq(patent_id = patent_id), fields = fields)
    one_res$data[[1]]$patent_id
  })
  built_singly <- unlist(built_singly)
  expect_equal(built_batch, built_singly)
})
