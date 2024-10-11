# TODO: add a test to see if all the requested fields come back

add_base_url <- function(x) {
  paste0("https://search.patentsview.org/api/v1/", x)
}

endpoints <- get_endpoints()

test_that("API returns expected df names for all endpoints", {
  skip_on_cran()

  broken_endpoints <- c(
    "cpc_subclass",
    "uspc_subclass",
    "uspc_mainclass",
    "wipo"
  )

  # this will fail when the api is fixed
  dev_null <- lapply(broken_endpoints, function(x) {
    print(x)
    expect_error(
      search_pv(
        query = TEST_QUERIES[[x]],
        endpoint = x,
        fields = get_fields(x)
      )
    )
  })

  goodendpoints <- endpoints[!endpoints %in% broken_endpoints]

  df_names <- vapply(goodendpoints, function(x) {
    print(x)
    out <- search_pv(query = TEST_QUERIES[[x]], endpoint = x)

    # now the endpoints are singular and most entites are plural
    to_singular(names(out[[1]]))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  # remove nesting
  plain_endpoints <- gsub("^(patent|publication)/", "", goodendpoints)

  # publication/rel_app_text's entity is rel_app_text_publications
  df_names <- gsub("rel_app_text_publication", "rel_app_text", df_names)

  expect_equal(plain_endpoints, df_names)
})

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

test_that("You can download up to 9,000+ records", {
  skip_on_cran()

  # Should return 9,000+ rows
  query <- with_qfuns(
    and(
      gte(patent_date = "2021-12-13"),
      lte(patent_date = "2021-12-24")
    )
  )
  out <- search_pv(query, per_page = 1000, all_pages = TRUE)
  expect_gt(out$query_results$total_hits, 9000)
})

test_that("search_pv can pull all fields for all endpoints", {
  skip_on_cran()

  troubled_endpoints <- c(
    "cpc_subclass", "location",
    "uspc_subclass", "uspc_mainclass", "wipo", "claim", "draw_desc_text"
  )

  # these tests will fail when the API is fixed
  dev_null <- lapply(troubled_endpoints, function(x) {
    print(x)
    expect_error(
      search_pv(
        query = TEST_QUERIES[[x]],
        endpoint = x,
        fields = get_fields(x)
      )
    )
  })

  # We should be able to get all fields from the non troubled endpoints
  dev_null <- lapply(endpoints[!(endpoints %in% troubled_endpoints)], function(x) {
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
    fields = get_fields("assignee"),
    endpoint = "assignee",
    sort = c("assignee_lastknown_latitude" = "desc"),
    per_page = 100
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

# Below we request the same data in built_singly and result_all, with the only
# difference being that we intentionally get throttled in built_singly by
# sending one request per patent number (instead of all requests at once). If
# the two responses match, then we've correctly handled throttling errors.
test_that("Throttled requests are automatically retried", {
  skip_on_cran()

  res <- search_pv('{"_gte":{"patent_date":"2007-01-04"}}', per_page = 50)
  patent_ids <- res$data$patents$patent_id

  expect_message(
    built_singly <- lapply(patent_ids, function(patent_id) {
      search_pv(
        query = qry_funs$eq(patent_id = patent_id),
        endpoint = "patent/us_patent_citation",
        fields = c("patent_id", "citation_patent_id"),
        sort = c("citation_patent_id" = "asc")
      )[["data"]][["us_patent_citations"]]
    }),
    "The API's requests per minute limit has been reached. "
  )

  built_singly <- do.call(rbind, built_singly)

  result_all <- search_pv(
    query = qry_funs$eq(patent_id = patent_ids),
    endpoint = "patent/us_patent_citation",
    fields = c("patent_id", "citation_patent_id"),
    sort = c("patent_id" = "asc", "citation_patent_id" = "asc"),
    per_page = 1000,
    all_pages = TRUE
  )
  result_all <- result_all$data$us_patent_citations

  # the secondary sort seems to be broken, expect_identical() fails when it shouldn't
  # this will fail when the bug is fixed
  expect_error(expect_identical(built_singly, result_all))
})

test_that("We won't expose the user's patentsview API key to random websites", {
  skip_on_cran()

  # We will try to call the api that tells us who is currently in space
  in_space_now_url <- "http://api.open-notify.org/astros.json"
  expect_error(retrieve_linked_data(in_space_now_url))
})


test_that("We can call all the legitimate HATEOAS endpoints", {
  skip_on_cran()

  single_item_queries <- c(
    "cpc_subclass/A01B/",
    "cpc_class/A01/",
    "cpc_group/G01S7:4811/",
    "patent/10757852/",
    "uspc_mainclass/30/",
    "uspc_subclass/30:100/",
    "wipo/1/",
    "publication/20010000001/"
  )

  # these currently throw Error: Internal Server Error
  broken_single_item_queries <- c(
    "cpc_subclass/A01B/",
    "uspc_mainclass/30/",
    "uspc_subclass/30:100/",
    "wipo/1/"
  )

  single_item_queries <- single_item_queries[!single_item_queries %in% broken_single_item_queries]

  dev_null <- lapply(single_item_queries, function(q) {
    print(q)
    j <- retrieve_linked_data(add_base_url(q))
    expect_equal(j$query_results$total_hits, 1)
  })

  # TODO: remove when this is fixed
  # we'll know the api is fixed when this fails
  dev_null <- lapply(broken_single_item_queries, function(q) {
    expect_error(
      j <- retrieve_linked_data(add_base_url(q))
    )
  })

  multi_item_queries <- c(
    "patent/us_application_citation/10966293/",
    "patent/us_patent_citation/10966293/"
  )
  dev_null <- lapply(multi_item_queries, function(q) {
    j <- retrieve_linked_data(add_base_url(q))
    expect_true(j$query_results$total_hits > 1)
  })


  # We'll make a call to get an inventor and assignee HATEOAS link
  # in case their ids are not persistent
  # new weirdness: we request inventor_id and assignee_id but the
  # fields come back without the _id
  res <- search_pv('{"patent_id":"10000000"}',
    fields = c("inventors.inventor_id", "assignees.assignee_id")
  )

  assignee <- retrieve_linked_data(res$data$patents$assignees[[1]]$assignee)
  expect_true(assignee$query_results$total_hits == 1)

  inventor <- retrieve_linked_data(res$data$patents$inventors[[1]]$inventor)
  expect_true(inventor$query_results$total_hits == 1)

  # Query to get a location HATEOAS link in case location_ids are not persistent
  res <- search_pv('{"location_name":"Chicago"}',
    fields = c("location_id"),
    endpoint = "location"
  )

  location <- retrieve_linked_data(add_base_url(paste0("location/", res$data$locations$location_id, "/")))
  expect_true(location$query_results$total_hits == 1)
})

test_that("individual fields are still broken", {
  skip_on_cran()

  # Sample fields that cause 500 errors when requested by themselves.
  # Some don't throw errors when included in get_fields() but they do if
  # they are the only field requested.  Other individual fields at these
  # same endpoints throw errors.  Check fields again when these fail.
  sample_bad_fields <- c(
    "assignee_organization" = "assignee",
    "inventor_lastknown_longitude" = "inventor",
    "inventor_gender_attr_status" = "inventor",
    "location_name" = "location",
    "attorney_name_last" = "patent/attorney",
    "citation_country" = "patent/foreign_citation",
    "ipc_id" = "ipc"
  )

  dev_null <- lapply(names(sample_bad_fields), function(x) {
    endpoint <- sample_bad_fields[[x]]
    expect_error(
      out <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint, fields = c(x))
    )
  })

  # make it noticeable that all is not right with the API
  skip("Skip for API bugs") # TODO: remove when the API is fixed
})

# Make sure gets and posts return the same data.
# Posts had issues that went undetected for a while using the new API
# (odd results with posts when either no fields or sort was passed
# see get_post_body in search-pv.R)

test_that("posts and gets return the same data", {
  skip_on_cran()

  bad_eps <- c(
    "cpc_subclasses",
    "location" # Error: Invalid field: location_latitude
    , "uspc_subclasse" # Error: Internal Server Error
    , "uspc_mainclass" # Error: Internal Server Error
    , "wipo" # Error: Internal Server Error
    , "claim" # Error: Invalid field: claim_dependent
    , "draw_desc_text" # Error: Invalid field: description_sequence
    , "cpc_subclass" # 404?  check the test query
    , "uspc_subclass" # 404
  )

  good_eps <- endpoints[!endpoints %in% bad_eps]

  z <- lapply(good_eps, function(x) {
    print(x)
    get_res <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      method = "GET"
    )

    g <- unnest_pv_data(get_res$data)

    post_res <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      method = "POST"
    )

    p <- unnest_pv_data(post_res$data)

    expect_equal(g, p)
  })
})

test_that("nested shorthand produces the same results as fully qualified ones", {
  skip_on_cran()

  # the API now allows a shorthand in the fields/f: parameter
  # just the group name will retrieve all that group's attributes
  # This is indirectly testing our parse of the OpenAPI object and actual API responses

  shorthand_res <- search_pv(TEST_QUERIES[["patent"]], fields = c("application"))
  qualified_res <- search_pv(TEST_QUERIES[["patent"]], fields = get_fields("patent", groups = c("application")))

  # the request$urls will be different but the data should match
  expect_failure(expect_equal(shorthand_res$request$url, qualified_res$request$url))
  expect_equal(shorthand_res$data, qualified_res$data)
})
