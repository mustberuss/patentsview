
# Tests from the other files in this directory that are masking API errors
# This file was submitted to the API team as PVS-1125

eps <- (get_endpoints())

add_base_url <- function(x) {
  paste0("https://search.patentsview.org/api/v1/", x)
}

test_that("invalid fields are accepted", {
  skip_on_cran()
  skip_on_ci()

  # reported to the API team PVS-1306
  # The API accepts invalid fields that start out looking like valid fields
  # This test will fail when the API throws an error
  results <- retrieve_linked_data(
    'https://search.patentsview.org/api/v1/patent/?q={"patent_idd":"10000000"}&f=["patent_iddddddddddddd", "patent_dateagogo"]'
  )

  expect_equal(results$query_results$total_hits, 0)
})

test_that("there is case sensitivity on string equals", {
  skip_on_cran()
  skip_on_ci()

  # reported to the API team PVS-1147
  # not sure if this is a bug or feature - original API was case insensitive
  # using both forms of equals, impied and explicit

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

test_that("string vs text operators behave differently", {
  skip_on_cran()

  # # reported to the API team PVS-1147
  query <- qry_funs$begins(assignee_organization = "johnson")
  a <- search_pv(query, endpoint = "assignee")

  query <- qry_funs$text_any(assignee_organization = "johnson")
  b <- search_pv(query, endpoint = "assignee")

  expect_failure(
    expect_equal(a$query_results$total_hits, b$query_results$total_hits)
  )
})

test_that("the otherreferences endpoint is still broken", {
  skip_on_cran()
  skip_on_ci()

  query <- '{"_gte":{"patent_id":"1"}}'

  # reported to the API team PVS-1109
  # otherreferences is listed in the OpenAPI object.  It isn't in get_endpoints()
  # as it only throws errors.
  # This test will fail when the API does not throw an error

  # Currently throws a 404
  expect_error(
    result <- retrieve_linked_data(add_base_url(paste0("patent/otherreference/?q=", query)))
  )
})


# from test-api-returns.R
test_that("API returns all requested groups", {
  skip_on_cran()
  skip_on_ci()

  # can we traverse the return building a list of fields?
  # sort both requested fields and returned ones to see if they are equal

  # TODO: remove the trickery to get this test to pass, once the API is fixed
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

  mismatched_returns <- c(
    "patent",
    "publication"
  )

  good_eps <- eps[!eps %in% bad_eps]
  good_eps <- good_eps[!good_eps %in% mismatched_returns]

  z <- lapply(good_eps, function(x) {
    print(x)
    res <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )

    dl <- unnest_pv_data(res$data)

    actual_groups <- names(dl)

    expected_groups <- unique(fieldsdf[fieldsdf$endpoint == x, "group"])

    # we now need to unnest the endpoints for the comparison to work
    expected_groups <- gsub("^(patent|publication)/", "", expected_groups)


    # for "publication/rel_app_text" the expected group is really "rel_app_text_publications"
    # which doesn't match the endpoint
    if (x == "publication/rel_app_text") {
      expected_groups <- replace(expected_groups, expected_groups == "", "rel_app_text_publications")
    } else {
      # the expected group for unnested attributes would be "" in actuality the come back
      # in an entity matching the plural form of the unnested endpoint
      expected_groups <- replace(expected_groups, expected_groups == "", to_plural(x))
    }

    expect_setequal(actual_groups, expected_groups)
    show_failure(expect_setequal(actual_groups, expected_groups))
  })

  # this will fail when the api is fixed
  z <- lapply(bad_eps, function(x) {
    print(x)
    expect_error(
      j <- search_pv(query = TEST_QUERIES[[x]], endpoint = x, fields = get_fields(x))
    )
  })

  # this will fail when the API is fixed
  z <- lapply(mismatched_returns, function(x) {
    print(x)
    res <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )

    dl <- unnest_pv_data(res$data)

    actual_groups <- names(dl)
    expected_groups <- unique(fieldsdf[fieldsdf$endpoint == x, "group"])

    # we now need to unnest the endpoints for the comparison to work
    expected_groups <- gsub("^(patent|publication)/", "", expected_groups)

    # the expected group for unnested attributes would be "" in actuality the come back
    # in an entity matching the plural form of the unnested endpoint
    expected_groups <- replace(expected_groups, expected_groups == "", to_plural(x))

    expect_failure(
      expect_setequal(actual_groups, expected_groups)
    )
  })

  # make it noticeable that all is not right with the API
  skip("Skip for API bugs") # TODO: remove when the API is fixed
})

# test-fetch-each-field.R
test_that("each field in fieldsdf can be retrieved", {
  skip_on_cran()

  # Iterate through fieldsdf, requesting one field at a time to see if the field
  # really can be retrieved.  What fields work and don't work is constantly changing
  # as the new version of the api is being developed

  # maybe have the return be the fields that failed?  "endpoint"    "field"
  count <- 0

  dev_null <- sapply(get_endpoints(), function(endpoint) {
    fields <- fieldsdf[fieldsdf$endpoint == endpoint, c("field")]

    # here we want to remove nested fields like assignees.assignee_id
    fields <- fields[!fields %in% fields[grepl("\\.", fields)]]

    # should also test that there are unique values, some fields come back all NULLS

    lapply(fields, function(field) {
      tryCatch(
        expr = {
          # try adding the primary key to fields to see if that stops the 500s- helped some but not all
          # pk <- get_ok_pk(endpoint)
          pv_out <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint, fields = c(field))

          # see if the field actually came back - a fair amount don't come back
          # make sure pv_out$query_results$total_hits >= 1 first
          if (pv_out$query_results$total_hits == 0) {
            print(paste(endpoint, "zero hits"))
          } else {
            found <- FALSE
            if (!field %in% colnames(pv_out$data[[1]])) {
              # check for the _id thing, ex requested assignee_id but got assignee back

              if (grepl("_id", field)) {
                idless <- sub("_id", "", field)

                found <- idless %in% colnames(pv_out$data[[1]])
                if (found) {
                  print(paste("id dance on ", endpoint, field))
                }
              }
              if (!found) {
                print(paste(endpoint, field, "not returned"))
              }
            }
          }
          NA
        },
        error = function(e) {
          print(paste("error", endpoint, field))
          print(e)
          count <<- count + 1
          c(endpoint, field)
        }
      )
    })
  })

  expect_true(count > 0) # would fail when the API doesn't throw errors
})

# from test-search-pv.R
test_that("We can call all the legitimate HATEOAS endpoints", {
  skip_on_cran()

  # these currently throw Error: Internal Server Error
  broken_single_item_queries <- c(
    "cpc_subclass/A01B/",
    "uspc_mainclass/30/",
    "uspc_subclass/30:100/",
    "wipo/1/"
  )


  # TODO: remove when this is fixed
  # we'll know the api is fixed when this test fails
  dev_null <- lapply(broken_single_item_queries, function(q) {
    expect_error(
      j <- retrieve_linked_data(add_base_url(q))
    )
  })
})

# from test-search-pv.R
test_that("individual fields are still broken", {
  skip_on_cran()

  # Sample fields that cause 500 errors when requested by themselves.
  # Some don't throw errors when included in get_fields() but they do if
  # they are the only field requested.  Other individual fields at these
  # same endpoints throw errors.  Check fields again when these fail.
  sample_bad_fields <- c(
    "assignee_organization" = "assignees",
    "inventor_lastknown_longitude" = "inventors",
    "inventor_gender_code" = "inventors",
    "location_name" = "locations",
    "attorney_name_last" = "patent/attorneys",
    "citation_country" = "patent/foreign_citations",
    "ipc_id" = "ipcs"
  )

  dev_null <- lapply(names(sample_bad_fields), function(x) {
    endpoint <- sample_bad_fields[[x]]
    expect_error(
      out <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint, fields = c(x))
    )
  })
})
